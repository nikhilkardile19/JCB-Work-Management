import type { AppContext } from '../../context.js'
import { prismaCode } from '../../database/prisma.js'
import { ApiError, denied, invalid, notFound, precondition } from '../../lib/errors.js'
import type { Api } from '../../lib/http.js'
import { newId } from '../../lib/ids.js'
import { idSchema, reasonSchema, z } from '../../lib/validation.js'
import { requireAdmin } from '../admin/adminAccess.js'
import { recordEvent } from '../audit/auditEvents.js'
import { requireActiveMember, requireMember } from '../companies/access.js'
import { hashCode } from '../licenses/activationCodes.js'
import { countActiveDevices, effectiveStatus, lockLicense } from '../licenses/licenseRules.js'
import { assertWithinLimit, consume, LIMITS } from '../rate-limits/rateLimit.js'

/**
 * Device replacement (ported from `functions/src/replacements.ts`): a phone
 * that can't activate because the license is full asks for a replacement; a
 * developer admin approves by revoking an old phone and authorizing the new
 * one in one transaction, so the device limit can never be exceeded. Old
 * phones need not take part (lost/damaged): they become read-only when they
 * next reconnect, and their local data is never touched.
 */

async function requestReplacement(
  ctx: AppContext,
  uid: string,
  companyId: string,
  d: { activationCode: string; newDeviceId: string; newDeviceModel?: string; reason: string },
) {
  const now = ctx.clock()
  const access = await requireActiveMember(ctx.db, companyId, uid)
  const codeKey = `codeFailures_${uid}`
  await assertWithinLimit(ctx.db, codeKey, LIMITS.codeFailures, now)

  // The activation code proves the requester was given access by the company.
  const license = await ctx.db.license.findUnique({
    where: { companyId_activationCodeHash: { companyId, activationCodeHash: hashCode(d.activationCode) } },
  })
  if (!license) {
    await consume(ctx.db, codeKey, LIMITS.codeFailures, now)
    throw precondition('That activation code is not valid for this company.', 'invalid_code')
  }
  const status = effectiveStatus(license.status, license.validFrom, license.validUntil, now)
  if (status !== 'active') throw precondition(`The license is ${status.replace('_', ' ')}.`, status)

  const device = await ctx.db.device.findUnique({ where: { companyId_id: { companyId, id: d.newDeviceId } } })
  if (device?.status === 'active') return { requestId: null, status: 'already_active' as const }
  if (device?.status === 'revoked') {
    throw precondition('This phone was deactivated. Reinstall the app to register it as a new phone.', 'device_revoked')
  }

  const open = await ctx.db.deviceReplacementRequest.findFirst({
    where: { companyId, newDeviceId: d.newDeviceId, status: 'pending' },
  })
  if (open) return { requestId: open.id, status: 'pending' as const }

  await consume(ctx.db, `replacementRequests_${uid}`, LIMITS.replacementRequests, now)
  const id = newId()
  try {
    await ctx.db.deviceReplacementRequest.create({
      data: {
        id,
        companyId,
        licenseId: license.id,
        newDeviceId: d.newDeviceId,
        newDeviceModel: d.newDeviceModel ?? null,
        requestedBy: uid,
        reason: d.reason,
        status: 'pending',
        createdAt: now,
      },
    })
  } catch (e) {
    // A concurrent identical request won the race (one pending per phone).
    if (prismaCode(e) !== 'P2002') throw e
    const winner = await ctx.db.deviceReplacementRequest.findFirstOrThrow({
      where: { companyId, newDeviceId: d.newDeviceId, status: 'pending' },
    })
    return { requestId: winner.id, status: 'pending' as const }
  }
  await recordEvent(ctx.db, now, {
    type: 'replacement.request',
    companyId,
    licenseId: license.id,
    deviceId: d.newDeviceId,
    actorId: uid,
    requestId: id,
    reason: d.reason,
    requesterEmail: (await ctx.db.user.findUnique({ where: { id: uid } }))?.email ?? null,
    role: access.role,
  })
  return { requestId: id, status: 'pending' as const }
}

