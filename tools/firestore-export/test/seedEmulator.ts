/**
 * Test-only: loads an export directory (e.g. the backend fixture) INTO the
 * Firestore and Auth emulators. Refuses to run unless both emulator hosts
 * are set and the project is a `demo-` project, which the Firebase SDKs and
 * CLI never connect to a real backend.
 */
import { readdir, readFile } from 'node:fs/promises'
import { join } from 'node:path'
import { deleteApp, initializeApp } from 'firebase-admin/app'
import { getAuth, type UserImportRecord } from 'firebase-admin/auth'
import { FieldValue, GeoPoint, getFirestore, Timestamp, type CollectionReference, type Firestore } from 'firebase-admin/firestore'

export function assertEmulator(projectId: string) {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error('Refusing to write: FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST must both be set.')
  }
  if (!projectId.startsWith('demo-')) throw new Error(`Refusing to write: ${projectId} is not a demo- (emulator-only) project.`)
}

function decode(v: unknown, db: Firestore): unknown {
  if (Array.isArray(v)) return v.map((x) => decode(x, db))
  if (v === null || typeof v !== 'object') return v
  const o = v as Record<string, unknown>
  switch (o.__type) {
    case undefined:
      return Object.fromEntries(Object.entries(o).map(([k, x]) => [k, decode(x, db)]))
    case 'timestamp': {
      const ms = o.ms as number
      const seconds = Math.floor(ms / 1000)
      return new Timestamp(seconds, (ms - seconds * 1000) * 1_000_000 + ((o.ns as number | undefined) ?? 0))
    }
    case 'geopoint':
      return new GeoPoint(o.lat as number, o.lng as number)
    case 'reference':
      return db.doc(o.path as string)
    case 'bytes':
      return Buffer.from(o.base64 as string, 'base64')
    case 'vector':
      return FieldValue.vector(o.values as number[])
    case 'int64':
      return BigInt(o.value as string)
    case 'double':
      return Number(o.value)
    case 'map':
      return Object.fromEntries(Object.entries(o.value as object).map(([k, x]) => [k, decode(x, db)]))
    default:
      throw new Error(`unknown __type ${String(o.__type)}`)
  }
}

export interface SeedResult {
  documents: number
  users: number
  /** Lines that are not valid JSON (deliberately corrupt fixture lines). */
  unreadable: number
}

export async function seedEmulator(dir: string, projectId: string): Promise<SeedResult> {
  assertEmulator(projectId)
  const app = initializeApp({ projectId }, 'jcb-e2e-seed')
  const db = getFirestore(app)
  const auth = getAuth(app)
  const result: SeedResult = { documents: 0, users: 0, unreadable: 0 }
  const users: UserImportRecord[] = []
  try {
    let batch = db.batch()
    let pending = 0
    for (const file of (await readdir(dir)).filter((f) => f.endsWith('.ndjson')).sort()) {
      for (const text of (await readFile(join(dir, file), 'utf8')).split('\n')) {
        if (!text.trim()) continue
        let line: { path: string; data: Record<string, unknown> }
        try {
          line = JSON.parse(text)
        } catch {
          result.unreadable++
          continue
        }
        if (line.path.startsWith('__auth__/')) {
          const d = line.data as { uid: string; email: string | null; emailVerified?: boolean; disabled?: boolean; createdAt?: { ms: number } | null; lastSignInAt?: { ms: number } | null }
          users.push({
            uid: d.uid,
            ...(d.email ? { email: d.email } : {}),
            emailVerified: !!d.emailVerified,
            disabled: !!d.disabled,
            metadata: {
              ...(d.createdAt ? { creationTime: new Date(d.createdAt.ms).toUTCString() } : {}),
              ...(d.lastSignInAt ? { lastSignInTime: new Date(d.lastSignInAt.ms).toUTCString() } : {}),
            },
          })
          continue
        }
        batch.set(db.doc(line.path), decode(line.data, db) as Record<string, unknown>)
        result.documents++
        if (++pending === 400) {
          await batch.commit()
          batch = db.batch()
          pending = 0
        }
      }
    }
    if (pending) await batch.commit()
    for (let i = 0; i < users.length; i += 1000) {
      const r = await auth.importUsers(users.slice(i, i + 1000))
      if (r.failureCount) throw new Error(`importUsers failed: ${JSON.stringify(r.errors.map((e) => e.error.message))}`)
    }
    result.users = users.length
    return result
  } finally {
    await deleteApp(app)
  }
}

/** Every document path with its update time (to prove the export wrote nothing). */
export async function snapshotUpdateTimes(projectId: string): Promise<Map<string, string>> {
  assertEmulator(projectId)
  const app = initializeApp({ projectId }, `jcb-e2e-snapshot-${Date.now()}`)
  const db = getFirestore(app)
  const out = new Map<string, string>()
  const walk = async (collections: CollectionReference[]) => {
    for (const c of collections) {
      for (const ref of await c.listDocuments()) {
        const snap = await ref.get()
        if (snap.exists) out.set(ref.path, snap.updateTime!.toDate().toISOString() + snap.updateTime!.nanoseconds)
        await walk(await ref.listCollections())
      }
    }
  }
  try {
    await walk(await db.listCollections())
    return out
  } finally {
    await deleteApp(app)
  }
}
