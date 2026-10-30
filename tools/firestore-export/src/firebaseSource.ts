import { applicationDefault, deleteApp, initializeApp, SDK_VERSION } from 'firebase-admin/app'
import { getAuth } from 'firebase-admin/auth'
import { FieldPath, getFirestore } from 'firebase-admin/firestore'

/**
 * The only module that talks to Firebase, and it only reads. The exporter
 * receives this narrow interface, never the Firestore or Auth objects, so
 * it cannot write by construction. `npm run check:readonly` fails if a
 * write API appears in this file (or Firebase is imported anywhere else).
 */
export interface RawDoc {
  path: string
  id: string
  data: Record<string, unknown>
}

export interface AuthUserRow {
  uid: string
  email: string | null
  emailVerified: boolean
  disabled: boolean
  createdAt: number | null
  lastSignInAt: number | null
  providerIds: string[]
}

export interface ReadOnlySource {
  readonly projectId: string
  /** Paths of the top-level collections. */
  rootCollections(): Promise<string[]>
  /** Document paths of a collection, including "missing" documents that only have subcollections. */
  documentPaths(collectionPath: string): Promise<string[]>
  /** Paths of a document's subcollections. */
  subcollections(documentPath: string): Promise<string[]>
  /** Up to [limit] documents after [afterId], in document-ID order. */
  page(collectionPath: string, afterId: string | null, limit: number): Promise<RawDoc[]>
  /** One page of Firebase Auth users (1000 per page). */
  authUsers(pageToken?: string): Promise<{ users: AuthUserRow[]; next?: string }>
  close(): Promise<void>
}

/** firebase-admin version, recorded in manifest.json. */
export const FIREBASE_ADMIN_VERSION = SDK_VERSION

const time = (s: string | null | undefined) => {
  const ms = s ? Date.parse(s) : NaN
  return Number.isNaN(ms) ? null : ms
}

export function openSource(projectId: string, emulator: boolean): ReadOnlySource {
  // Real project: Application Default Credentials (GOOGLE_APPLICATION_CREDENTIALS).
  // Emulator: no credentials; the SDK routes to the *_EMULATOR_HOST variables.
  const app = initializeApp({ projectId, ...(emulator ? {} : { credential: applicationDefault() }) }, 'jcb-firestore-export')
  const db = getFirestore(app)
  db.settings({ useBigInt: true })
  const auth = getAuth(app)

  return {
    projectId,
    rootCollections: async () => (await db.listCollections()).map((c) => c.path),
    documentPaths: async (collectionPath) => (await db.collection(collectionPath).listDocuments()).map((d) => d.path),
    subcollections: async (documentPath) => (await db.doc(documentPath).listCollections()).map((c) => c.path),
    async page(collectionPath, afterId, limit) {
      let query = db.collection(collectionPath).orderBy(FieldPath.documentId()).limit(limit)
      if (afterId !== null) query = query.startAfter(afterId)
      const snap = await query.get()
      return snap.docs.map((d) => ({ path: d.ref.path, id: d.id, data: d.data() }))
    },
    async authUsers(pageToken) {
      const res = await auth.listUsers(1000, pageToken)
      return {
        users: res.users.map((u) => ({
          uid: u.uid,
          email: u.email ?? null,
          emailVerified: u.emailVerified,
          disabled: u.disabled,
          createdAt: time(u.metadata.creationTime),
          lastSignInAt: time(u.metadata.lastSignInTime),
          providerIds: u.providerData.map((p) => p.providerId),
        })),
        next: res.pageToken,
      }
    },
    close: () => deleteApp(app),
  }
}
