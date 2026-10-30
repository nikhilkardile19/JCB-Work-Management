import type { Tx } from '../../database/prisma.js'
import type { CollectionName } from '../../modules/sync/collections.js'
import type { ImportReport, Metric } from './report.js'

/** Import order inside a company: referenced collections first. */
export const SYNC_ORDER: CollectionName[] = ['clients', 'sites', 'machines', 'operators', 'petrolPumps', 'workLogs', 'fuelEntries', 'invoices', 'payments', 'auditLogs']

export const SYNC_TABLES: Record<CollectionName, string> = {
  clients: 'clients',
  sites: 'sites',
  machines: 'machines',
  operators: 'operators',
  petrolPumps: 'petrol_pumps',
  workLogs: 'work_logs',
  fuelEntries: 'fuel_entries',
  invoices: 'invoices',
  payments: 'payments',
  auditLogs: 'audit_logs',
}

/** Per-company figures computed from the source documents and from PostgreSQL. */
export const TOTAL_METRICS = [
  'invoices',
  'invoiceTotalPaise',
  'invoiceLines',
  'invoiceLineAmountPaise',
  'paymentsNotReversedPaise',
  'fuelTotalPaise',
  'workLogs',
  'workLogWorkingHours',
] as const
export type Totals = Record<(typeof TOTAL_METRICS)[number], bigint>
export const zeroTotals = (): Totals => Object.fromEntries(TOTAL_METRICS.map((m) => [m, 0n])) as Totals

export interface ReconcileInput {
  report: ImportReport
  /** Keys written by this run, by table (`companyId/id`, or `id` for global tables). */
  written: { keys: Map<string, Set<string>> }
  /** Source totals of the records imported, by company. */
  totals: Map<string, Totals>
  importedCompanies: Set<string>
}

const scoped = (table: string, key = "company_id || '/' || id") => ({ table, scoped: true, sql: `SELECT ${key} AS k FROM ${table} WHERE company_id = ANY($1::text[])` })
const global = (table: string, key = 'id') => ({ table, scoped: false, sql: `SELECT ${key} AS k FROM ${table}` })

/**
 * Global tables may hold rows from elsewhere (e.g. an admin created with
 * `npm run admin:create`): extra rows are a warning. In the imported
 * companies' tables every row must come from the export.
 */
const TABLES = [
  global('users'),
  global('developer_admins', 'user_id'),
  global('companies'),
  scoped('company_members', "company_id || '/' || user_id"),
  scoped('licenses'),
  scoped('devices'),
  scoped('device_replacement_requests'),
  scoped('issued_invoice_numbers', "company_id || '/' || invoice_id"),
  scoped('invoice_number_counters', "company_id || '/' || financial_year"),
  ...Object.values(SYNC_TABLES).map((t) => scoped(t)),
  scoped('invoice_lines'),
  global('audit_events'),
]

const TOTALS_SQL = `
SELECT
  (SELECT count(*) FROM invoices WHERE company_id = $1)::bigint AS "invoices",
  (SELECT coalesce(sum(total_paise), 0) FROM invoices WHERE company_id = $1)::bigint AS "invoiceTotalPaise",
  (SELECT count(*) FROM invoice_lines WHERE company_id = $1)::bigint AS "invoiceLines",
  (SELECT coalesce(sum(amount_paise), 0) FROM invoice_lines WHERE company_id = $1)::bigint AS "invoiceLineAmountPaise",
  (SELECT coalesce(sum(amount_paise), 0) FROM payments WHERE company_id = $1 AND reversed_at IS NULL)::bigint AS "paymentsNotReversedPaise",
  (SELECT coalesce(sum(total_paise), 0) FROM fuel_entries WHERE company_id = $1)::bigint AS "fuelTotalPaise",
  (SELECT count(*) FROM work_logs WHERE company_id = $1)::bigint AS "workLogs",
  (SELECT coalesce(sum(working_hours), 0) FROM work_logs WHERE company_id = $1)::bigint AS "workLogWorkingHours"`

interface OrphanCheck {
  name: string
  severity: 'error' | 'warning'
  table: string
  /** Returns company_id, id, detail. */
  sql: string
}

