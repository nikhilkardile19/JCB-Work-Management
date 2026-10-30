import type { AppContext } from '../../context.js'
import { ApiError } from '../../lib/errors.js'
import type { Api } from '../../lib/http.js'
import { idSchema, z } from '../../lib/validation.js'
import { recordEvent } from '../audit/auditEvents.js'
import { requireActiveMember } from '../companies/access.js'
import { assertWithinLimit, consume, LIMITS } from '../rate-limits/rateLimit.js'
import { hashCode } from './activationCodes.js'
import { countActiveDevices, effectiveStatus, lockLicense, type LicenseState } from './licenseRules.js'

/**
 * Phone activation and license checks (ported from `functions/src/licenses.ts`).
 * The app never decides by itself that it is licensed; it caches what the
 * server says.
 */
type DenyReason = 'invalid_code' | 'not_started' | 'expired' | 'suspended' | 'revoked' | 'pending' | 'device_limit' | 'device_revoked'

const DENY_MESSAGES: Record<DenyReason, string> = {
  invalid_code: 'That activation code is not valid for this company.',
  not_started: 'This license has not started yet.',
  expired: 'This license has expired. Contact support to renew.',
  suspended: 'This license is suspended. Contact support.',
  revoked: 'This license has been revoked. Contact support.',
  pending: 'This license is not active yet. Contact support.',
  device_limit: 'All devices allowed by this license are in use. Request a device replacement or contact support.',
  device_revoked: 'This device has been deactivated. Request a device replacement or contact support.',
}

class Denied extends Error {
  constructor(
    readonly reason: DenyReason,
    readonly licenseId?: string,
  ) {
    super(DENY_MESSAGES[reason])
  }
}

export const LicenseStateOut = z
  .object({
    licenseId: z.string().nullable(),
    licenseStatus: z.enum(['pending', 'active', 'suspended', 'expired', 'revoked', 'not_started', 'none']),
    deviceStatus: z.enum(['active', 'revoked', 'unknown']),
    validUntil: z.number().int().nullable(),
    maxDevices: z.number().int().nullable(),
    serverTime: z.number().int(),
  })
  .openapi('LicenseState')

const Params = z.object({ companyId: idSchema() })
const shortText = (max: number) => z.string().min(1).max(max)

/** Persists `expired` on an active license whose end date has passed. */
async function markExpired(ctx: AppContext, licenseId: string, now: Date) {
  await ctx.db.license.updateMany({ where: { id: licenseId, status: 'active', validUntil: { lt: now } }, data: { status: 'expired' } })
}

async function activate(
  ctx: AppContext,
  uid: string,
  companyId: string,
  d: { activationCode: string; deviceId: string; deviceModel?: string; platform?: string },
): Promise<LicenseState> {
  const now = ctx.clock()
  await requireActiveMember(ctx.db, companyId, uid)
  const limitKey = `codeFailures_${uid}`
  await assertWithinLimit(ctx.db, limitKey, LIMITS.codeFailures, now)
  const base = { companyId, deviceId: d.deviceId, uid, deviceModel: d.deviceModel ?? null }

  const license = await ctx.db.license.findUnique({
    where: { companyId_activationCodeHash: { companyId, activationCodeHash: hashCode(d.activationCode) } },
  })
  try {
    if (!license) throw new Denied('invalid_code')
    const state = await ctx.db.$transaction(async (tx) => {
      await lockLicense(tx, license.id)
      const l = (await tx.license.findUniqueOrThrow({ where: { id: license.id } }))
      const status = effectiveStatus(l.status, l.validFrom, l.validUntil, now)
      if (status !== 'active') throw new Denied(status, l.id)

      const device = await tx.device.findUnique({ where: { companyId_id: { companyId, id: d.deviceId } } })
      if (device?.status === 'revoked') throw new Denied('device_revoked', l.id)
      const alreadyActive = device?.status === 'active' && device.licenseId === l.id
      if (!alreadyActive && (await countActiveDevices(tx, companyId, l.id)) >= l.maxDevices) {
        throw new Denied('device_limit', l.id)
      }
      const fields = {
        licenseId: l.id,
        userId: uid,
        deviceModel: base.deviceModel,
        platform: d.platform ?? 'android',
        status: 'active' as const,
        lastSeenAt: now,
      }
      await tx.device.upsert({
        where: { companyId_id: { companyId, id: d.deviceId } },
        create: { companyId, id: d.deviceId, ...fields, activatedAt: now },
        update: alreadyActive ? fields : { ...fields, activatedAt: now },
      })
      await tx.license.update({ where: { id: l.id }, data: { lastValidatedAt: now } })
      return {
        reactivated: alreadyActive,
        result: {
          licenseId: l.id,
          licenseStatus: 'active' as const,
          deviceStatus: 'active' as const,
          validUntil: l.validUntil.getTime(),
          maxDevices: l.maxDevices,
          serverTime: now.getTime(),
        },
      }
    })
    await recordEvent(ctx.db, now, {
      type: state.reactivated ? 'device.revalidate' : 'device.activate',
      ...base,
      actorId: uid,
      licenseId: state.result.licenseId,
    })
    return state.result
  } catch (e) {
    if (!(e instanceof Denied)) throw e
    // Record date-based expiry outside the refused transaction (which rolled back).
    if (e.reason === 'expired' && e.licenseId) await markExpired(ctx, e.licenseId, now)
    if (e.reason === 'invalid_code') await consume(ctx.db, limitKey, LIMITS.codeFailures, now)
    await recordEvent(ctx.db, now, { type: 'device.activate_denied', reason: e.reason, ...base, actorId: uid, licenseId: e.licenseId ?? null })
    throw new ApiError('failed_precondition', e.message, { reason: e.reason })
  }
}

