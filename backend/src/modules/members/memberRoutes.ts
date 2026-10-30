import type { AppContext } from '../../context.js'
import type { CompanyRole } from '../../generated/prisma/client.js'
import { ApiError, alreadyExists, denied, invalid, notFound, precondition } from '../../lib/errors.js'
import type { Api } from '../../lib/http.js'
import { emailSchema, idSchema, z } from '../../lib/validation.js'
import { recordEvent } from '../audit/auditEvents.js'
import { requireActiveMember, requireMember } from '../companies/access.js'
import { consume, LIMITS } from '../rate-limits/rateLimit.js'
import { findOrCreateUser } from './users.js'

/**
 * Company user management by the company's owner/admins (ported from
 * `functions/src/users.ts`). The owner can't be changed here; only the owner
 * can grant, change or re-enable admins; nobody can change themselves.
 */
const ASSIGNABLE = ['admin', 'manager', 'operator', 'accounts'] as const

const Params = z.object({ companyId: idSchema() })
const MemberParams = z.object({ companyId: idSchema(), userId: idSchema() })

const MemberOut = z
  .object({
    uid: z.string(),
    email: z.string(),
    role: z.enum(['owner', 'admin', 'manager', 'operator', 'accounts']),
    status: z.enum(['active', 'disabled']),
  })
  .openapi('CompanyMember')

async function requireManager(ctx: AppContext, companyId: string, uid: string) {
  const access = await requireActiveMember(ctx.db, companyId, uid).catch((e: unknown) => {
    if (e instanceof ApiError && e.extra.reason === 'company_inactive') throw precondition('This company is not active.')
    throw e
  })
  if (access.role !== 'owner' && access.role !== 'admin') {
    throw denied('Only the company owner or an admin can manage users.')
  }
  return access.role
}

async function target(ctx: AppContext, uid: string, companyId: string, userId: string, callerRole: CompanyRole) {
  if (userId === uid) throw precondition('You cannot change your own access.')
  const m = await ctx.db.companyMember.findUnique({ where: { companyId_userId: { companyId, userId } } })
  if (!m) throw notFound('User in this company')
  if (m.role === 'owner') throw precondition('The owner cannot be changed here.')
  if (m.role === 'admin' && callerRole !== 'owner') throw denied('Only the owner can change admins.')
  return m
}

export function registerMemberRoutes(api: Api) {
  const { ctx } = api

  api.route(
    {
      method: 'get',
      path: '/companies/:companyId/members',
      tag: 'Company users',
      summary: "The company's members (any active member may list them)",
      params: Params,
      response: z.object({ items: z.array(MemberOut) }),
      errors: [403],
    },
    async ({ params, user }) => {
      await requireMember(ctx.db, params.companyId, user.id)
      const rows = await ctx.db.companyMember.findMany({
        where: { companyId: params.companyId },
        include: { user: { select: { email: true } } },
      })
      return {
        items: rows
          .map((m) => ({ uid: m.userId, email: m.user.email, role: m.role, status: m.status }))
          .sort((a, b) => a.email.localeCompare(b.email)),
      }
    },
  )

  api.route(
    {
      method: 'post',
      path: '/companies/:companyId/members',
      tag: 'Company users',
      summary: 'Add someone by email (the account is created if needed)',
      params: Params,
      body: z.object({ email: emailSchema, role: z.enum(ASSIGNABLE) }),
      response: z.object({ userId: z.string(), newUser: z.boolean() }),
      errors: [403, 409, 429],
    },
    async ({ params, body, user }) => {
      const { companyId } = params
      const now = ctx.clock()
      const callerRole = await requireManager(ctx, companyId, user.id)
      if (body.role === 'admin' && callerRole !== 'owner') throw denied('Only the owner can add admins.')
      await consume(ctx.db, `invites_${companyId}`, LIMITS.invites, now)

      const { invitee, newUser, reinvite } = await ctx.db.$transaction(async (tx) => {
        const { user: invitee, newUser } = await findOrCreateUser(tx, body.email, now)
        const existing = await tx.companyMember.findUnique({ where: { companyId_userId: { companyId, userId: invitee.id } } })
        if (existing?.status === 'active') throw alreadyExists(`${body.email} is already a member.`)
        if (existing?.role === 'owner') throw precondition('The owner cannot be re-invited.')
        // Re-inviting a disabled admin would undo the owner's decision.
        if (existing?.role === 'admin' && callerRole !== 'owner') throw denied('Only the owner can re-enable an admin.')
        await tx.companyMember.upsert({
          where: { companyId_userId: { companyId, userId: invitee.id } },
          create: { companyId, userId: invitee.id, role: body.role, status: 'active', invitedBy: user.id, createdAt: now },
          update: { role: body.role, status: 'active', invitedBy: user.id },
        })
        return { invitee, newUser, reinvite: !!existing }
      })
      await recordEvent(ctx.db, now, {
        type: reinvite ? 'user.reinvite' : 'user.invite',
        companyId,
        actorId: user.id,
        userId: invitee.id,
        email: body.email,
        role: body.role,
        newUser,
      })
      return { userId: invitee.id, newUser }
    },
  )

  api.route(
    {
      method: 'patch',
      path: '/companies/:companyId/members/:userId',
      tag: 'Company users',
      summary: "Change a member's role or disable/re-enable them (exactly one of role, status)",
      description: 'Disabled members lose access immediately; data on their phones is kept.',
      params: MemberParams,
      body: z.object({ role: z.enum(ASSIGNABLE).optional(), status: z.enum(['active', 'disabled']).optional() }),
      response: z.union([z.object({ role: z.string() }), z.object({ status: z.string() })]),
      errors: [403, 404, 409],
    },
    async ({ params, body, user }) => {
      if ((body.role === undefined) === (body.status === undefined)) throw invalid('Send exactly one of role or status.')
      const { companyId, userId } = params
      const now = ctx.clock()
      const callerRole = await requireManager(ctx, companyId, user.id)
      if (body.role === 'admin' && callerRole !== 'owner') throw denied('Only the owner can make admins.')
      const m = await target(ctx, user.id, companyId, userId, callerRole)
      const where = { companyId_userId: { companyId, userId } }
      if (body.role !== undefined) {
        await ctx.db.companyMember.update({ where, data: { role: body.role } })
        await recordEvent(ctx.db, now, { type: 'user.role', companyId, actorId: user.id, userId, from: m.role, to: body.role })
        return { role: body.role }
      }
      await ctx.db.companyMember.update({ where, data: { status: body.status } })
      await recordEvent(ctx.db, now, { type: 'user.status', companyId, actorId: user.id, userId, from: m.status, to: body.status })
      return { status: body.status! }
    },
  )
}
