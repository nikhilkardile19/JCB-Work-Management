import { errors, jwtVerify, SignJWT } from 'jose'
import type { AppContext } from '../../context.js'
import { unauthenticated } from '../../lib/errors.js'

export interface AuthUser {
  id: string
  email: string
}

const secretKeys = new WeakMap<object, Uint8Array>()

function key(ctx: AppContext): Uint8Array {
  let k = secretKeys.get(ctx.config)
  if (!k) {
    k = new TextEncoder().encode(ctx.config.JWT_ACCESS_SECRET)
    secretKeys.set(ctx.config, k)
  }
  return k
}

/**
 * Short-lived JWT. It carries only the user ID and the user's token version:
 * roles, memberships and company status are read from the database on every
 * request, so a disabled member or suspended company loses access at once.
 */
export async function signAccessToken(ctx: AppContext, user: { id: string; tokenVersion: number }) {
  const now = ctx.clock().getTime()
  const expiresAt = now + ctx.config.ACCESS_TOKEN_TTL_SECONDS * 1000
  const token = await new SignJWT({ ver: user.tokenVersion })
    .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
    .setSubject(user.id)
    .setIssuer(ctx.config.JWT_ISSUER)
    .setAudience(ctx.config.JWT_AUDIENCE)
    .setIssuedAt(Math.floor(now / 1000))
    .setExpirationTime(Math.floor(expiresAt / 1000))
    .sign(key(ctx))
  return { token, expiresAt }
}

/** Verifies `Authorization: Bearer …` and returns the active user. */
export async function authenticate(ctx: AppContext, header: string | undefined): Promise<AuthUser> {
  const match = /^Bearer (\S+)$/.exec(header ?? '')
  if (!match) throw unauthenticated('Sign in first.', 'missing_token')
  let sub: string
  let ver: unknown
  try {
    const { payload } = await jwtVerify(match[1], key(ctx), {
      issuer: ctx.config.JWT_ISSUER,
      audience: ctx.config.JWT_AUDIENCE,
      algorithms: ['HS256'],
      currentDate: ctx.clock(),
    })
    sub = payload.sub ?? ''
    ver = payload.ver
  } catch (e) {
    if (e instanceof errors.JWTExpired) throw unauthenticated('Your session has expired.', 'token_expired')
    throw unauthenticated('Sign in first.', 'invalid_token')
  }
  const user = await ctx.db.user.findUnique({
    where: { id: sub },
    select: { id: true, email: true, status: true, tokenVersion: true },
  })
  if (!user || user.status !== 'active' || user.tokenVersion !== ver) {
    throw unauthenticated('Your session is no longer valid. Sign in again.', 'invalid_token')
  }
  return { id: user.id, email: user.email }
}
