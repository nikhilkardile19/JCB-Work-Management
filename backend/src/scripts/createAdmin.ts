/**
 * Grants developer-admin access (replaces adding `developerAdmins/{uid}` in
 * the Firebase console).
 *
 *   npm run admin:create -- --email you@company.in [--role super|support]
 *                           [--permissions companies.manage,licenses.manage,devices.revoke]
 *
 * Creates the account if needed and prints a one-time link (24 h) to set the
 * password when the account has none.
 */
import { ADMIN_PERMISSIONS } from '../modules/admin/adminAccess.js'
import { recordEvent } from '../modules/audit/auditEvents.js'
import { createResetLink } from '../modules/auth/authService.js'
import { findOrCreateUser } from '../modules/members/users.js'
import { arg, cliContext } from './cliContext.js'

const ctx = cliContext()
const email = arg('email').trim().toLowerCase()
const role = arg('role', 'support')
const permissions = arg('permissions', '').split(',').map((p) => p.trim()).filter(Boolean)

if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw new Error('--email must be a valid email address')
if (role !== 'super' && role !== 'support') throw new Error('--role must be super or support')
const unknown = permissions.filter((p) => !ADMIN_PERMISSIONS.includes(p as never))
if (unknown.length) throw new Error(`Unknown permissions: ${unknown.join(', ')}`)

try {
  const now = ctx.clock()
  const { user, newUser } = await findOrCreateUser(ctx.db, email, now)
  await ctx.db.developerAdmin.upsert({
    where: { userId: user.id },
    create: { userId: user.id, role, permissions },
    update: { role, permissions },
  })
  await recordEvent(ctx.db, now, { type: 'admin.grant', actorId: null, userId: user.id, email, role, permissions, via: 'cli' })
  console.log(`${email} is now a ${role} developer admin${permissions.length ? ` (${permissions.join(', ')})` : ''}.`)
  if (newUser || !user.passwordHash) {
    console.log(`Set the password within 24 hours: ${await createResetLink(ctx, user.id, 24 * 60)}`)
  }
} finally {
  await ctx.db.$disconnect()
}
