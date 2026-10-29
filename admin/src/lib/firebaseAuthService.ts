import { initializeApp, type FirebaseApp } from 'firebase/app'
import { createFirebaseAdminApi } from './firebaseAdminApi'
import type { AdminApi } from './adminApi'
import {
  getAuth,
  onAuthStateChanged,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signOut,
  type User,
} from 'firebase/auth'
import { doc, getDoc, getFirestore } from 'firebase/firestore'
import type { AdminUser, AuthService } from './authContext'

const env = import.meta.env

export const NOT_ADMIN_MESSAGE = 'This account is not an authorized developer administrator.'

export function messageForAuthError(code: string): string {
  switch (code) {
    case 'auth/invalid-email':
      return 'That email address is not valid.'
    case 'auth/user-not-found':
    case 'auth/wrong-password':
    case 'auth/invalid-credential':
      return 'Incorrect email or password.'
    case 'auth/user-disabled':
      return 'This account has been disabled.'
    case 'auth/too-many-requests':
      return 'Too many attempts. Wait a few minutes and try again.'
    case 'auth/network-request-failed':
      return 'No internet connection. Connect and try again.'
    default:
      return 'Sign-in failed. Please try again.'
  }
}

/**
 * Firebase Auth + developer-admin allowlist (`developerAdmins/{uid}`, created
 * only from the Firebase console). Non-admins are signed straight back out.
 */
export function createFirebaseAuthService(app: FirebaseApp): AuthService {
  const auth = getAuth(app)
  const db = getFirestore(app)

  async function asAdmin(u: User): Promise<AdminUser | null> {
    try {
      const snap = await getDoc(doc(db, 'developerAdmins', u.uid))
      return snap.exists() ? { uid: u.uid, email: u.email ?? '' } : null
    } catch {
      return null
    }
  }

  const codeOf = (e: unknown) => (e as { code?: string })?.code ?? ''

  return {
    onChange(cb) {
      return onAuthStateChanged(auth, async (u) => {
        if (!u) return cb(null)
        const admin = await asAdmin(u)
        if (!admin) await signOut(auth)
        cb(admin)
      })
    },
    async signIn(email, password) {
      let user: User
      try {
        user = (await signInWithEmailAndPassword(auth, email.trim(), password)).user
      } catch (e) {
        throw new Error(messageForAuthError(codeOf(e)))
      }
      const admin = await asAdmin(user)
      if (!admin) {
        await signOut(auth)
        throw new Error(NOT_ADMIN_MESSAGE)
      }
      return admin
    },
    async sendPasswordReset(email) {
      try {
        await sendPasswordResetEmail(auth, email.trim())
      } catch (e) {
        if (codeOf(e) === 'auth/user-not-found') return
        throw new Error(messageForAuthError(codeOf(e)))
      }
    },
    signOut: () => signOut(auth),
  }
}

/** One Firebase app for both sign-in and the admin API. */
export function createFirebaseServices(): { auth: AuthService; api: AdminApi } {
  const app = initializeApp({
    apiKey: env.VITE_FIREBASE_API_KEY,
    authDomain: env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: env.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: env.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: env.VITE_FIREBASE_APP_ID,
  })
  return { auth: createFirebaseAuthService(app), api: createFirebaseAdminApi(app, getAuth(app)) }
}