async function reviewReplacement(
  ctx: AppContext,
  uid: string,
  companyId: string,
  requestId: string,
  d: { decision: 'approve' | 'reject'; reason: string; revokeDeviceId?: string },
) {
  const now = ctx.clock()
  await requireAdmin(ctx.db, uid, 'devices.revoke')
  const outcome = await ctx.db.$transaction(async (tx) => {
    const found = await tx.deviceReplacementRequest.findFirst({ where: { id: requestId, companyId } })
    if (!found) throw notFound('Request')
    await lockLicense(tx, found.licenseId)
    const req = await tx.deviceReplacementRequest.findUniqueOrThrow({ where: { id: requestId } })
    if (req.status !== 'pending') throw precondition(`This request was already ${req.status}.`)
    const review = { reviewedBy: uid, reviewedAt: now, reviewReason: d.reason }

    if (d.decision === 'reject') {
      await tx.deviceReplacementRequest.update({ where: { id: requestId }, data: { status: 'rejected', ...review } })
      return { status: 'rejected' as const, revoked: null, req }
    }

    const license = await tx.license.findUniqueOrThrow({ where: { id: req.licenseId } })
    if (effectiveStatus(license.status, license.validFrom, license.validUntil, now) !== 'active') {
      throw precondition('The license is not active; renew or reactivate it first.')
    }
    const newDevice = await tx.device.findUnique({ where: { companyId_id: { companyId, id: req.newDeviceId } } })
    if (newDevice?.status === 'revoked') throw precondition('The new phone was deactivated; it must reinstall the app.')
    const revokeId = d.revokeDeviceId ?? null
    if (revokeId) {
      const old = await tx.device.findUnique({ where: { companyId_id: { companyId, id: revokeId } } })
      if (!old || old.status !== 'active' || old.licenseId !== license.id) {
        throw invalid('The phone to replace must be an active phone on this license.')
      }
    }
    const alreadyActive = newDevice?.status === 'active'
    const activeAfter = (await countActiveDevices(tx, companyId, license.id)) - (revokeId ? 1 : 0) + (alreadyActive ? 0 : 1)
    if (activeAfter > license.maxDevices) {
      throw new ApiError('failed_precondition', 'The license is full. Choose which phone this one replaces.', { reason: 'device_limit' })
    }
    if (revokeId) {
      await tx.device.update({
        where: { companyId_id: { companyId, id: revokeId } },
        data: { status: 'revoked', revokedAt: now, revokedBy: uid, revokeReason: `Replaced by another phone: ${d.reason}`, replacedBy: req.newDeviceId },
      })
    }
    if (!alreadyActive) {
      const fields = {
        licenseId: license.id,
        userId: req.requestedBy,
        deviceModel: req.newDeviceModel,
        platform: 'android',
        status: 'active' as const,
        activatedAt: now,
        lastSeenAt: now,
        replacementForDeviceId: revokeId,
      }
      await tx.device.upsert({
        where: { companyId_id: { companyId, id: req.newDeviceId } },
        create: { companyId, id: req.newDeviceId, ...fields },
        update: fields,
      })
    }
    await tx.deviceReplacementRequest.update({ where: { id: requestId }, data: { status: 'approved', revokedDeviceId: revokeId, ...review } })
    return { status: 'approved' as const, revoked: revokeId, req }
  })

  const base = { companyId, licenseId: outcome.req.licenseId, actorId: uid, requestId, reason: d.reason }
  if (outcome.status === 'rejected') {
    await recordEvent(ctx.db, now, { type: 'replacement.reject', ...base, deviceId: outcome.req.newDeviceId })
  } else {
    await recordEvent(ctx.db, now, { type: 'replacement.approve', ...base, deviceId: outcome.req.newDeviceId, oldDeviceId: outcome.revoked })
    if (outcome.revoked) await recordEvent(ctx.db, now, { type: 'device.revoke', ...base, deviceId: outcome.revoked })
    await recordEvent(ctx.db, now, { type: 'device.activate', ...base, deviceId: outcome.req.newDeviceId, replacementFor: outcome.revoked })
  }
  return { status: outcome.status, revokedDeviceId: outcome.revoked }
}

export function registerReplacementRoutes(api: Api) {
  const { ctx } = api

  api.route(
    {
      method: 'post',
      path: '/companies/:companyId/device-replacements',
      tag: 'Licensing',
      summary: 'Ask for this phone to replace one on a full license',
      params: z.object({ companyId: idSchema() }),
      body: z.object({
        activationCode: z.string().min(1).max(40),
        newDeviceId: idSchema(64),
        newDeviceModel: z.string().min(1).max(100).optional(),
        reason: z.string().trim().min(3, 'Say why the phone is being replaced.').max(500),
      }),
      response: z.object({ requestId: z.string().nullable(), status: z.enum(['pending', 'already_active']) }),
      errors: [403, 409, 429],
    },
    ({ params, body, user }) => requestReplacement(ctx, user.id, params.companyId, body),
  )

  api.route(
    {
      method: 'get',
      path: '/companies/:companyId/device-replacements/:requestId',
      tag: 'Licensing',
      summary: 'State of a replacement request (requester, or company owner/admin)',
      params: z.object({ companyId: idSchema(), requestId: idSchema() }),
      response: z.object({
        requestId: z.string(),
        status: z.enum(['pending', 'approved', 'rejected']),
        reviewReason: z.string().nullable(),
      }),
      errors: [403, 404],
    },
    async ({ params, user }) => {
      const access = await requireMember(ctx.db, params.companyId, user.id)
      const req = await ctx.db.deviceReplacementRequest.findFirst({ where: { id: params.requestId, companyId: params.companyId } })
      if (!req) throw notFound('Request')
      if (req.requestedBy !== user.id && access.role !== 'owner' && access.role !== 'admin') {
        throw denied('Only the requester or the company owner/admins can see this request.')
      }
      return { requestId: req.id, status: req.status, reviewReason: req.reviewReason }
    },
  )

  api.route(
    {
      method: 'post',
      path: '/admin/companies/:companyId/replacement-requests/:requestId/review',
      tag: 'Admin: devices',
      summary: 'Approve (optionally revoking an old phone) or reject a replacement request',
      params: z.object({ companyId: idSchema(), requestId: idSchema() }),
      body: z.object({
        decision: z.enum(['approve', 'reject']),
        reason: reasonSchema,
        revokeDeviceId: idSchema(64).optional(),
      }),
      response: z.object({ status: z.enum(['approved', 'rejected']), revokedDeviceId: z.string().nullable() }),
      errors: [403, 404, 409],
    },
    ({ params, body, user }) => reviewReplacement(ctx, user.id, params.companyId, params.requestId, body),
  )
}
