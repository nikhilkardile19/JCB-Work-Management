/**
 * Firestore → PostgreSQL data migration (Phase F, docs/migration/README.md).
 * Loads a backup written by `tools/firestore-export` into DATABASE_URL. Has
 * no Firebase dependency: it only reads the export directory.
 *
 *   npm run import:firestore -- <export-dir> --dry-run   # validate + reconcile, then roll back
 *   npm run import:firestore -- <export-dir> --fresh     # the real import, into an empty database
 *   npm run import:firestore -- <export-dir>             # upsert again (rehearsals; idempotent)
 *
 * Options:
 *   --report-dir <dir>       where migration-report.json/.txt go (default: the export dir)
 *   --strict                 also exit 1 when any source record was rejected
 *   --timeout-minutes <n>    per-company transaction timeout (dry run: whole run), default 10
 *   --quiet                  no progress lines
 *
 * Exit code: 0 reconciled; 1 reconciliation failed (or --strict with
 * rejected records); 2 could not run (bad arguments, unreadable export,
 * --fresh on a non-empty database, database unreachable).
 */
import { mkdir, writeFile } from 'node:fs/promises'
import { join, resolve } from 'node:path'
import { parseArgs } from 'node:util'
import { createPrisma } from '../database/prisma.js'
import { FatalImportError } from './firestore-import/exportReader.js'
import { importFirestore } from './firestore-import/importer.js'
import { stringify } from './firestore-import/report.js'

const USAGE = 'Usage: npm run import:firestore -- <export-dir> [--dry-run] [--fresh] [--strict] [--report-dir <dir>] [--timeout-minutes <n>] [--quiet]'

/** The connection string without its password, for the report. */
function redactUrl(url: string): string {
  try {
    const u = new URL(url)
    if (u.password) u.password = '***'
    return u.toString()
  } catch {
    return '(unparseable DATABASE_URL)'
  }
}

async function main(): Promise<number> {
  let args
  try {
    args = parseArgs({
      allowPositionals: true,
      options: {
        'dry-run': { type: 'boolean', default: false },
        fresh: { type: 'boolean', default: false },
        strict: { type: 'boolean', default: false },
        quiet: { type: 'boolean', default: false },
        'report-dir': { type: 'string' },
        'timeout-minutes': { type: 'string', default: '10' },
      },
    })
  } catch (e) {
    console.error(`${(e as Error).message}\n${USAGE}`)
    return 2
  }
  const { values, positionals } = args
  const minutes = Number(values['timeout-minutes'])
  if (positionals.length !== 1 || !(minutes > 0)) {
    console.error(USAGE)
    return 2
  }
  const url = process.env.DATABASE_URL
  if (!url) {
    console.error('DATABASE_URL is not set (the target PostgreSQL database).')
    return 2
  }

  const dir = resolve(positionals[0])
  const reportDir = resolve(values['report-dir'] ?? dir)
  const target = redactUrl(url)
  const quiet = values.quiet
  if (!quiet) console.error(`${values['dry-run'] ? 'Dry run' : 'Importing'} ${dir} → ${target}`)

  const db = createPrisma(url, 2)
  try {
    const report = await importFirestore(db, dir, {
      dryRun: values['dry-run'],
      fresh: values.fresh,
      target,
      transactionTimeoutMs: minutes * 60_000,
      log: quiet ? undefined : (m) => console.error(`  … ${m}`),
    })
    await mkdir(reportDir, { recursive: true })
    const summary = report.summary()
    await writeFile(join(reportDir, 'migration-report.json'), `${stringify(report.toJSON())}\n`)
    await writeFile(join(reportDir, 'migration-report.txt'), `${summary}\n`)
    console.log(summary)
    console.log(`\nFull report: ${join(reportDir, 'migration-report.json')}`)
    if (!report.ok) return 1
    if (values.strict && report.problems.some((p) => p.severity === 'error')) return 1
    return 0
  } catch (e) {
    if (e instanceof FatalImportError) {
      console.error(e.message)
      return 2
    }
    console.error(e)
    return 2
  } finally {
    await db.$disconnect()
  }
}

process.exitCode = await main()
