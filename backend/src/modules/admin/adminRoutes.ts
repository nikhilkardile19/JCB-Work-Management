import type { AppContext } from '../../context.js'
import type { CompanyStatus, Prisma } from '../../generated/prisma/client.js'
import { invalid, notFound, precondition } from '../../lib/errors.js'
import type { Api } from '../../lib/http.js'
import { newId } from '../../lib/ids.js'
import { page, PageQuery } from '../../lib/pagination.js'
import { DAY_MS } from '../../lib/time.js'
import { emailSchema, idSchema, reasonSchema, z } from '../../lib/validation.js'
import { recordEvent } from '../audit/auditEvents.js'
import { changedFields, CompanyOut, companyOut, CompanyProfileInput } from '../companies/companyProfile.js'
import { generateActivationCode, hashCode } from '../licenses/activationCodes.js'
import { countActiveDevices } from '../licenses/licenseRules.js'
import { findOrCreateUser } from '../members/users.js'
import { requireAdmin, type AdminPermission } from './adminAccess.js'
import { DeviceOut, deviceOut, EventOut, eventOut, LicenseOut, licenseOut, pageOf, RequestOut, requestOut } from './adminViews.js'

/**
 * Developer admin portal (ported from `functions/src/admin.ts` plus the
 * portal's former Firestore reads). Every change needs the matching
 * permission and a reason, and is written to `audit_events` with
 * before/after values.
 */
export const EXPIRING_DAYS = 30

const TAG = { companies: 'Admin: companies', licenses: 'Admin: licenses', devices: 'Admin: devices', audit: 'Admin: audit' }
const CompanyParams = z.object({ companyId: idSchema() })
const LicenseParams = CompanyParams.extend({ licenseId: idSchema() })
const DeviceParams = CompanyParams.extend({ deviceId: idSchema(64) })

async function license(ctx: AppContext, companyId: string, licenseId: string) {
  const l = await ctx.db.license.findFirst({ where: { id: licenseId, companyId }, include: { company: { select: { name: true } } } })
  if (!l) throw notFound('License')
  return l
}

const notRevoked = (l: { status: string }) => {
  if (l.status === 'revoked') throw precondition('A revoked license cannot be changed. Create a new license.')
}

