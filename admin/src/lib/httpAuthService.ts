import type { AdminProfile } from './adminApi'
import { ApiError, type ApiClient, type Session } from './apiClient'
import { PasswordResetError, type AdminUser, type AuthService } from './authContext'

export const NOT_ADMIN_MESSAGE = 'This account is not an authorized developer administrator.'

/** User-facing text for a failed auth request: an ApiError, or its `reason`/`code`. */
export function messageForAuthError(error: unknown, fallback = 'Sign-in failed. Please try again.'): string {
  const key =
    typeof error === 'string'
      ? error
      : error instanceof ApiError
        ? error.code === 'invalid_argument' && error.fields?.email
          ? 'invalid_email'
          : (error.reason ?? error.code)
        : ''
  switch (key) {
    case 'invalid_email':
      return 'That email address is not valid.'
    case 'invalid_credentials':
    case 'unauthenticated':
      return 'Incorrect email or password.'
    case 'user_disabled':
      return 'This account has been disabled.'
    case 'rate_limited':
    case 'resource_exhausted':
      return 'Too many attempts. Wait a few minutes and try again.'
    case 'network':
      return 'No internet connection. Connect and try again.'
    default:
      return fallback
  }
}

const isNotAdmin = (e: unknown) => e instanceof ApiError && e.status === 403 && e.reason !== 'user_disabled'

function resetError(e: unknown): PasswordResetError {
  if (!(e instanceof ApiError)) return new PasswordResetError('other', 'Could not change the password. Please try again.')
  if (e.status === 400 && e.fields?.password && !e.fields.token) return new PasswordResetError('invalid_password', e.fields.password)
  // Unknown, used and expired tokens all look the same.
  if ([400, 401, 404, 409, 410].includes(e.status)) return new PasswordResetError('invalid_link', 'This reset link is invalid or has expired.')
  return new PasswordResetError('other', e.status === 0 || e.status === 429 ? messageForAuthError(e) : e.message)
}

/**
 * Email/password sign-in against `/auth/*`, limited to developer admins:
 * `GET /admin/me` answers 403 for everyone else, who is signed straight back out.
 */
export function createHttpAuthService(client: ApiClient): AuthService {
  const listeners = new Set<(u: AdminUser | null) => void>()
  let current: AdminUser | null = null
  /** Bumped on every sign-in/out so a slow startup check can't overwrite it. */
  let version = 0
  let ready: Promise<void> | null = null

  function set(user: AdminUser | null) {
    current = user
    version++
    listeners.forEach((l) => l(user))
  }
  client.onSessionEnd(() => set(null))

  async function verifyAdmin(session: Session): Promise<AdminUser> {
    const p = await client.request<AdminProfile>('GET', '/admin/me')
    return { uid: p.uid, email: p.email ?? session.user.email }
  }

  /** Resumes this tab's session, if it left a refresh token. */
  async function restore(): Promise<AdminUser | null> {
    if (!client.hasSession()) return null
    try {
      return await verifyAdmin(await client.refresh())
    } catch (e) {
      // No longer an admin: end the session. Offline: keep the token so a reload can retry.
      if (e instanceof ApiError && e.status === 403) await client.logout()
      return null
    }
  }

  return {
    onChange(cb) {
      listeners.add(cb)
      if (!ready) {
        const started = version
        ready = restore()
          .catch(() => null)
          .then((u) => {
            if (started === version) current = u
          })
      }
      void ready.then(() => {
        if (listeners.has(cb)) cb(current)
      })
      return () => {
        listeners.delete(cb)
      }
    },

    async signIn(email, password) {
      let session: Session
      try {
        session = await client.request<Session>('POST', '/auth/login', { body: { email: email.trim(), password, client: 'portal' }, auth: false })
      } catch (e) {
        throw new Error(messageForAuthError(e))
      }
      client.setSession(session)
      let admin: AdminUser
      try {
        admin = await verifyAdmin(session)
      } catch (e) {
        await client.logout()
        throw new Error(isNotAdmin(e) ? NOT_ADMIN_MESSAGE : messageForAuthError(e))
      }
      set(admin)
      return admin
    },

    async sendPasswordReset(email) {
      try {
        await client.request('POST', '/auth/forgot-password', { body: { email: email.trim() }, auth: false })
      } catch (e) {
        // Never reveal whether an account exists.
        if (e instanceof ApiError && e.status === 404) return
        throw new Error(messageForAuthError(e, 'Could not send the reset email. Please try again.'))
      }
    },

    async resetPassword(token, password) {
      try {
        await client.request('POST', '/auth/reset-password', { body: { token, password }, auth: false })
      } catch (e) {
        throw resetError(e)
      }
    },

    async signOut() {
      const done = client.logout() // clears the local session synchronously
      set(null)
      await done
    },
  }
}