/** Current state for a phone. Never an error for suspended/expired/revoked states. */
async function validate(ctx: AppContext, uid: string, companyId: string, deviceId: string): Promise<LicenseState> {
  const now = ctx.clock()
  await requireActiveMember(ctx.db, companyId, uid)
  const device = await ctx.db.device.findUnique({ where: { companyId_id: { companyId, id: deviceId } }, include: { license: true } })
  if (!device || device.userId !== uid) {
    return { licenseId: null, licenseStatus: 'none', deviceStatus: 'unknown', validUntil: null, maxDevices: null, serverTime: now.getTime() }
  }
  const l = device.license
  const status = effectiveStatus(l.status, l.validFrom, l.validUntil, now)
  await ctx.db.$transaction([
    ctx.db.license.update({
      where: { id: l.id },
      data: { lastValidatedAt: now, ...(status === 'expired' && l.status === 'active' ? { status: 'expired' as const } : {}) },
    }),
    ...(device.status === 'active'
      ? [ctx.db.device.update({ where: { companyId_id: { companyId, id: deviceId } }, data: { lastSeenAt: now } })]
      : []),
  ])
  return {
    licenseId: l.id,
    licenseStatus: status,
    deviceStatus: device.status === 'active' ? 'active' : 'revoked',
    validUntil: l.validUntil.getTime(),
    maxDevices: l.maxDevices,
    serverTime: now.getTime(),
  }
}

export function registerDeviceRoutes(api: Api) {
  const { ctx } = api

  api.route(
    {
      method: 'post',
      path: '/companies/:companyId/license/activate',
      tag: 'Licensing',
      summary: 'Register this phone on the company license with an activation code',
      description: 'Denials are `409 failed_precondition` with `reason` (invalid_code, expired, device_limit, …). 10 wrong codes per user per hour.',
      params: Params,
      body: z.object({
        activationCode: shortText(40),
        deviceId: idSchema(64),
        deviceModel: shortText(100).optional(),
        platform: shortText(20).optional(),
      }),
      response: LicenseStateOut,
      errors: [403, 409, 429],
    },
    ({ params, body, user }) => activate(ctx, user.id, params.companyId, body),
  )

  api.route(
    {
      method: 'post',
      path: '/companies/:companyId/license/validate',
      tag: 'Licensing',
      summary: "This phone's current license and device state",
      params: Params,
      body: z.object({ deviceId: idSchema(64) }),
      response: LicenseStateOut,
      errors: [403, 409],
    },
    ({ params, body, user }) => validate(ctx, user.id, params.companyId, body.deviceId),
  )
}