export function registerAdminRoutes(api: Api) {
  const { ctx } = api
  const admin = (uid: string, permission?: AdminPermission) => requireAdmin(ctx.db, uid, permission)

  api.route(
    {
      method: 'get',
      path: '/admin/me',
      tag: TAG.companies,
      summary: "The signed-in developer admin's role and grants (403 for everyone else)",
      response: z
        .object({ uid: z.string(), email: z.string().nullable(), role: z.enum(['super', 'support']), permissions: z.array(z.string()) })
        .openapi('AdminProfile'),
      errors: [403],
    },
    ({ user }) => admin(user.id),
  )

  api.route(
    {
      method: 'get',
      path: '/admin/metrics',
      tag: TAG.companies,
      summary: 'Dashboard counts',
      description: `Licenses past their end date count as expired even before they are marked so; "expiring soon" = active and ending within ${EXPIRING_DAYS} days.`,
      response: z
        .object({
          companies: z.object({ pending: z.number(), active: z.number(), suspended: z.number() }),
          licenses: z.object({ active: z.number(), expiringSoon: z.number(), expired: z.number(), suspended: z.number() }),
          activeDevices: z.number(),
          pendingRequests: z.number(),
        })
        .openapi('DashboardMetrics'),
      errors: [403],
    },
    async ({ user }) => {
      await admin(user.id)
      const now = ctx.clock()
      const soon = new Date(now.getTime() + EXPIRING_DAYS * DAY_MS)
      const [byStatus, lActive, lSoon, lExpired, lSuspended, activeDevices, pendingRequests] = await Promise.all([
        ctx.db.company.groupBy({ by: ['status'], _count: { _all: true } }),
        ctx.db.license.count({ where: { status: 'active', validUntil: { gte: now } } }),
        ctx.db.license.count({ where: { status: 'active', validUntil: { gte: now, lte: soon } } }),
        ctx.db.license.count({ where: { OR: [{ status: 'expired' }, { status: 'active', validUntil: { lt: now } }] } }),
        ctx.db.license.count({ where: { status: 'suspended' } }),
        ctx.db.device.count({ where: { status: 'active' } }),
        ctx.db.deviceReplacementRequest.count({ where: { status: 'pending' } }),
      ])
      const companies = { pending: 0, active: 0, suspended: 0 }
      for (const g of byStatus) companies[g.status] = g._count._all
      return {
        companies,
        licenses: { active: lActive, expiringSoon: lSoon, expired: lExpired, suspended: lSuspended },
        activeDevices,
        pendingRequests,
      }
    },
  )

  // --- Companies --------------------------------------------------------------

  api.route(
    {
      method: 'get',
      path: '/admin/companies',
      tag: TAG.companies,
      summary: 'Companies, newest first, or matching a name search',
      query: PageQuery.extend({ status: z.enum(['pending', 'active', 'suspended']).optional(), search: z.string().trim().max(120).optional() }),
      response: pageOf(CompanyOut, 'CompanyPage'),
      errors: [403],
    },
    async ({ query, user }) => {
      await admin(user.id)
      const where: Prisma.CompanyWhereInput = {
        ...(query.status ? { status: query.status } : {}),
        ...(query.search ? { name: { contains: query.search, mode: 'insensitive' } } : {}),
      }
      const orderBy: Prisma.CompanyOrderByWithRelationInput[] = query.search
        ? [{ name: 'asc' }, { id: 'asc' }]
        : [{ createdAt: 'desc' }, { id: 'desc' }]
      return page(
        (args) => ctx.db.company.findMany({ where, orderBy, ...args, cursor: args.cursor as { id: string } | undefined }),
        (c) => ({ id: c.id }),
        companyOut,
        query,
      )
    },
  )

  api.route(
    { method: 'get', path: '/admin/companies/:companyId', tag: TAG.companies, summary: 'One company', params: CompanyParams, response: CompanyOut, errors: [403, 404] },
    async ({ params, user }) => {
      await admin(user.id)
      const c = await ctx.db.company.findUnique({ where: { id: params.companyId } })
      if (!c) throw notFound('Company')
      return companyOut(c)
    },
  )

  api.route(
    {
      method: 'get',
      path: '/admin/companies/:companyId/members',
      tag: TAG.companies,
      summary: "A company's users",
      params: CompanyParams,
      response: z.object({ items: z.array(z.object({ uid: z.string(), email: z.string().nullable(), role: z.string(), status: z.string() })) }),
      errors: [403],
    },
    async ({ params, user }) => {
      await admin(user.id)
      const rows = await ctx.db.companyMember.findMany({
        where: { companyId: params.companyId },
        include: { user: { select: { email: true } } },
        orderBy: { createdAt: 'asc' },
      })
      return { items: rows.map((m) => ({ uid: m.userId, email: m.user.email, role: m.role, status: m.status })) }
    },
  )

  api.route(
    {
      method: 'post',
      path: '/admin/companies',
      tag: TAG.companies,
      summary: "Create an active company on a customer's behalf, with its owner account",
      description: 'The owner account is created without a password if needed; the owner sets one with "Forgot password".',
      body: CompanyProfileInput.extend({ ownerEmail: emailSchema }),
      response: z.object({ companyId: z.string(), ownerUid: z.string(), newUser: z.boolean() }),
      status: 201,
      errors: [403],
    },
    async ({ body, user }) => {
      await admin(user.id, 'companies.manage')
      const { ownerEmail, ...profile } = body
      const now = ctx.clock()
      const id = newId()
      const { owner, newUser } = await ctx.db.$transaction(async (tx) => {
        const { user: owner, newUser } = await findOrCreateUser(tx, ownerEmail, now)
        await tx.company.create({
          data: { id, ...profile, currency: 'INR', status: 'active', ownerUserId: owner.id, createdBy: user.id, updatedBy: user.id, createdAt: now, updatedAt: now },
        })
        await tx.companyMember.create({ data: { companyId: id, userId: owner.id, role: 'owner', status: 'active', createdAt: now } })
        return { owner, newUser }
      })
      await recordEvent(ctx.db, now, { type: 'company.create', actorId: user.id, companyId: id, name: profile.name, ownerEmail, newUser })
      return { companyId: id, ownerUid: owner.id, newUser }
    },
  )

  api.route(
    {
      method: 'patch',
      path: '/admin/companies/:companyId',
      tag: TAG.companies,
      summary: 'Edit a company profile (never status, owner or id)',
      params: CompanyParams,
      body: CompanyProfileInput,
      response: z.object({ ok: z.literal(true) }),
      errors: [403, 404],
    },
    async ({ params, body, user }) => {
      await admin(user.id, 'companies.manage')
      const now = ctx.clock()
      const before = await ctx.db.company.findUnique({ where: { id: params.companyId } })
      if (!before) throw notFound('Company')
      await ctx.db.company.update({ where: { id: params.companyId }, data: { ...body, updatedBy: user.id, updatedAt: now } })
      await recordEvent(ctx.db, now, {
        type: 'company.update',
        actorId: user.id,
        companyId: params.companyId,
        changed: changedFields(before as unknown as Record<string, unknown>, body),
      })
      return { ok: true as const }
    },
  )

  api.route(
    {
      method: 'post',
      path: '/admin/companies/:companyId/status',
      tag: TAG.companies,
      summary: 'Approve, suspend or reactivate a company',
      params: CompanyParams,
      body: z.object({ status: z.enum(['pending', 'active', 'suspended']), reason: reasonSchema }),
      response: z.object({ status: z.string() }),
      errors: [403, 404],
    },
    async ({ params, body, user }) => {
      await admin(user.id, 'companies.manage')
      const now = ctx.clock()
      const before = await ctx.db.company.findUnique({ where: { id: params.companyId } })
      if (!before) throw notFound('Company')
      await ctx.db.company.update({ where: { id: params.companyId }, data: { status: body.status as CompanyStatus, updatedBy: user.id, updatedAt: now } })
      await recordEvent(ctx.db, now, { type: 'company.status', actorId: user.id, companyId: params.companyId, from: before.status, to: body.status, reason: body.reason })
      return { status: body.status }
    },
  )

  // --- Licenses ----------------------------------------------------------------

  api.route(
    {
      method: 'get',
      path: '/admin/licenses',
      tag: TAG.licenses,
      summary: 'Licenses, soonest end date first',
      query: PageQuery.extend({ status: z.enum(['pending', 'active', 'suspended', 'expired', 'revoked']).optional(), companyId: idSchema().optional() }),
      response: pageOf(LicenseOut, 'LicensePage'),
      errors: [403],
    },
    async ({ query, user }) => {
      await admin(user.id)
      const where = { ...(query.status ? { status: query.status } : {}), ...(query.companyId ? { companyId: query.companyId } : {}) }
      return page(
        (args) =>
          ctx.db.license.findMany({
            where,
            orderBy: [{ validUntil: 'asc' }, { id: 'asc' }],
            include: { company: { select: { name: true } } },
            ...args,
            cursor: args.cursor as { id: string } | undefined,
          }),
        (l) => ({ id: l.id }),
        licenseOut,
        query,
      )
    },
  )

  api.route(
    {
      method: 'post',
      path: '/admin/companies/:companyId/licenses',
      tag: TAG.licenses,
      summary: 'Issue a license; the activation code is returned once and stored only as a hash',
      params: CompanyParams,
      body: z
        .object({ validFrom: z.number().int().min(0), validUntil: z.number().int().min(0), maxDevices: z.number().int().min(1).max(100) })
        .refine((d) => d.validUntil > d.validFrom, { message: 'validUntil must be after validFrom', path: ['validUntil'] }),
      response: z.object({ licenseId: z.string(), activationCode: z.string() }),
      status: 201,
      errors: [403, 404],
    },
    async ({ params, body, user }) => {
      await admin(user.id, 'licenses.manage')
      const now = ctx.clock()
      const company = await ctx.db.company.findUnique({ where: { id: params.companyId } })
      if (!company) throw notFound('Company')
      const activationCode = generateActivationCode()
      const licenseId = newId()
      await ctx.db.license.create({
        data: {
          id: licenseId,
          companyId: params.companyId,
          status: 'active',
          validFrom: new Date(body.validFrom),
          validUntil: new Date(body.validUntil),
          maxDevices: body.maxDevices,
          activationCodeHash: hashCode(activationCode),
          createdBy: user.id,
          createdAt: now,
          updatedAt: now,
        },
      })
      await recordEvent(ctx.db, now, { type: 'license.create', actorId: user.id, companyId: params.companyId, licenseId, maxDevices: body.maxDevices })
      // The plaintext code is returned once and never stored.
      return { licenseId, activationCode }
    },
  )

  api.route(
    { method: 'get', path: '/admin/companies/:companyId/licenses/:licenseId', tag: TAG.licenses, summary: 'One license', params: LicenseParams, response: LicenseOut, errors: [403, 404] },
    async ({ params, user }) => {
      await admin(user.id)
      return licenseOut(await license(ctx, params.companyId, params.licenseId))
    },
  )

  api.route(
    {
      method: 'patch',
      path: '/admin/companies/:companyId/licenses/:licenseId',
      tag: TAG.licenses,
      summary: 'Change the end date (renewal) and/or the device limit',
      description: 'Renewing an expired license past today re-activates it. The limit cannot drop below the active devices.',
      params: LicenseParams,
      body: z.object({ validUntil: z.number().int().optional(), maxDevices: z.number().int().min(1).max(100).optional(), reason: reasonSchema }),
      response: z.object({ ok: z.literal(true) }),
      errors: [403, 404, 409],
    },
    async ({ params, body, user }) => {
      await admin(user.id, 'licenses.manage')
      const now = ctx.clock()
      const before = await license(ctx, params.companyId, params.licenseId)
      notRevoked(before)
      const changes: Prisma.LicenseUpdateInput = {}
      const changed: Record<string, { from: unknown; to: unknown }> = {}
      if (body.validUntil !== undefined) {
        if (body.validUntil <= before.validFrom.getTime()) throw invalid('validUntil must be after the start date.', { validUntil: 'must be after the start date' })
        changes.validUntil = new Date(body.validUntil)
        changed.validUntil = { from: before.validUntil.getTime(), to: body.validUntil }
        // A renewed license that had lapsed by date becomes active again.
        if (before.status === 'expired' && body.validUntil > now.getTime()) {
          changes.status = 'active'
          changed.status = { from: 'expired', to: 'active' }
        }
      }
      if (body.maxDevices !== undefined) {
        const active = await countActiveDevices(ctx.db, params.companyId, params.licenseId)
        if (body.maxDevices < active) {
          throw precondition(`${active} devices are active. Revoke some before lowering the limit to ${body.maxDevices}.`)
        }
        changes.maxDevices = body.maxDevices
        changed.maxDevices = { from: before.maxDevices, to: body.maxDevices }
      }
      if (!Object.keys(changes).length) throw invalid('Nothing to change.')
      await ctx.db.license.update({ where: { id: params.licenseId }, data: changes })
      await recordEvent(ctx.db, now, { type: 'license.update', actorId: user.id, companyId: params.companyId, licenseId: params.licenseId, changed, reason: body.reason })
      return { ok: true as const }
    },
  )

  api.route(
    {
      method: 'post',
      path: '/admin/companies/:companyId/licenses/:licenseId/status',
      tag: TAG.licenses,
      summary: 'Suspend, reactivate or revoke a license (revocation is final; expiry is by date)',
      params: LicenseParams,
      body: z.object({ status: z.enum(['active', 'suspended', 'revoked']), reason: reasonSchema }),
      response: z.object({ status: z.string() }),
      errors: [403, 404, 409],
    },
    async ({ params, body, user }) => {
      await admin(user.id, 'licenses.manage')
      const now = ctx.clock()
      const before = await license(ctx, params.companyId, params.licenseId)
      notRevoked(before)
      if (body.status === 'active' && before.validUntil.getTime() < now.getTime()) {
        throw precondition('This license has ended. Extend it before reactivating.')
      }
      await ctx.db.license.update({ where: { id: params.licenseId }, data: { status: body.status } })
      await recordEvent(ctx.db, now, {
        type: 'license.status',
        actorId: user.id,
        companyId: params.companyId,
        licenseId: params.licenseId,
        from: before.status,
        to: body.status,
        reason: body.reason,
      })
      return { status: body.status }
    },
  )

  api.route(
    {
      method: 'post',
      path: '/admin/companies/:companyId/licenses/:licenseId/rotate-code',
      tag: TAG.licenses,
      summary: 'Issue a new activation code (shown once); the old one stops working',
      params: LicenseParams,
      body: z.object({ reason: reasonSchema }),
      response: z.object({ activationCode: z.string() }),
      errors: [403, 404, 409],
    },
    async ({ params, body, user }) => {
      await admin(user.id, 'licenses.manage')
      const now = ctx.clock()
      notRevoked(await license(ctx, params.companyId, params.licenseId))
      const activationCode = generateActivationCode()
      await ctx.db.license.update({ where: { id: params.licenseId }, data: { activationCodeHash: hashCode(activationCode) } })
      await recordEvent(ctx.db, now, { type: 'license.rotate_code', actorId: user.id, companyId: params.companyId, licenseId: params.licenseId, reason: body.reason })
      return { activationCode }
    },
  )

  // --- Devices -----------------------------------------------------------------

  api.route(
    {
      method: 'get',
      path: '/admin/devices',
      tag: TAG.devices,
      summary: 'Phones, most recently seen first',
      query: PageQuery.extend({ status: z.enum(['active', 'revoked']).optional(), companyId: idSchema().optional(), licenseId: idSchema().optional() }),
      response: pageOf(DeviceOut, 'DevicePage'),
      errors: [403],
    },
    async ({ query, user }) => {
      await admin(user.id)
      const where = {
        ...(query.status ? { status: query.status } : {}),
        ...(query.companyId ? { companyId: query.companyId } : {}),
        ...(query.licenseId ? { licenseId: query.licenseId } : {}),
      }
      type Key = { companyId_id: { companyId: string; id: string } }
      return page(
        (args) =>
          ctx.db.device.findMany({
            where,
            orderBy: [{ lastSeenAt: { sort: 'desc', nulls: 'last' } }, { companyId: 'asc' }, { id: 'asc' }],
            ...args,
            cursor: args.cursor as Key | undefined,
          }),
        (d): Key => ({ companyId_id: { companyId: d.companyId, id: d.id } }),
        deviceOut,
        query,
      )
    },
  )

  api.route(
    { method: 'get', path: '/admin/companies/:companyId/devices/:deviceId', tag: TAG.devices, summary: 'One phone', params: DeviceParams, response: DeviceOut, errors: [403, 404] },
    async ({ params, user }) => {
      await admin(user.id)
      const d = await ctx.db.device.findUnique({ where: { companyId_id: { companyId: params.companyId, id: params.deviceId } } })
      if (!d) throw notFound('Device')
      return deviceOut(d)
    },
  )

  api.route(
    {
      method: 'post',
      path: '/admin/companies/:companyId/devices/:deviceId/revoke',
      tag: TAG.devices,
      summary: 'Deactivate a phone; it becomes read-only as soon as it reconnects',
      params: DeviceParams,
      body: z.object({ reason: reasonSchema }),
      response: z.object({ ok: z.literal(true) }),
      errors: [403, 404, 409],
    },
    async ({ params, body, user }) => {
      await admin(user.id, 'devices.revoke')
      const now = ctx.clock()
      const where = { companyId_id: { companyId: params.companyId, id: params.deviceId } }
      const before = await ctx.db.device.findUnique({ where })
      if (!before) throw notFound('Device')
      if (before.status === 'revoked') throw precondition('This device is already revoked.')
      await ctx.db.device.update({ where, data: { status: 'revoked', revokedAt: now, revokedBy: user.id, revokeReason: body.reason } })
      await recordEvent(ctx.db, now, {
        type: 'device.revoke',
        actorId: user.id,
        companyId: params.companyId,
        deviceId: params.deviceId,
        licenseId: before.licenseId,
        reason: body.reason,
      })
      return { ok: true as const }
    },
  )

  api.route(
    {
      method: 'get',
      path: '/admin/replacement-requests',
      tag: TAG.devices,
      summary: 'Device replacement requests, newest first',
      query: PageQuery.extend({ status: z.enum(['pending', 'approved', 'rejected']).optional() }),
      response: pageOf(RequestOut, 'ReplacementRequestPage'),
      errors: [403],
    },
    async ({ query, user }) => {
      await admin(user.id)
      const result = await page(
        (args) =>
          ctx.db.deviceReplacementRequest.findMany({
            where: query.status ? { status: query.status } : {},
            orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
            include: { company: { select: { name: true } } },
            ...args,
            cursor: args.cursor as { id: string } | undefined,
          }),
        (r) => ({ id: r.id }),
        (r) => r,
        query,
      )
      const emails = new Map(
        (await ctx.db.user.findMany({ where: { id: { in: result.items.map((r) => r.requestedBy) } }, select: { id: true, email: true } })).map((u) => [u.id, u.email]),
      )
      return { items: result.items.map((r) => requestOut({ ...r, requesterEmail: emails.get(r.requestedBy) ?? null })), next: result.next }
    },
  )

  // --- Audit -------------------------------------------------------------------

  api.route(
    {
      method: 'get',
      path: '/admin/audit-events',
      tag: TAG.audit,
      summary: 'Server-written history, newest first',
      query: PageQuery.extend({
        companyId: idSchema().optional(),
        licenseId: idSchema().optional(),
        deviceId: idSchema(64).optional(),
        type: z.string().max(80).optional(),
      }),
      response: pageOf(EventOut, 'AuditEventPage'),
      errors: [403],
    },
    async ({ query, user }) => {
      await admin(user.id)
      const where = {
        ...(query.companyId ? { companyId: query.companyId } : {}),
        ...(query.licenseId ? { licenseId: query.licenseId } : {}),
        ...(query.deviceId ? { deviceId: query.deviceId } : {}),
        ...(query.type ? { type: query.type } : {}),
      }
      return page(
        (args) => ctx.db.auditEvent.findMany({ where, orderBy: [{ at: 'desc' }, { id: 'desc' }], ...args, cursor: args.cursor as { id: string } | undefined }),
        (e) => ({ id: e.id }),
        eventOut,
        query,
      )
    },
  )
}
