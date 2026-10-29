import { createContext, useContext } from 'react'

export interface AdminUser {
  uid: string
  email: string
}

/** Identity backend. Firebase in the app, a fake in tests. */
export interface AuthService {
  /** Calls back with the signed-in developer admin, or null. Returns unsubscribe. */
  onChange(cb: (user: AdminUser | null) => void): () => void
  /** Signs in and verifies the developer-admin allowlist; throws with a user-facing message. */
  signIn(email: string, password: string): Promise<AdminUser>
  sendPasswordReset(email: string): Promise<void>
  signOut(): Promise<void>
}

export interface AuthContextValue {
  user: AdminUser | null
  /** True until the first auth state is known. */
  initializing: boolean
  /** False when Firebase is not configured for this build. */
  configured: boolean
  signIn: (email: string, password: string) => Promise<void>
  sendPasswordReset: (email: string) => Promise<void>
  signOut: () => Promise<void>
}

export const AuthContext = createContext<AuthContextValue | null>(null)

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>')
  return ctx
}
