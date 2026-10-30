import type { Db, Tx } from '../../database/prisma.js'
import { newId } from '../../lib/ids.js'

/**
 * Finds the account for [email], creating it without a password if needed.
 * New users choose their password through "Forgot password" — the same flow
 * the Cloud Functions relied on (they created a random password).
 */
export async function findOrCreateUser(db: Db | Tx, email: string, now: Date) {
  const existing = await db.user.findUnique({ where: { email } })
  if (existing) return { user: existing, newUser: false }
  const user = await db.user.create({ data: { id: newId(), email, createdAt: now } })
  return { user, newUser: true }
}