/** `table.fk` must name a row of `target` in the same company. */
const sameCompany = (severity: 'error' | 'warning', table: string, fk: string, target: string, nullable = false): OrphanCheck => ({
  name: `${table}.${fk}→${target}`,
  severity,
  table,
  sql: `SELECT t.company_id, t.id, '${fk} ' || t.${fk} || ' not in ${target}' AS detail FROM ${table} t
        WHERE ${nullable ? `t.${fk} IS NOT NULL AND ` : ''}NOT EXISTS (SELECT 1 FROM ${target} r WHERE r.company_id = t.company_id AND r.id = t.${fk})`,
})

const toUser = (severity: 'error' | 'warning', table: string, fk: string, company: string, id: string): OrphanCheck => ({
  name: `${table}.${fk}→users`,
  severity,
  table,
  sql: `SELECT ${company} AS company_id, ${id} AS id, '${fk} ' || t.${fk} || ' not in users' AS detail FROM ${table} t
        WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = t.${fk})`,
})

/**
 * Run after the import. "error" checks repeat what the foreign keys enforce
 * (they must find nothing); "warning" checks cover the soft references the
 * schema deliberately leaves unconstrained.
 */
const ORPHAN_CHECKS: OrphanCheck[] = [
  sameCompany('error', 'sites', 'client_id', 'clients'),
  sameCompany('error', 'work_logs', 'client_id', 'clients'),
  sameCompany('error', 'work_logs', 'site_id', 'sites'),
  sameCompany('error', 'work_logs', 'machine_id', 'machines'),
  sameCompany('error', 'work_logs', 'operator_id', 'operators', true),
  sameCompany('error', 'fuel_entries', 'machine_id', 'machines'),
  sameCompany('error', 'fuel_entries', 'pump_id', 'petrol_pumps'),
  sameCompany('error', 'fuel_entries', 'client_id', 'clients', true),
  sameCompany('error', 'fuel_entries', 'site_id', 'sites', true),
  sameCompany('error', 'invoices', 'client_id', 'clients'),
  sameCompany('error', 'invoice_lines', 'invoice_id', 'invoices'),
  sameCompany('error', 'invoice_lines', 'work_log_id', 'work_logs'),
  sameCompany('error', 'payments', 'invoice_id', 'invoices'),
  sameCompany('error', 'devices', 'license_id', 'licenses'),
  sameCompany('error', 'device_replacement_requests', 'license_id', 'licenses'),
  toUser('error', 'company_members', 'user_id', 't.company_id', 't.user_id'),
  toUser('error', 'companies', 'owner_user_id', 't.id', 't.id'),
  toUser('error', 'developer_admins', 'user_id', 'NULL', 't.user_id'),
  {
    name: 'invoice_number_counters behind issued numbers',
    severity: 'error',
    table: 'invoice_number_counters',
    sql: `SELECT n.company_id, n.financial_year AS id,
                 'highest issued ' || max(n.invoice_number) || ' but counter last = ' || coalesce(c.last, 0) AS detail
          FROM issued_invoice_numbers n
          LEFT JOIN invoice_number_counters c ON c.company_id = n.company_id AND c.financial_year = n.financial_year
          GROUP BY n.company_id, n.financial_year, c.last
          HAVING max(substring(n.invoice_number from '([0-9]+)$')::int) > coalesce(c.last, 0)`,
  },
  sameCompany('warning', 'work_logs', 'invoice_id', 'invoices', true),
  sameCompany('warning', 'invoice_lines', 'site_id', 'sites'),
  sameCompany('warning', 'invoice_lines', 'machine_id', 'machines'),
  {
    name: 'issued_invoice_numbers.invoice_id→invoices',
    severity: 'warning',
    table: 'issued_invoice_numbers',
    sql: `SELECT n.company_id, n.invoice_id AS id, 'number ' || n.invoice_number || ' issued for an invoice that is not in invoices' AS detail
          FROM issued_invoice_numbers n
          WHERE NOT EXISTS (SELECT 1 FROM invoices i WHERE i.company_id = n.company_id AND i.id = n.invoice_id)`,
  },
  {
    name: 'invoices.invoice_number not the issued number',
    severity: 'warning',
    table: 'invoices',
    sql: `SELECT i.company_id, i.id, i.status || ' invoice ' || coalesce(i.invoice_number, '(none)') || ' has no matching issued number' AS detail
          FROM invoices i
          WHERE i.status <> 'draft' AND NOT EXISTS (
            SELECT 1 FROM issued_invoice_numbers n
            WHERE n.company_id = i.company_id AND n.invoice_id = i.id AND n.invoice_number = i.invoice_number)`,
  },
  {
    name: 'payments on invoices that are not finalized',
    severity: 'warning',
    table: 'payments',
    sql: `SELECT p.company_id, p.id, 'counted payment on ' || i.status || ' invoice ' || i.id AS detail
          FROM payments p JOIN invoices i ON i.company_id = p.company_id AND i.id = p.invoice_id
          WHERE p.reversed_at IS NULL AND i.status <> 'finalized'`,
  },
  toUser('warning', 'devices', 'user_id', 't.company_id', 't.id'),
  toUser('warning', 'device_replacement_requests', 'requested_by', 't.company_id', 't.id'),
  {
    name: 'audit_events.company_id→companies',
    severity: 'warning',
    table: 'audit_events',
    sql: `SELECT e.company_id, e.id, 'company ' || e.company_id || ' not in companies' AS detail FROM audit_events e
          WHERE e.company_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM companies c WHERE c.id = e.company_id)`,
  },
]

