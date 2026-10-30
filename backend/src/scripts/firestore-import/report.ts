import type { SourceDoc } from './exportReader.js'

export type Severity = 'error' | 'warning' | 'info'

/**
 * error   — a source record was not imported (or reconciliation is at risk);
 * warning — imported, but something was adjusted or looks wrong;
 * info    — expected, documented behaviour (e.g. a field intentionally dropped).
 */
export type ProblemCode =
  | 'malformed' // unreadable line, bad path, undecodable value
  | 'invalid' // failed the collection schema / required fields
  | 'duplicate' // same path twice, or a unique key already taken
  | 'orphan' // refers to a record that is missing or was not imported
  | 'fk_violation' // the database refused a reference
  | 'db_constraint' // any other database refusal (check constraint, …)
  | 'company_missing' // a subcollection document under a company document that does not exist
  | 'company_not_imported' // its company was rejected
  | 'company_failed' // the company's transaction failed as a whole
  | 'unmapped_collection' // no PostgreSQL table for this kind
  | 'skipped_collection' // deliberately not migrated (rateLimits)
  | 'unmapped_field' // a field with no column; dropped
  | 'missing_email' // an Auth user without a usable email
  | 'email_mismatch' // companyUsers/developerAdmins email differs from Auth
  | 'user_from_membership' // user created from a companyUsers email (absent from the Auth export)
  | 'id_mismatch' // a document's id field differs from its document ID
  | 'profile_invalid' // company profile fails today's validation; imported as is
  | 'target_only' // a row in the target that is not in the export
  | 'counter_behind' // an invoice counter is below a number already issued

export interface Problem {
  severity: Severity
  code: ProblemCode
  kind?: string
  path?: string
  companyId?: string
  message: string
}

type Outcome = 'imported' | 'rejected' | 'skipped'

export interface KindCounts {
  /** Count the exporter wrote to manifest.json (null when absent). */
  manifest: number | null
  /** Non-empty lines in the export files. */
  lines: number
  malformed: number
  duplicate: number
  /** Parsed documents; each ends as exactly one of imported, rejected or skipped. */
  read: number
  imported: number
  rejected: number
  skipped: number
}

export interface TableCheck {
  table: string
  /** Rows this run imported (or, in a dry run, would import). */
  expected: number
  /** Rows in the table (scoped to the imported companies for company tables). */
  database: number
  missing: string[]
  extra: string[]
  ok: boolean
}

export interface Metric {
  source: string
  database: string
  ok: boolean
}

export interface CompanyTotals {
  companyId: string
  metrics: Record<string, Metric>
}

export interface OrphanFinding {
  check: string
  severity: 'error' | 'warning'
  table: string
  companyId: string | null
  id: string
  detail: string
}

const SAMPLE = 20

export class ImportReport {
  readonly startedAt = new Date()
  finishedAt: Date | null = null
  mode: 'import' | 'dry-run' = 'import'
  fresh = false
  exportDir = ''
  projectId: string | null = null
  exportedAt: string | null = null
  target = ''

  readonly problems: Problem[] = []
  readonly droppedFields: Record<string, Record<string, number>> = {}
  tables: TableCheck[] = []
  totals: CompanyTotals[] = []
  orphans: OrphanFinding[] = []
  readonly failures: string[] = []
  reconciled = false

  private readonly lineCounts = new Map<string, { lines: number; malformed: number; duplicate: number; read: number }>()
  private readonly outcomes = new Map<string, { kind: string; outcome: Outcome }>()
  private manifestCounts: Record<string, number> = {}

  problem(p: Problem) {
    this.problems.push(p)
  }

  lineRead(kind: string, what: 'read' | 'malformed' | 'duplicate') {
    const c = this.lineCounts.get(kind) ?? { lines: 0, malformed: 0, duplicate: 0, read: 0 }
    c.lines++
    c[what]++
    this.lineCounts.set(kind, c)
  }

  setManifestCounts(counts: Record<string, number>) {
    this.manifestCounts = counts
  }

  /** Final outcome of a source document (a later call replaces an earlier one). */
  settle(doc: SourceDoc, outcome: Outcome) {
    this.outcomes.set(doc.path, { kind: doc.kind, outcome })
  }

  outcomeOf(doc: SourceDoc): Outcome | undefined {
    return this.outcomes.get(doc.path)?.outcome
  }

  /** Rejects [doc] with an error problem. */
  reject(doc: SourceDoc, code: ProblemCode, message: string, companyId?: string) {
    this.settle(doc, 'rejected')
    this.problem({ severity: 'error', code, kind: doc.kind, path: doc.path, companyId, message })
  }

  dropped(kind: string, field: string) {
    const k = (this.droppedFields[kind] ??= {})
    k[field] = (k[field] ?? 0) + 1
  }

  fail(message: string) {
    this.failures.push(message)
  }

  get kinds(): Record<string, KindCounts> {
    const kinds = new Set([...this.lineCounts.keys(), ...Object.keys(this.manifestCounts)])
    const out: Record<string, KindCounts> = {}
    for (const kind of [...kinds].sort()) {
      const l = this.lineCounts.get(kind) ?? { lines: 0, malformed: 0, duplicate: 0, read: 0 }
      out[kind] = { manifest: this.manifestCounts[kind] ?? null, ...l, imported: 0, rejected: 0, skipped: 0 }
    }
    for (const { kind, outcome } of this.outcomes.values()) out[kind][outcome]++
    return out
  }

  get ok(): boolean {
    return this.reconciled && this.failures.length === 0
  }

