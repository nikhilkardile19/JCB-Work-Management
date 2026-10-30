import type { AppContext } from '../../context.js'
import type { Tx } from '../../database/prisma.js'
import type { SessionClient } from '../../generated/prisma/client.js'
import { unauthenticated } from '../../lib/errors.js'
import { newId, randomToken, sha256 } from '../../lib/ids.js'
import { DAY_MS, HOUR_MS } from '../../lib/time.js'
import { recordEvent } from '../audit/auditEvents.js'
import { signAccessToken } from './tokens.js'

export interface Session {
  accessToken: string
  accessTokenExpiresAt: number
  refreshToken: string
  refreshTokenExpiresAt: number
  user: { id: string; email: string }
}

export interface ClientMeta {
  ip?: string
  userAgent?: string
}

const invalidRefresh = () => unauthenticated('Your session has ended. Sign in again.', 'invalid_refresh_token')

function refreshExpiry(ctx: AppContext, client: SessionClient, now: Date, familyExpiry?: Date): Date {
  if (client === 'mobile') {
    // Sliding: a phone that keeps refreshing stays signed in (offline-first).
    return new Date(now.getTime() + ctx.config.REFRESH_TOKEN_TTL_DAYS_MOBILE * DAY_MS)
  }
  // Portal: absolute lifetime from sign-in.
  return familyExpiry ?? new Date(now.getTime() + ctx.config.REFRESH_TOKEN_TTL_HOURS_PORTAL * HOUR_MS)
}

async function issue(
  ctx: AppContext,
  tx: Tx,
  user: { id: string; email: string; tokenVersion: number },
  client: SessionClient,
  familyId: string,
  expiresAt: Date,
  meta: ClientMeta,
): Promise<Session & { refreshTokenId: string }> {
  const refreshToken = randomToken()
  const id = newId()
  await tx.refreshToken.create({
    data: {
      id,
      userId: user.id,
      familyId,
      tokenHash: sha256(refreshToken),
      client,
      expiresAt,
      createdAt: ctx.clock(),
      userAgent: meta.userAgent?.slice(0, 300) ?? null,
      ip: meta.ip ?? null,
    },
  })
  const access = await signAccessToken(ctx, user)
  return {
    accessToken: access.token,
    accessTokenExpiresAt: access.expiresAt,
    refreshToken,
    refreshTokenExpiresAt: expiresAt.getTime(),
    user: { id: user.id, email: user.email },
    refreshTokenId: id,
  }
}

const strip = ({ refreshTokenId: _, ...session }: Session & { refreshTokenId: string }): Session => session

/** Starts a new session (token family) after a successful sign-in. */
export async function startSession(
  ctx: AppContext,
  user: { id: string; email: string; tokenVersion: number },
  client: SessionClient,
  meta: ClientMeta,
): Promise<Session> {
  const now = ctx.clock()
  return ctx.db.$transaction(async (tx) =>
    strip(await issue(ctx, tx, user, client, newId(), refreshExpiry(ctx, client, now), meta)),
  )
}

async function revokeFamily(tx: Tx, familyId: string, now: Date, reason: string) {
  await tx.refreshToken.updateMany({
    where: { familyId, revokedAt: null },
    data: { revokedAt: now, revokeReason: reason },
  })
}

/**
 * Exchanges a refresh token for a new pair (rotation). A token that was
 * already exchanged is a sign of theft and ends the whole session, unless it
 * comes back within the grace window while its replacement is still unused —
 * the phone simply never received the previous response.
 */
export async function refreshSession(ctx: AppContext, refreshToken: string, meta: ClientMeta): Promise<Session> {
  const now = ctx.clock()
  const outcome = await ctx.db.$transaction(async (tx) => {
    const found = await tx.refreshToken.findUnique({ where: { tokenHash: sha256(refreshToken) } })
    if (!found) return { error: invalidRefresh() }
    // Lock the row so two concurrent exchanges of one token are serialized.
    await tx.$queryRaw`SELECT id FROM refresh_tokens WHERE id = ${found.id} FOR UPDATE`
    const row = (await tx.refreshToken.findUnique({ where: { id: found.id } }))!
    const user = await tx.user.findUnique({ where: { id: row.userId } })
    if (row.revokedAt && row.revokeReason === 'superseded') {
      // Two holders forked the session through the grace window: end it.
      await revokeFamily(tx, row.familyId, now, 'reuse_detected')
      return { reuse: { userId: row.userId, familyId: row.familyId } }
    }
    if (row.revokedAt || row.expiresAt <= now) return { error: invalidRefresh() }
    if (!user || user.status !== 'active') {
      await revokeFamily(tx, row.familyId, now, 'user_disabled')
      return { error: invalidRefresh() }
    }

    if (row.rotatedAt) {
      const successor = row.replacedById ? await tx.refreshToken.findUnique({ where: { id: row.replacedById } }) : null
      const withinGrace = now.getTime() - row.rotatedAt.getTime() <= ctx.config.REFRESH_REUSE_GRACE_SECONDS * 1000
      const successorUnused = successor && !successor.rotatedAt && !successor.revokedAt
      if (!withinGrace || !successorUnused) {
        await revokeFamily(tx, row.familyId, now, 'reuse_detected')
        return { reuse: { userId: row.userId, familyId: row.familyId } }
      }
      await tx.refreshToken.update({
        where: { id: successor.id },
        data: { revokedAt: now, revokeReason: 'superseded' },
      })
    }

    const next = await issue(ctx, tx, user, row.client, row.familyId, refreshExpiry(ctx, row.client, now, row.expiresAt), meta)
    await tx.refreshToken.update({
      where: { id: row.id },
      data: { rotatedAt: row.rotatedAt ?? now, replacedById: next.refreshTokenId },
    })
    return { session: strip(next) }
  })
  if ('reuse' in outcome && outcome.reuse) {
    await recordEvent(ctx.db, now, { type: 'auth.refresh_reuse', actorId: outcome.reuse.userId, familyId: outcome.reuse.familyId })
    ctx.logger.warn({ userId: outcome.reuse.userId }, 'Refresh token reuse detected; session revoked')
    throw invalidRefresh()
  }
  if ('error' in outcome && outcome.error) throw outcome.error
  return outcome.session!
}

/** Ends the session the token belongs to (whatever its state). */
export async function endSession(ctx: AppContext, refreshToken: string) {
  const row = await ctx.db.refreshToken.findUnique({ where: { tokenHash: sha256(refreshToken) } })
  if (!row) return
  await ctx.db.$transaction((tx) => revokeFamily(tx, row.familyId, ctx.clock(), 'logout'))
}

/** Ends every session of a user (password reset, account disabled). */
export async function endAllSessions(tx: Tx, userId: string, now: Date, reason: string) {
  await tx.refreshToken.updateMany({ where: { userId, revokedAt: null }, data: { revokedAt: now, revokeReason: reason } })
}
