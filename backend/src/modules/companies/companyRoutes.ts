import type { Api } from '../../lib/http.js'
import { Reply } from '../../lib/http.js'
import { alreadyExists } from '../../lib/errors.js'
import { idSchema, z } from '../../lib/validation.js'
import { requireMember, requireRole } from './access.js'
import { CompanyOut, companyOut, CompanyProfileInput } from './companyProfile.js'

const Role = z.enum(['owner', 'admin', 'manager', 'operator', 'accounts'])
const CompanyParams = z.object({ companyId: idSchema() })

/**
 * Mobile company endpoints. Replace the membership collection-group query,
 * the registration batch write and the profile update the app made directly
 * against Firestore (ADR 0002).
 */
export function registerCompanyRoutes(api: Api) {
  const { ctx } = api

  api.route(
    {
      method: 'get',
      path: '/me/memberships',
      tag: 'Companies',
      summary: "The caller's active memberships with their companies (any company status)",
      response: z.object({
        items: z.array(z.object({ role: Role, status: z.literal('active'), company: CompanyOut }).openapi('Membership')),
      }),
    },
    async ({ user }) => {
      const rows = await ctx.db.companyMember.findMany({
        where: { userId: user.id, status: 'active' },
        include: { company: true },
        orderBy: { createdAt: 'asc' },
      })
      return { items: rows.map((m) => ({ role: m.role, status: 'active' as const, company: companyOut(m.company) })) }
    },
  )

  api.route(
    {
      method: 'post',
      path: '/companies',
      tag: 'Companies',
      summary: 'Register a company; it starts pending with the caller as owner',
      description: 'Idempotent for the same owner and id (a retried request returns the existing company with 200).',
      body: CompanyProfileInput.extend({ id: idSchema() }),
      response: CompanyOut,
      status: 201,
      errors: [409],
    },
    async ({ body, user }) => {
      const { id, ...profile } = body
      const now = ctx.clock()
      const existing = await ctx.db.company.findUnique({ where: { id } })
      if (existing) {
        if (existing.ownerUserId === user.id) return new Reply(200, companyOut(existing))
        throw alreadyExists('That company ID is taken.')
      }
      const company = await ctx.db.$transaction(async (tx) => {
        const c = await tx.company.create({
          data: { id, ...profile, currency: 'INR', status: 'pending', ownerUserId: user.id, createdBy: user.id, updatedBy: user.id, createdAt: now, updatedAt: now },
        })
        await tx.companyMember.create({ data: { companyId: id, userId: user.id, role: 'owner', status: 'active', createdAt: now } })
        return c
      })
      return new Reply(201, companyOut(company))
    },
  )

  api.route(
    {
      method: 'patch',
      path: '/companies/:companyId',
      tag: 'Companies',
      summary: 'Edit the company profile (owner/admin; never status, owner or id)',
      params: CompanyParams,
      body: CompanyProfileInput,
      response: CompanyOut,
      errors: [403],
    },
    async ({ params, body, user }) => {
      const access = await requireMember(ctx.db, params.companyId, user.id)
      requireRole(access, ['owner', 'admin'], 'Only the owner or an admin can edit the company profile.')
      const company = await ctx.db.company.update({
        where: { id: params.companyId },
        data: { ...body, updatedBy: user.id, updatedAt: ctx.clock() },
      })
      return companyOut(company)
    },
  )
}
