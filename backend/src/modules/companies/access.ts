import type { Db, Tx } from '../../database/prisma.js'
import type { Company, CompanyMember, CompanyRole } from '../../generated/prisma/client.js'
import { ApiError, denied, precondition } from '../../lib/errors.js'

export interface Access {
  company: Company
  member: CompanyMember
  role: CompanyRole
}

/**
 * The caller's active membership, read from the database on every request —
 * never from the client or the token. Disabled members lose access at once.
 */
export async function activeMembership(db: Db | Tx, companyId: string, userId: string): Promise<Access | null> {
  const member = await db.companyMember.findUnique({
    where: { companyId_userId: { companyId, userId } },
    include: { company: true },
  })
  if (!member || member.status !== 'active') return null
  const { company, ...m } = member
  return { company, member: m, role: m.role }
}

/** Active member of the company (company in any state: read-only access). */
export async function requireMember(db: Db | Tx, companyId: string, userId: string): Promise<Access> {
  const access = await activeMembership(db, companyId, userId)
  if (!access) throw denied('You are not a member of this company.', 'not_member')
  return access
}

/** Active member of an approved (active) company — required for any change. */
export async function requireActiveMember(db: Db | Tx, companyId: string, userId: string): Promise<Access> {
  const access = await requireMember(db, companyId, userId)
  if (access.company.status !== 'active') {
    throw precondition('This company is not approved yet.', 'company_inactive')
  }
  return access
}

export function requireRole(access: Access, roles: readonly CompanyRole[], message: string): void {
  if (!roles.includes(access.role)) throw new ApiError('permission_denied', message)
}