const sample = (keys: string[]) => keys.slice(0, 5).join(', ') + (keys.length > 5 ? ', …' : '')

/**
 * Source vs PostgreSQL: export integrity (manifest counts), every imported
 * key present per table, per-company money/hour totals, and the SQL orphan
 * checks. Any failure is recorded with `report.fail`.
 */
export async function reconcile(db: Tx, input: ReconcileInput) {
  const { report } = input

  for (const [kind, c] of Object.entries(report.kinds)) {
    if (c.manifest === null) report.fail(`${kind}: ${c.lines} line(s) in the export but no count in manifest.json.`)
    else if (c.manifest !== c.lines) report.fail(`${kind}: manifest.json counts ${c.manifest} but the files have ${c.lines} line(s) — truncated or edited export.`)
    const settled = c.imported + c.rejected + c.skipped
    if (settled !== c.read) report.fail(`${kind}: ${c.read - settled} document(s) were neither imported nor reported.`)
  }

  const companies = [...input.importedCompanies].sort()
  report.tables = []
  for (const spec of TABLES) {
    const expected = input.written.keys.get(spec.table) ?? new Set<string>()
    const rows = await db.$queryRawUnsafe<{ k: string }[]>(spec.sql, ...(spec.scoped ? [companies] : []))
    const actual = new Set(rows.map((r) => r.k))
    const missing = [...expected].filter((k) => !actual.has(k)).sort()
    const extra = [...actual].filter((k) => !expected.has(k)).sort()
    if (missing.length) report.fail(`${spec.table}: ${missing.length} imported row(s) not found in the database (${sample(missing)}).`)
    if (extra.length && spec.scoped) report.fail(`${spec.table}: ${extra.length} row(s) of the imported companies are not in the export (${sample(extra)}).`)
    if (extra.length && !spec.scoped) {
      report.problem({ severity: 'warning', code: 'target_only', kind: spec.table, message: `${extra.length} row(s) in ${spec.table} are not from this export (${sample(extra)}).` })
    }
    report.tables.push({
      table: spec.table,
      expected: expected.size,
      database: actual.size,
      missing: missing.slice(0, 50),
      extra: extra.slice(0, 50),
      ok: missing.length === 0 && (!spec.scoped || extra.length === 0),
    })
  }

  report.totals = []
  for (const companyId of companies) {
    const source = input.totals.get(companyId)!
    const [row] = await db.$queryRawUnsafe<Record<string, unknown>[]>(TOTALS_SQL, companyId)
    const metrics: Record<string, Metric> = {}
    for (const m of TOTAL_METRICS) {
      const database = BigInt(String(row[m]))
      metrics[m] = { source: source[m].toString(), database: database.toString(), ok: source[m] === database }
      if (source[m] !== database) report.fail(`${companyId}: ${m} is ${source[m]} in the source but ${database} in PostgreSQL.`)
    }
    report.totals.push({ companyId, metrics })
  }

  report.orphans = []
  for (const check of ORPHAN_CHECKS) {
    const rows = await db.$queryRawUnsafe<{ company_id: string | null; id: string; detail: string }[]>(check.sql)
    for (const r of rows) {
      report.orphans.push({ check: check.name, severity: check.severity, table: check.table, companyId: r.company_id, id: r.id, detail: r.detail })
    }
    if (rows.length && check.severity === 'error') report.fail(`orphan check ${check.name}: ${rows.length} row(s).`)
  }
  report.reconciled = true
}
