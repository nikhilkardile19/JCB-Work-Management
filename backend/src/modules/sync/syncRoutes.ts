import type { AppContext } from '../../context.js'
import { prismaCode, type Tx } from '../../database/prisma.js'
import type { CompanyRole } from '../../generated/prisma/client.js'
import { ApiError, invalid, notFound } from '../../lib/errors.js'
import type { Api } from '../../lib/http.js'
import { idSchema, parse, z } from '../../lib/validation.js'
import { activeMembership } from '../companies/access.js'
import { deviceLicensed } from '../licenses/licenseRules.js'
import {
  BILLING_COLLECTIONS,
  changesAfter,
  COLLECTIONS,
  isCollection,
  loadRecord,
  saveRecord,
  SCHEMAS,
  type CollectionName,
  type Json,
} from './collections.js'
import { checkWrite } from './rules.js'

/**
 * Offline sync (ADR 0003, ported to PostgreSQL). Replaces the app's direct
 * Firestore reads and writes of `companies/{c}/{collection}/{id}`.
 *
 * Push: optimistic concurrency on `rev` — a write must name the revision the
 * phone last saw; a mismatch returns the server copy (409 `conflict`) and the
 * app resolves it per its conflict policy. Pull: changes after a cursor, in
 * the company's change-sequence order.
 */
const READ_BILLING: CompanyRole[] = ['owner', 'admin', 'manager', 'accounts']

const passRefusal = (message: string, reason: string) => new ApiError('permission_denied', message, { reason })

function collectionOf(name: string): CollectionName {
  if (!isCollection(name)) throw notFound(`Collection ${name}`)
  return name
}

function canRead(role: CompanyRole, c: CollectionName) {
  return !BILLING_COLLECTIONS.has(c) || READ_BILLING.includes(role)
}

/** Next position in the company's change feed; locks it until commit. */
async function nextSeq(tx: Tx, companyId: string): Promise<bigint> {
  const [row] = await tx.$queryRaw<{ seq: bigint }[]>`
    INSERT INTO company_sync_state (company_id, seq) VALUES (${companyId}, 1)
    ON CONFLICT (company_id) DO UPDATE SET seq = company_sync_state.seq + 1
    RETURNING seq`
  return row.seq
}

/** Friendly messages for database constraints the rules don't pre-check. */
function constraintError(e: unknown): ApiError | null {
  switch (prismaCode(e)) {
    case 'P2003':
      return invalid('This record refers to a client, site, machine or other record that is not on the server yet. Sync again; if it persists, check that record.')
    case 'P2002':
      return invalid('That invoice number is already used by another invoice.')
    case 'P2004':
      return invalid('The server refused this record because its values are inconsistent.')
    default:
      return null
  }
}

async function push(ctx: AppContext, uid: string, companyId: string, collection: CollectionName, id: string, body: { baseRev: number | null; data: unknown }, deviceId: string | undefined) {
  const now = ctx.clock()
  // Whole-pass refusals: the app stops syncing and keeps its records pending.
  const access = await activeMembership(ctx.db, companyId, uid)
  if (!access) throw passRefusal('You are not a member of this company.', 'not_member')
  if (access.company.status !== 'active') throw passRefusal('This company is not active. Changes stay on the phone.', 'company_inactive')
  if (!(await deviceLicensed(ctx.db, companyId, deviceId, uid, now))) {
    throw passRefusal('This phone is not activated on an active license. Changes stay on the phone.', 'device_not_licensed')
  }

  // Record-level refusals: the app marks this record and moves on.
  const data = parse(SCHEMAS[collection], body.data, 'data') as Json
  if (data.id !== id || data.companyId !== companyId) throw invalid('The record ID and company must match the URL.')
  // Checked before a conflict could return the server copy.
  if (!canRead(access.role, collection)) throw new ApiError('permission_denied', 'Your role cannot see billing records.')

  try {
    return await ctx.db.$transaction(async (tx) => {
      const seq = await nextSeq(tx, companyId)
      const stored = await loadRecord(tx, collection, companyId, id)
      // Revision 0 means "does not exist yet", so a phone that was told
      // `serverRev: 0` can create the record on its next attempt.
      const current = stored?.rev ?? 0
      if (current !== (body.baseRev ?? 0)) {
        throw new ApiError('conflict', 'The record changed on the server since this phone last saw it.', {
          body: { serverRev: current, serverData: stored?.data ?? {} },
        })
      }
      await checkWrite({ tx, collection, companyId, uid, role: access.role, before: stored?.data ?? null, data })
      const rev = current + 1
      await saveRecord(tx, collection, data, { rev, syncSeq: seq, serverUpdatedAt: now, pushedBy: uid, deviceId: deviceId ?? null })
      return { rev }
    })
  } catch (e) {
    throw constraintError(e) ?? e
  }
}

async function pull(ctx: AppContext, uid: string, companyId: string, collection: CollectionName, after: string | undefined, limit: number) {
  const access = await activeMembership(ctx.db, companyId, uid)
  if (!access) throw passRefusal('You are not a member of this company.', 'not_member')
  if (!canRead(access.role, collection)) throw new ApiError('permission_denied', 'Your role cannot see billing records.')
  let afterSeq = 0n
  if (after) {
    const m = /^(\d{1,19})\|/.exec(after)
    if (!m) throw invalid('The cursor is not valid.')
    afterSeq = BigInt(m[1])
  }
  return { items: await changesAfter(ctx.db as unknown as Tx, collection, companyId, afterSeq, limit) }
}

const Params = z.object({ companyId: idSchema(), collection: z.enum(COLLECTIONS) })

const RecordEnvelope = z.object({
  id: z.string(),
  rev: z.number().int(),
  cursor: z.string().openapi({ example: '1042|5f0c…' }),
  data: z.record(z.string(), z.unknown()).openapi({ description: 'The record as the app stores it (Drift toJson), minus syncStatus and device-only paths' }),
})

export function registerSyncRoutes(api: Api) {
  const { ctx } = api

  api.route(
    {
      method: 'get',
      path: '/companies/:companyId/sync/:collection',
      tag: 'Sync',
      summary: 'Records changed after a cursor, oldest change first',
      description: `Collections: ${COLLECTIONS.join(', ')}. Read-only access continues while the company or license is inactive.`,
      params: Params,
      query: z.object({
        after: z.string().max(200).optional(),
        limit: z.coerce.number().int().min(1).max(500).default(200),
      }),
      response: z.object({ items: z.array(RecordEnvelope) }).openapi('SyncPage'),
      errors: [403],
    },
    ({ params, query, user }) => pull(ctx, user.id, params.companyId, collectionOf(params.collection), query.after, query.limit),
  )

  api.route(
    {
      method: 'put',
      path: '/companies/:companyId/sync/:collection/:id',
      tag: 'Sync',
      summary: 'Upload one record, guarded by the revision this phone last saw',
      description:
        'Requires `X-Device-Id`. 409 `conflict` carries `serverRev` and `serverData`. 403 with reason `not_member`, `company_inactive` or `device_not_licensed` refuses the whole sync pass; other 400/403 refuse this record only.',
      params: Params.extend({ id: idSchema() }),
      body: z.object({ baseRev: z.number().int().min(0).nullable(), data: z.record(z.string(), z.unknown()) }).strict(),
      response: z.object({ rev: z.number().int() }),
      errors: [403, 409],
    },
    ({ params, body, user, req }) =>
      push(ctx, user.id, params.companyId, collectionOf(params.collection), params.id, body, req.get('x-device-id')),
  )
}
