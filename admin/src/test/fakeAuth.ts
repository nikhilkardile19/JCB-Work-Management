import type { AdminUser, AuthService } from '../lib/authContext'
import { NOT_ADMIN_MESSAGE } from '../lib/firebaseAuthService'

/** In-memory auth with an admin allowlist, mirroring the Firebase service. */
export class FakeAuthService implements AuthService {
  private listeners = new Set<(u: AdminUser | null) => void>()
  resetEmail: string | null = null
  private current: AdminUser | null
  private admins = new Set(['admin@jcbworks.in'])
  constructor(current: AdminUser | null = null) {
    this.current = current
  }
  onChange(cb: (u: AdminUser | null) => void) {
    this.listeners.add(cb)
    queueMicrotask(() => cb(this.current))
    return () => this.listeners.delete(cb)
  }
  async signIn(email: string, password: string) {
    if (password === 'wrong-password') throw new Error('Incorrect email or password.')
    if (!this.admins.has(email)) throw new Error(NOT_ADMIN_MESSAGE)
    this.current = { uid: `uid-${email}`, email }
    return this.current
  }
  async sendPasswordReset(email: string) {
    this.resetEmail = email
  }
  async signOut() {
    this.current = null
    this.listeners.forEach((l) => l(null))
  }
}

