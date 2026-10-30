/**
 * End-to-end check, run inside `firebase emulators:exec` (see run-e2e.sh):
 *
 *   1. seed the Firestore + Auth emulators from backend/tests/fixtures/firestore-export
 *   2. export them with this tool, proving no emulator document changed
 *   3. compare the export with the fixture (lossless round trip)
 *   4. import into a scratch PostgreSQL database with `npm run import:firestore -- --fresh`
 *      and require reconciliation to pass, twice (the rerun must be a no-op)
 *   5. drop the scratch database
 *
 * Environment: E2E_DATABASE (default jcb_import_check) and PG* settings for
 * createdb/dropdb; E2E_DATABASE_URL overrides the connection string.
 */
import { spawnSync } from 'node:child_process'
import { mkdtemp, readdir, readFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { assertEmulator, seedEmulator, snapshotUpdateTimes } from './seedEmulator.ts'

const PROJECT = process.env.GCLOUD_PROJECT ?? 'demo-jcb-export'
const TOOL = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const BACKEND = resolve(TOOL, '../../backend')
const FIXTURE = join(BACKEND, 'tests/fixtures/firestore-export')
const DB = process.env.E2E_DATABASE ?? 'jcb_import_check'
const DB_URL = process.env.E2E_DATABASE_URL ?? `postgresql://${process.env.PGUSER ?? process.env.USER}@${process.env.PGHOST ?? 'localhost'}:${process.env.PGPORT ?? '5432'}/${DB}`

let failures = 0
const check = (ok: boolean, what: string) => {
  console.log(`${ok ? '  ok  ' : '  FAIL'}  ${what}`)
  if (!ok) failures++
}

function run(cmd: string, args: string[], cwd: string, env: NodeJS.ProcessEnv = process.env) {
  console.log(`\n$ ${cmd} ${args.join(' ')}`)
  const r = spawnSync(cmd, args, { cwd, env, stdio: 'inherit' })
  return r.status ?? 1
}

/** JSON with sorted keys, for order-insensitive comparison. */
const canonical = (v: unknown): string =>
  JSON.stringify(v, (_k, x) => (x && typeof x === 'object' && !Array.isArray(x) ? Object.fromEntries(Object.entries(x).sort(([a], [b]) => (a < b ? -1 : 1))) : x))

async function readLines(dir: string) {
  const docs = new Map<string, Record<string, unknown>>()
  for (const file of (await readdir(dir)).filter((f) => f.endsWith('.ndjson'))) {
    for (const text of (await readFile(join(dir, file), 'utf8')).split('\n')) {
      if (!text.trim()) continue
      try {
        const line = JSON.parse(text) as { path: string; data: Record<string, unknown> }
        docs.set(line.path, line.data)
      } catch {
        // the fixture's deliberately corrupt line
      }
    }
  }
  return docs
}

assertEmulator(PROJECT)
const work = await mkdtemp(join(tmpdir(), 'jcb-export-e2e-'))
const exportDir = join(work, 'export')
try {
  console.log(`Seeding emulator project ${PROJECT} from ${FIXTURE}`)
  const seeded = await seedEmulator(FIXTURE, PROJECT)
  console.log(`  ${seeded.documents} documents, ${seeded.users} Auth users, ${seeded.unreadable} unreadable fixture line(s) skipped`)

  const before = await snapshotUpdateTimes(PROJECT)
  const exported0 = run(process.execPath, ['src/export.ts', '--project', PROJECT, '--out', exportDir, '--page-size', '2'], TOOL) === 0
  check(exported0, 'export exits 0')
  if (!exported0) throw new Error('export failed')
  const after = await snapshotUpdateTimes(PROJECT)
  check(canonical([...before]) === canonical([...after]) && before.size === seeded.documents, `export changed no emulator document (${before.size} documents, same update times)`)

  // Lossless round trip: every readable fixture document comes back identical.
  const fixture = await readLines(FIXTURE)
  const exported = await readLines(exportDir)
  const manifest = JSON.parse(await readFile(join(exportDir, 'manifest.json'), 'utf8')) as { counts: Record<string, number>; projectId: string }
  check(manifest.projectId === PROJECT, 'manifest names the project')
  check(Object.values(manifest.counts).reduce((a, b) => a + b, 0) === exported.size, `manifest counts match the files (${exported.size} lines)`)
  check(exported.size === fixture.size, `export has the same documents as the fixture (${exported.size} vs ${fixture.size})`)
  let same = 0
  for (const [path, data] of fixture) {
    const got = exported.get(path)
    if (!got) {
      check(false, `missing from export: ${path}`)
      continue
    }
    const pick = (d: Record<string, unknown>) => (path.startsWith('__auth__/') ? { uid: d.uid, email: d.email, disabled: d.disabled, createdAt: d.createdAt, lastSignInAt: d.lastSignInAt } : d)
    if (canonical(pick(got)) === canonical(pick(data))) same++
    else check(false, `differs after round trip: ${path}\n    fixture ${canonical(pick(data))}\n    export  ${canonical(pick(got))}`)
  }
  check(same === fixture.size, `${same}/${fixture.size} documents identical after seed → export (timestamps to the nanosecond)`)

  // Import into a scratch database.
  run('dropdb', ['--if-exists', DB], BACKEND)
  check(run('createdb', [DB], BACKEND) === 0, `createdb ${DB}`)
  const env = { ...process.env, DATABASE_URL: DB_URL }
  check(run('npx', ['prisma', 'migrate', 'deploy'], BACKEND, env) === 0, 'migrations applied')
  const reportDir = join(work, 'report')
  check(run('npm', ['run', '--silent', 'import:firestore', '--', exportDir, '--dry-run', '--quiet', '--report-dir', join(work, 'dry-run')], BACKEND, env) === 0, 'dry run reconciles (exit 0)')
  check(run('npm', ['run', '--silent', 'import:firestore', '--', exportDir, '--fresh', '--quiet', '--report-dir', reportDir], BACKEND, env) === 0, 'import --fresh reconciles (exit 0)')
  const report = JSON.parse(await readFile(join(reportDir, 'migration-report.json'), 'utf8')) as {
    reconciliation: { ok: boolean }
    tables: { table: string; expected: number; database: number }[]
    problemCounts: Record<string, number>
  }
  check(report.reconciliation.ok, 'report: reconciliation ok')
  const rows = Object.fromEntries(report.tables.map((t) => [t.table, t.database]))
  check(rows.users === 10 && rows.work_logs === 5 && rows.invoice_lines === 4 && rows.audit_events === 7, `rows: users ${rows.users}, work_logs ${rows.work_logs}, invoice_lines ${rows.invoice_lines}, audit_events ${rows.audit_events}`)
  for (const code of ['error:invalid', 'error:orphan', 'error:duplicate', 'error:company_missing', 'warning:user_from_membership', 'warning:unmapped_collection', 'info:skipped_collection']) {
    check((report.problemCounts[code] ?? 0) === 1, `report: ${code} reported`)
  }
  check(run('npm', ['run', '--silent', 'import:firestore', '--', exportDir, '--quiet', '--report-dir', join(work, 'rerun')], BACKEND, env) === 0, 'rerun (upsert) reconciles (exit 0)')
  const counts = spawnSync('psql', ['-At', DB, '-c', 'SELECT (SELECT count(*) FROM users) || \'/\' || (SELECT count(*) FROM work_logs) || \'/\' || (SELECT seq FROM company_sync_state ORDER BY seq DESC LIMIT 1)'], { encoding: 'utf8' })
  check(counts.stdout.trim() === '10/5/23', `after rerun: users/work_logs/max sync seq = ${counts.stdout.trim()} (expected 10/5/23)`)
} finally {
  run('dropdb', ['--if-exists', DB], BACKEND)
  await rm(work, { recursive: true, force: true })
}

console.log(failures ? `\nE2E FAILED: ${failures} check(s)` : '\nE2E PASSED')
process.exit(failures ? 1 : 0)
