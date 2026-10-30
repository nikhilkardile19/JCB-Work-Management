import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router'
import { AuthContext, NOT_CONFIGURED_MESSAGE, useAuth, type AdminUser, type AuthService } from './authContext'

const notConfigured = new Error(NOT_CONFIGURED_MESSAGE)

export function AuthProvider({ service, children }: { service: AuthService | null; children: ReactNode }) {
  const [user, setUser] = useState<AdminUser | null>(null)
  const [initializing, setInitializing] = useState(service !== null)

  useEffect(() => {
    if (!service) return
    return service.onChange((u) => {
      setUser(u)
      setInitializing(false)
    })
  }, [service])

  const signIn = useCallback(
    async (email: string, password: string) => {
      if (!service) throw notConfigured
      setUser(await service.signIn(email, password))
    },
    [service],
  )

  const sendPasswordReset = useCallback(
    async (email: string) => {
      if (!service) throw notConfigured
      await service.sendPasswordReset(email)
    },
    [service],
  )

  const resetPassword = useCallback(
    async (token: string, password: string) => {
      if (!service) throw notConfigured
      await service.resetPassword(token, password)
    },
    [service],
  )

  const signOut = useCallback(async () => {
    await service?.signOut()
    setUser(null)
  }, [service])

  const value = useMemo(
    () => ({ user, initializing, configured: service !== null, signIn, sendPasswordReset, resetPassword, signOut }),
    [user, initializing, service, signIn, sendPasswordReset, resetPassword, signOut],
  )
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

/** Redirects to /login (remembering the target) when signed out. */
export function RequireAuth({ children }: { children: ReactNode }) {
  const { user, initializing } = useAuth()
  const location = useLocation()
  if (initializing) {
    return (
      <div className="boot" role="status" aria-live="polite">
        <span className="spinner" aria-hidden />
        <span>Checking your session…</span>
      </div>
    )
  }
  if (!user) return <Navigate to="/login" replace state={{ from: location.pathname }} />
  return children
}
