import type { Db } from '../../database/prisma.js'
import { denied } from '../../lib/errors.js'

/**
 * Developer admins (`developer_admins`, replaces `developerAdmins/{uid}`):
 *   role 'super' may do everything; 'support' only what `permissions` grants.
 * Checked on the server for every admin request — hiding buttons in the
 * portal is a convenience, not the control.
 */
export type AdminPermission = 'companies.manage' | 'licenses.manage' | 'devices.revoke'

export const ADMIN_PERMISSIONS: readonly AdminPermission[] = ['companies.manage', 'licenses.manage', 'devices.revoke']

export async function requireAdmin(db: Db, uid: string, permission?: AdminPermission) {
  const admin = await db.developerAdmin.findUnique({ where: { userId: uid }, include: { user: { select: { email: true } } } })
  if (!admin) throw denied('Developer admins only.', 'not_admin')
  if (permission && admin.role !== 'super' && !admin.permissions.includes(permission)) {
    throw denied(`Your admin role does not allow ${permission}.`)
  }
  return {
    uid,
    email: admin.user.email,
    role: admin.role,
    permissions: admin.permissions.filter((p): p is AdminPermission => ADMIN_PERMISSIONS.includes(p as AdminPermission)),
  }
}
