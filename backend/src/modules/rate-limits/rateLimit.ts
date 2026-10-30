import type { Db, Tx } from '../../database/prisma.js'
import { ApiError } from '../../lib/errors.js'
import { HOUR_MS } from '../../lib/time.js'

/**
 * Fixed-window counters in `rate_limits` (ported from the Cloud Functions'
 * `rateLimits/{key}`). A single upsert counts atomically, so concurrent
 * requests on several API instances share the same limit.
 */
export interface Limit {
  max: number
  windowMs: number
  message: string
}

export const LIMITS = {
  /** Wrong activation codes, per user (activation and replacement requests). */
  codeFailures: { max: 10, windowMs: HOUR_MS, message: 'Too many wrong activation codes. Wait an hour and try again.' },
  /** Replacement requests, per user. */
  replacementRequests: { max: 5, windowMs: 24 * HOUR_MS, message: 'Too many replacement requests today. Contact support.' },
  /** Users added, per company (each may create a sign-in account). */
  invites: { max: 30, windowMs: 24 * HOUR_MS, message: 'Too many users added today. Try again tomorrow or contact support.' },
  /** Failed sign-ins, per email address. */
  loginFailuresPerEmail: { max: 10, windowMs: HOUR_MS / 4, message: 'Too many attempts. Wait a few minutes and try again.' },
  /** Failed sign-ins, per client IP. */
  loginFailuresPerIp: { max: 50, windowMs: HOUR_MS / 4, message: 'Too many attempts. Wait a few minutes and try again.' },
  /** Reset requests per client IP (stops mailing many addresses from one source). */
  resetRequestsPerIp: { max: 20, windowMs: HOUR_MS, message: 'Too many reset requests. Try again later.' },
  /** Password reset emails, per address (extra requests are silently ignored). */
  resetEmails: { max: 3, windowMs: HOUR_MS, message: 'Too many reset requests.' },
} satisfies Record<string, Limit>

function refused(limit: Limit, retryAfterMs: number) {
  return new ApiError('resource_exhausted', limit.message, { reason: 'rate_limited', retryAfterMs: Math.max(0, retryAfterMs) })
}

/** Throws if [key] has used up [limit], without counting this call. */
export async function assertWithinLimit(db: Db | Tx, key: string, limit: Limit, now: Date) {
  const row = await db.rateLimit.findUnique({ where: { key } })
  if (!row) return
  const elapsed = now.getTime() - row.windowStart.getTime()
  if (elapsed < limit.windowMs && row.count >= limit.max) throw refused(limit, limit.windowMs - elapsed)
}

/** Counts one use of [key] and returns false once the limit is exceeded. */
export async function tryConsume(db: Db | Tx, key: string, limit: Limit, now: Date): Promise<{ ok: boolean; retryAfterMs: number }> {
  const windowStartCutoff = new Date(now.getTime() - limit.windowMs)
  const rows = await db.$queryRaw<{ window_start: Date; count: number }[]>`
    INSERT INTO rate_limits (key, window_start, count, expires_at)
    VALUES (${key}, ${now}, 1, ${new Date(now.getTime() + limit.windowMs)})
    ON CONFLICT (key) DO UPDATE SET
      window_start = CASE WHEN rate_limits.window_start <= ${windowStartCutoff} THEN ${now} ELSE rate_limits.window_start END,
      count        = CASE WHEN rate_limits.window_start <= ${windowStartCutoff} THEN 1 ELSE rate_limits.count + 1 END,
      expires_at   = CASE WHEN rate_limits.window_start <= ${windowStartCutoff}
                          THEN ${new Date(now.getTime() + limit.windowMs)} ELSE rate_limits.expires_at END
    RETURNING window_start, count`
  const { window_start, count } = rows[0]
  return { ok: count <= limit.max, retryAfterMs: window_start.getTime() + limit.windowMs - now.getTime() }
}

/** Counts one use of [key]; throws `resource_exhausted` once the limit is exceeded. */
export async function consume(db: Db | Tx, key: string, limit: Limit, now: Date) {
  const r = await tryConsume(db, key, limit, now)
  if (!r.ok) throw refused(limit, r.retryAfterMs)
}

/** Deletes expired counters (run from a scheduler, e.g. daily). */
export async function purgeExpired(db: Db, now: Date) {
  return (await db.rateLimit.deleteMany({ where: { expiresAt: { lt: now } } })).count
}
