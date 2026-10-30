/**
 * Read-only Firestore + Firebase Auth export (migration Phase F). Writes a
 * backup directory that `npm run import:firestore` in backend/ loads into
 * PostgreSQL. See README.md for the exact commands.
 *
 *   node src/export.ts --project <id> --out <new-dir> [--page-size 500] [--deep] [--skip-auth]
 *
 * Real project: GOOGLE_APPLICATION_CREDENTIALS=<read-only service account key>.
 * Emulator: FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST (both).
 */
import { createHash, type Hash } from 'node:crypto'
import { createWriteStream, type WriteStream } from 'node:fs'
import { mkdir, readdir, writeFile } from 'node:fs/promises'
import { join, resolve } from 'node:path'
import { once } from 'node:events'
import { parseArgs } from 'node:util'
import { AUTH_KIND, encodeMillis, encodeValue, fileOf, kindOf } from './codec.ts'
import { FIREBASE_ADMIN_VERSION, openSource, type ReadOnlySource } from './firebaseSource.ts'

/** Top-level collections whose documents are searched for subcollections (all with --deep). */
const DISCOVER_UNDER = new Set(['companies', 'developerAdmins'])

interface KindFile {
  kind: string
  file: string
  stream: WriteStream
  hash: Hash
  count: number
}

/** One NDJSON file per kind, created on first use; never overwrites. */
class Backup {
  private readonly kinds = new Map<string, KindFile>()
  private readonly names = new Set<string>()
  private readonly dir: string

  constructor(dir: string) {
    this.dir = dir
  }

  async write(kind: string, line: { path: string; id: string; data: unknown }) {
    let f = this.kinds.get(kind)
    if (!f) {
      let file = fileOf(kind)
      for (let i = 2; this.names.has(file); i++) file = fileOf(kind).replace(/\.ndjson$/, `~${i}.ndjson`)
      this.names.add(file)
      f = { kind, file, stream: createWriteStream(join(this.dir, file), { flags: 'wx' }), hash: createHash('sha256'), count: 0 }
      this.kinds.set(kind, f)
    }
    const text = `${JSON.stringify(line)}\n`
    f.hash.update(text)
    f.count++
    if (!f.stream.write(text)) await once(f.stream, 'drain')
  }

  async close() {
    const files: Record<string, { file: string; count: number; sha256: string }> = {}
    const counts: Record<string, number> = {}
    for (const f of [...this.kinds.values()].sort((a, b) => (a.kind < b.kind ? -1 : 1))) {
      f.stream.end()
      await once(f.stream, 'finish')
      files[f.kind] = { file: f.file, count: f.count, sha256: f.hash.digest('hex') }
      counts[f.kind] = f.count
    }
    return { files, counts }
  }
}

async function exportCollection(src: ReadOnlySource, out: Backup, path: string, pageSize: number, discover: boolean, deep: boolean, log: (m: string) => void) {
  let after: string | null = null
  let n = 0
  for (;;) {
    const docs = await src.page(path, after, pageSize)
    for (const d of docs) {
      let data: unknown
      try {
        data = encodeValue(d.data)
      } catch (e) {
        throw new Error(`${d.path}: ${(e as Error).message}`)
      }
      await out.write(kindOf(d.path), { path: d.path, id: d.id, data })
    }
    n += docs.length
    if (docs.length < pageSize) break
    after = docs[docs.length - 1].id
  }
  log(`${path}: ${n}`)
  if (!discover) return
  for (const doc of await src.documentPaths(path)) {
    for (const sub of await src.subcollections(doc)) await exportCollection(src, out, sub, pageSize, deep, deep, log)
  }
}

async function exportAuth(src: ReadOnlySource, out: Backup, log: (m: string) => void) {
  let token: string | undefined
  let n = 0
  do {
    const page = await src.authUsers(token)
    for (const u of page.users) {
      const ts = (ms: number | null) => (ms === null ? null : encodeMillis(ms))
      await out.write(AUTH_KIND, {
        path: `${AUTH_KIND}/${u.uid}`,
        id: u.uid,
        data: { uid: u.uid, email: u.email, emailVerified: u.emailVerified, disabled: u.disabled, createdAt: ts(u.createdAt), lastSignInAt: ts(u.lastSignInAt), providerIds: u.providerIds },
      })
      n++
    }
    token = page.next
  } while (token)
  log(`Firebase Auth users: ${n}`)
}

function fail(message: string): never {
  console.error(message)
  process.exit(2)
}

async function main() {
  const { values } = parseArgs({
    options: {
      project: { type: 'string' },
      out: { type: 'string' },
      'page-size': { type: 'string', default: '500' },
      deep: { type: 'boolean', default: false },
      'skip-auth': { type: 'boolean', default: false },
      quiet: { type: 'boolean', default: false },
    },
  })
  const project = values.project
  const pageSize = Number(values['page-size'])
  if (!project || !values.out || !(pageSize >= 1 && pageSize <= 10_000)) {
    fail('Usage: node src/export.ts --project <id> --out <new-dir> [--page-size 500] [--deep] [--skip-auth] [--quiet]')
  }
  const firestoreEmu = process.env.FIRESTORE_EMULATOR_HOST ?? null
  const authEmu = process.env.FIREBASE_AUTH_EMULATOR_HOST ?? null
  if (!!firestoreEmu !== !!authEmu) {
    fail('Set both FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST (emulator) or neither (real project); never mix the two.')
  }
  const emulator = !!firestoreEmu
  if (!emulator && project.startsWith('demo-')) fail(`${project} is a demo project: it only exists in the emulator. Set the *_EMULATOR_HOST variables.`)

  const out = resolve(values.out)
  await mkdir(out, { recursive: true })
  if ((await readdir(out)).length) fail(`${out} is not empty; give a new directory (backups are never overwritten).`)

  const log = values.quiet ? () => {} : (m: string) => console.error(`  ${m}`)
  console.error(`Exporting ${emulator ? `emulator (Firestore ${firestoreEmu}, Auth ${authEmu})` : 'REAL project (read-only)'} ${project} → ${out}`)

  const startedAt = new Date()
  const src = openSource(project, emulator)
  const backup = new Backup(out)
  try {
    for (const root of (await src.rootCollections()).sort()) {
      await exportCollection(src, backup, root, pageSize, values.deep || DISCOVER_UNDER.has(root), values.deep, log)
    }
    if (!values['skip-auth']) await exportAuth(src, backup, log)
  } finally {
    await src.close()
  }
  const { files, counts } = await backup.close()
  const manifest = {
    format: 'jcb-firestore-export',
    formatVersion: 1,
    projectId: project,
    emulator: { firestore: firestoreEmu, auth: authEmu },
    startedAt: startedAt.toISOString(),
    exportedAt: new Date().toISOString(),
    tool: { name: 'jcb-firestore-export', version: '1.0.0', firebaseAdmin: FIREBASE_ADMIN_VERSION },
    options: { pageSize, deep: values.deep, skipAuth: values['skip-auth'] },
    counts,
    files,
  }
  // Written last: an export without manifest.json is incomplete.
  await writeFile(join(out, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`, { flag: 'wx' })
  console.error(`Done: ${Object.values(counts).reduce((a, b) => a + b, 0)} documents in ${Object.keys(files).length} files.`)
  for (const [kind, n] of Object.entries(counts)) console.log(`${String(n).padStart(8)}  ${kind}`)
}

await main()
