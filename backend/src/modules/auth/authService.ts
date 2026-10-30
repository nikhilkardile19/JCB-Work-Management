import type { AppContext } from '../../context.js'
import type { SessionClient } from '../../generated/prisma/client.js'
import { ApiError, denied, invalid, unauthenticated } from '../../lib/errors.js'
import { newId, randomToken, sha256 } from '../../lib/ids.js'
import { recordEvent } from '../audit/auditEvents.js'
import { assertWithinLimit, consume, LIMITS, tryConsume } from '../rate-limits/rateLimit.js'
import { burnVerifyTime, hashPassword, needsRehash, verifyPassword } from './passwords.js'
import { endAllSessions, startSession, type ClientMeta, type Session } from './sessions.js'

const wrongCredentials = () => unauthenticated('Incorrect email or password.', 'invalid_credentials')

export async function login(
  ctx: AppContext,
  input: { email: string; password: string; client: SessionClient },
  meta: ClientMeta,
): Promise<Session> {
  const now = ctx.clock()
  const emailKey = `login:email:${input.email}`
  const ipKey = `login:ip:${meta.ip ?? 'unknown'}`
  await assertWithinLimit(ctx.db, emailKey, LIMITS.loginFailuresPerEmail, now)
  await assertWithinLimit(ctx.db, ipKey, LIMITS.loginFailuresPerIp, now)

  const user = await ctx.db.user.findUnique({ where: { email: input.email } })
  const ok = user?.passwordHash ? await verifyPassword(user.passwordHash, input.password) : (await burnVerifyTime(input.password), false)
  if (!user || !ok) {
    await tryConsume(ctx.db, emailKey, LIMITS.loginFailuresPerEmail, now)
    await tryConsume(ctx.db, ipKey, LIMITS.loginFailuresPerIp, now)
    throw wrongCredentials()
  }
  if (user.status !== 'active') {
    throw denied('This account has been disabled. Contact your administrator.', 'user_disabled')
  }
  const passwordHash = needsRehash(user.passwordHash!) ? await hashPassword(input.password) : undefined
  await ctx.db.user.update({ where: { id: user.id }, data: { lastLoginAt: now, ...(passwordHash ? { passwordHash } : {}) } })
  return startSession(ctx, user, input.client, meta)
}

export async function currentUser(ctx: AppContext, userId: string) {
  const user = await ctx.db.user.findUniqueOrThrow({ where: { id: userId }, include: { developerAdmin: true } })
  const admin = user.developerAdmin
  return {
    id: user.id,
    email: user.email,
    developerAdmin: admin ? { role: admin.role, permissions: admin.permissions } : null,
  }
}

/**
 * Creates a single-use password link (only the newest one works). Used by
 * "Forgot password" and by the admin CLI for accounts without a password.
 */
export async function createResetLink(ctx: AppContext, userId: string, ttlMinutes = ctx.config.PASSWORD_RESET_TTL_MINUTES) {
  const now = ctx.clock()
  const token = randomToken()
  await ctx.db.$transaction(async (tx) => {
    await tx.passwordResetToken.updateMany({ where: { userId, usedAt: null }, data: { usedAt: now } })
    await tx.passwordResetToken.create({
      data: { id: newId(), userId, tokenHash: sha256(token), expiresAt: new Date(now.getTime() + ttlMinutes * 60_000), createdAt: now },
    })
  })
  return `${ctx.config.PASSWORD_RESET_URL}?token=${encodeURIComponent(token)}`
}

/**
 * Emails a single-use reset link. Always succeeds from the caller's point of
 * view, so it never reveals whether an account exists.
 */
export async function forgotPassword(ctx: AppContext, email: string, ip = 'unknown') {
  const now = ctx.clock()
  await consume(ctx.db, `reset:ip:${ip}`, LIMITS.resetRequestsPerIp, now)
  const user = await ctx.db.user.findUnique({ where: { email } })
  if (!user || user.status !== 'active') return
  const limit = await tryConsume(ctx.db, `reset:email:${email}`, LIMITS.resetEmails, now)
  if (!limit.ok) return

  const link = await createResetLink(ctx, user.id)
  // Not awaited: response time must not depend on the mail server.
  ctx.mailer
    .send({
      to: user.email,
      subject: 'Reset your JCB Works password',
      text: [
        'Someone asked to reset the password for this JCB Works account.',
        '',
        `Open this link within ${ctx.config.PASSWORD_RESET_TTL_MINUTES} minutes to choose a new password:`,
        link,
        '',
        'If this was not you, ignore this email; your password stays the same.',
      ].join('\n'),
    })
    .catch((err: unknown) => ctx.logger.error({ err, userId: user.id }, 'Password reset email failed'))
}

/** Sets a new password from a reset link and signs the user out everywhere. */
export async function resetPassword(ctx: AppContext, token: string, password: string) {
  const now = ctx.clock()
  const row = await ctx.db.passwordResetToken.findUnique({ where: { tokenHash: sha256(token) } })
  if (!row || row.usedAt || row.expiresAt <= now) {
    throw new ApiError('invalid_argument', 'This reset link is invalid or has expired. Ask for a new one.', {
      reason: 'invalid_reset_token',
    })
  }
  const passwordHash = await hashPassword(password)
  await ctx.db.$transaction(async (tx) => {
    // Single use, even under concurrent submissions.
    const claimed = await tx.passwordResetToken.updateMany({ where: { id: row.id, usedAt: null }, data: { usedAt: now } })
    if (claimed.count !== 1) throw invalid('This reset link was already used. Ask for a new one.')
    await tx.user.update({
      where: { id: row.userId },
      data: { passwordHash, passwordChangedAt: now, tokenVersion: { increment: 1 } },
    })
    await endAllSessions(tx, row.userId, now, 'password_reset')
    await recordEvent(tx, now, { type: 'user.password_reset', actorId: row.userId, userId: row.userId })
  })
}