  problemCounts(): Record<string, number> {
    const out: Record<string, number> = {}
    for (const p of this.problems) out[`${p.severity}:${p.code}`] = (out[`${p.severity}:${p.code}`] ?? 0) + 1
    return out
  }

  toJSON() {
    return {
      tool: 'importFirestore',
      formatVersion: 1,
      mode: this.mode,
      fresh: this.fresh,
      startedAt: this.startedAt.toISOString(),
      finishedAt: this.finishedAt?.toISOString() ?? null,
      export: { dir: this.exportDir, projectId: this.projectId, exportedAt: this.exportedAt },
      target: this.target,
      reconciliation: { ok: this.ok, ran: this.reconciled, failures: this.failures },
      kinds: this.kinds,
      tables: this.tables,
      totals: this.totals,
      orphans: this.orphans,
      problemCounts: this.problemCounts(),
      problems: this.problems,
      droppedFields: this.droppedFields,
    }
  }

  /** Plain-text summary for the console and migration-report.txt. */
  summary(): string {
    const out: string[] = []
    const line = (s = '') => out.push(s)
    line(`Firestore → PostgreSQL import — ${this.mode === 'dry-run' ? 'DRY RUN (nothing was written)' : 'IMPORT'}${this.fresh ? ' --fresh' : ''}`)
    line(`Export:  ${this.exportDir} (project ${this.projectId ?? '?'}, exported ${this.exportedAt ?? '?'})`)
    line(`Target:  ${this.target}`)
    line(`Result:  ${!this.reconciled ? 'NOT RECONCILED' : this.ok ? 'RECONCILED — counts, totals and references match' : 'RECONCILIATION FAILED'}`)
    line()

    line('Source documents (read = imported + rejected + skipped)')
    const kinds = this.kinds
    const w = Math.max(28, ...Object.keys(kinds).map((k) => k.length))
    line(`  ${'kind'.padEnd(w)} ${'manifest'.padStart(8)} ${'read'.padStart(6)} ${'imported'.padStart(8)} ${'rejected'.padStart(8)} ${'skipped'.padStart(7)} ${'bad lines'.padStart(9)}`)
    for (const [kind, c] of Object.entries(kinds)) {
      line(
        `  ${kind.padEnd(w)} ${String(c.manifest ?? '-').padStart(8)} ${String(c.read).padStart(6)} ${String(c.imported).padStart(8)} ${String(c.rejected).padStart(8)} ${String(c.skipped).padStart(7)} ${String(c.malformed + c.duplicate).padStart(9)}`,
      )
    }
    line()

    if (this.tables.length) {
      line('Tables (expected = imported by this run)')
      const tw = Math.max(28, ...this.tables.map((t) => t.table.length))
      line(`  ${'table'.padEnd(tw)} ${'expected'.padStart(8)} ${'in db'.padStart(8)}  ok`)
      for (const t of this.tables) {
        line(`  ${t.table.padEnd(tw)} ${String(t.expected).padStart(8)} ${String(t.database).padStart(8)}  ${t.ok ? 'yes' : 'NO'}`)
      }
      line()
    }

    if (this.totals.length) {
      line('Per-company totals (source records imported vs PostgreSQL)')
      for (const c of this.totals) {
        line(`  ${c.companyId}`)
        for (const [name, m] of Object.entries(c.metrics)) {
          line(`    ${name.padEnd(34)} ${m.source.padStart(14)} ${m.database.padStart(14)}  ${m.ok ? 'ok' : 'MISMATCH'}`)
        }
      }
      line()
    }

    if (this.orphans.length) {
      line(`Orphan check (SQL, after import): ${this.orphans.length} finding(s)`)
      for (const o of this.orphans.slice(0, SAMPLE)) line(`  [${o.severity}] ${o.check}: ${o.table} ${o.companyId ?? ''}/${o.id} — ${o.detail}`)
      if (this.orphans.length > SAMPLE) line(`  … ${this.orphans.length - SAMPLE} more in migration-report.json`)
      line()
    } else if (this.reconciled) {
      line('Orphan check (SQL, after import): none')
      line()
    }

    const counts = this.problemCounts()
    line(`Problems: ${this.problems.length}${Object.keys(counts).length ? ` (${Object.entries(counts).map(([k, n]) => `${k} ${n}`).join(', ')})` : ''}`)
    for (const sev of ['error', 'warning', 'info'] as const) {
      const list = this.problems.filter((p) => p.severity === sev)
      for (const p of list.slice(0, SAMPLE)) line(`  [${sev}] ${p.code}${p.path ? ` ${p.path}` : p.kind ? ` ${p.kind}` : ''}: ${p.message}`)
      if (list.length > SAMPLE) line(`  … ${list.length - SAMPLE} more ${sev}s in migration-report.json`)
    }
    const dropped = Object.entries(this.droppedFields)
    if (dropped.length) {
      line()
      line('Fields not stored (by design or unknown; see problems for unknown ones)')
      for (const [kind, fields] of dropped) line(`  ${kind}: ${Object.entries(fields).map(([f, n]) => `${f} ×${n}`).join(', ')}`)
    }
    if (this.failures.length) {
      line()
      line('Reconciliation failures')
      for (const f of this.failures) line(`  - ${f}`)
    }
    return out.join('\n')
  }
}

/** JSON.stringify that writes bigints as strings. */
export const stringify = (value: unknown) => JSON.stringify(value, (_k, v) => (typeof v === 'bigint' ? v.toString() : v), 2)
