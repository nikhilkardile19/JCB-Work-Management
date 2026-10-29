import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

/**
 * Fixed-window counters in `rateLimits/{key}` (no client access; rules
 * default-deny). `expiresAt` lets a Firestore TTL policy clean them up.
 *
 * Activation codes have 60 bits of entropy, so guessing is already
 * impractical; the limits stop scripted abuse and keep costs bounded.
 */
export interface Limit {
  max: number;
  windowMs: number;
  message: string;
}

const HOUR = 3_600_000;

export const LIMITS = {
  /** Wrong activation codes, per user (activation and replacement requests). */
  codeFailures: { max: 10, windowMs: HOUR, message: 'Too many wrong activation codes. Wait an hour and try again.' },
  /** Replacement requests, per user. */
  replacementRequests: { max: 5, windowMs: 24 * HOUR, message: 'Too many replacement requests today. Contact support.' },
  /** Users added, per company (each may create a sign-in account). */
  invites: { max: 30, windowMs: 24 * HOUR, message: 'Too many users added today. Try again tomorrow or contact support.' },
} satisfies Record<string, Limit>;

function refused(limit: Limit, retryAfterMs: number): HttpsError {
  return new HttpsError('resource-exhausted', limit.message, { reason: 'rate_limited', retryAfterMs });
}

/** Throws if [key] has used up [limit], without counting this call. */
export async function assertWithinLimit(db: Firestore, key: string, limit: Limit, now = Date.now()) {
  const snap = await db.doc(`rateLimits/${key}`).get();
  const start = snap.get('windowStart') as number | undefined;
  if (start !== undefined && now - start < limit.windowMs && (snap.get('count') as number) >= limit.max) {
    throw refused(limit, start + limit.windowMs - now);
  }
}

/** Counts one use of [key]; throws once the limit is exceeded. */
export async function consume(db: Firestore, key: string, limit: Limit, now = Date.now()) {
  const ref = db.doc(`rateLimits/${key}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const start = snap.get('windowStart') as number | undefined;
    const fresh = start === undefined || now - start >= limit.windowMs;
    const count = fresh ? 0 : (snap.get('count') as number);
    if (count >= limit.max) throw refused(limit, start! + limit.windowMs - now);
    const windowStart = fresh ? now : start!;
    tx.set(ref, { windowStart, count: count + 1, expiresAt: Timestamp.fromMillis(windowStart + limit.windowMs) });
  });
}
