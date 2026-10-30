import { createContext, useContext } from 'react'

export interface AdminUser {
  uid: string
  email: string
}

export const NOT_CONFIGURED_MESSAGE = 'Admin sign-in is not configured. Set VITE_API_BASE_URL in admin/.env.local (see .env.example).'

/** Why a password reset failed, so the page can show the right state. */
export type PasswordResetFailure = 'invalid_link' | 'invalid_password' | 'other'

export class PasswordResetError extends Error {
  readonly kind: PasswordResetFailure
  constructor(kind: PasswordResetFailure, message: string) {
    super(message)
    this.name = 'PasswordResetError'
    this.kind = kind
  }
}

/** Identity backend. The REST API in the app, a fake in tests. */
export interface AuthService {
  /** Calls back with the signed-in developer admin, or null. Returns unsubscribe. */
  onChange(cb: (user: AdminUser | null) => void): () => void
  /** Signs in and verifies the developer-admin allowlist; throws with a user-facing message. */
  signIn(email: string, password: string): Promise<AdminUser>
  /** Never reveals whether an account exists for [email]. */
  sendPasswordReset(email: string): Promise<void>
  /** Sets a new password from an emailed reset link; throws PasswordResetError. */
  resetPassword(token: string, password: string): Promise<void>
  signOut(): Promise<void>
}

export interface AuthContextValue {
  user: AdminUser | null
  /** True until the first auth state is known. */
  initializing: boolean
  /** False when this build has no API base URL. */
  configured: boolean
  signIn: (email: string, password: string) => Promise<void>
  sendPasswordReset: (email: string) => Promise<void>
  resetPassword: (token: string, password: string) => Promise<void>
  signOut: () => Promise<void>
}

export const AuthContext = createContext<AuthContextValue | null>(null)

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>')
  return ctx
}
