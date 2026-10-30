import { spawnSync } from 'node:child_process'
import { cp, mkdtemp, readdir, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { afterAll, describe, expect, it, onTestFinished } from 'vitest'
import type { Tx } from '../src/database/prisma.js'
import { hashPassword } from '../src/modules/auth/passwords.js'
import { hashCode } from '../src/modules/licenses/activationCodes.js'
import { saveRecord, type CollectionName, type Json } from '../src/modules/sync/collections.js'
import { FatalImportError } from '../src/scripts/firestore-import/exportReader.js'
import { importFirestore } from '../src/scripts/firestore-import/importer.js'
import { PASSWORD, tokenFor } from './helpers/factories.js'
import { TEST_DATABASE_URL } from './helpers/globalSetup.js'
import { useTestApp } from './helpers/testApp.js'

/**
 * Phase F import, against the hand-written export in
 * tests/fixtures/firestore-export (the same shape tools/firestore-export
 * writes; the emulator end-to-end run round-trips it through Firestore).
 */
const env = useTestApp()
const FIXTURE = fileURLToPath(new URL('./fixtures/firestore-export', import.meta.url))
const BACKEND = fileURLToPath(new URL('..', import.meta.url))

const CO = '3f6c1a9e-8b2d-4e7f-a1c5-9d0b2e4f6a81'
const CO2 = '7a2e5c8b-1d4f-4a6e-b9c3-2f8d0e1a5b74'
const GHOST = 'c0ffee00-dead-4bee-8f00-000000000bad'
const U = {
  owner: 'h7GfQ2xLmP9sVt3RkW8bNc1YzA04',
  operator: 'Zr5Nc1WqH8tB3vL6mX0pS9dK2gF4',
  disabledOp: 'Wd6Fp3JkS9mQ1xR4tZ7bV2nC8hL5',
  manager: 'Lc8Vm1QzT5rK9wB2xN6pH3sJ7dF0',
  devSuper: 'Yj3Bq6WmR9tL2xZ5cN8vK1sH4dF7',
  devSupport: 'Gs1Tn4XpK7wM0zR3bV6qL9cH2dJ5',
}
const LIC = 'A7kQ2mZx9VbN4tR1pL8s'
const LIC_COPY = 'x2Hd8KpW5nQ9rT3vB6mC'
const DEV_OWNER = '9b1f7e3a-6c2d-4f8e-a5b0-1d3c7e9f2a64'
const CLIENT = 'b8e2f4a6-3c5d-4e7f-9a1b-2c4d6e8f0a13'
const W = {
  w1: '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c01',
  w2: '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c02',
  w3: '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c03',
  w4: '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c04',
  w5: '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c05',
  orphan: '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c06',
  bad: '0a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c07',
}
const INV1 = '7c8d9e0f-1a2b-4c3d-8e4f-5a6b7c8d9e01'
const AUDIT_LOG_FINALIZE = '9d0e1f2a-3b4c-4d5e-8f6a-7b8c9d0e1f02'
const SYNC_TABLES = ['clients', 'sites', 'machines', 'operators', 'petrol_pumps', 'work_logs', 'fuel_entries', 'invoices', 'payments', 'audit_logs']

const temps: string[] = []
afterAll(async () => {
  for (const d of temps) await rm(d, { recursive: true, force: true })
})
const tempDir = async () => {
  const d = await mkdtemp(join(tmpdir(), 'jcb-import-test-'))
  temps.push(d)
  return d
}

/** The fixture's readable documents of one kind, as the exporter wrote them. */
async function source(kind: string): Promise<{ path: string; id: string; data: Json }[]> {
  const manifest = JSON.parse(await readFile(join(FIXTURE, 'manifest.json'), 'utf8'))
  const text = await readFile(join(FIXTURE, manifest.files[kind].file), 'utf8')
  return text
    .split('\n')
    .filter(Boolean)
    .flatMap((l) => {
      try {
        return [JSON.parse(l)]
      } catch {
        return []
      }
    })
}

/** Business fields: what the app pushed (Drift toJson minus device-only paths). */
const business = (data: Json) => {
  const { rev: _r, serverUpdatedAt: _s, pushedBy: _p, deviceId: _d, syncStatus: _st, ...rest } = data
  return rest
}

/** Every row of every table, for before/after comparisons. */
async function dumpAll() {
  const tables = await env.db.$queryRaw<{ tablename: string }[]>`
    SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename <> '_prisma_migrations' ORDER BY tablename`
  const out: Record<string, string[]> = {}
  for (const { tablename } of tables) {
    const rows = await env.db.$queryRawUnsafe<{ j: string }[]>(`SELECT row_to_json(t)::text AS j FROM "${tablename}" t`)
    out[tablename] = rows.map((r) => r.j).sort()
  }
  return out
}

const run = (opts: Parameters<typeof importFirestore>[2] = {}) => importFirestore(env.db, FIXTURE, opts)

describe('import: reconciliation', () => {
  it('imports the export; counts and per-company totals reconcile', async () => {
    const report = await run({ fresh: true })
    expect(report.failures).toEqual([])
    expect(report.ok).toBe(true)

    const k = report.kinds
    expect(k.__auth__).toMatchObject({ manifest: 9, read: 9, imported: 9, rejected: 0 })
    expect(k['companies/*/workLogs']).toMatchObject({ manifest: 7, read: 7, imported: 5, rejected: 2 })
    expect(k['companies/*/fuelEntries']).toMatchObject({ manifest: 3, lines: 3, malformed: 1, read: 2, imported: 2 })
    expect(k['companies/*/licenses']).toMatchObject({ read: 2, imported: 1, rejected: 1 })
    expect(k['companies/*/clients']).toMatchObject({ read: 3, imported: 2, rejected: 1 })
    expect(k.rateLimits).toMatchObject({ read: 1, skipped: 1, imported: 0 })
    expect(k.appConfig).toMatchObject({ read: 1, skipped: 1, imported: 0 })
    for (const c of Object.values(k)) expect(c.imported + c.rejected + c.skipped).toBe(c.read)

    const tables = Object.fromEntries(report.tables.map((t) => [t.table, t]))
    expect(report.tables.every((t) => t.ok)).toBe(true)
    expect(tables.users).toMatchObject({ expected: 10, database: 10 })
    expect(tables.company_members).toMatchObject({ expected: 7, database: 7 })
    expect(tables.work_logs).toMatchObject({ expected: 5, database: 5 })
    expect(tables.invoice_lines).toMatchObject({ expected: 4, database: 4 })
    expect(tables.audit_events).toMatchObject({ expected: 7, database: 7 })

    // Hand-computed from the fixture.
    const totals = report.totals.find((t) => t.companyId === CO)!.metrics
    const expected = {
      invoices: '3',
      invoiceTotalPaise: '4470000', // 23 500.00 + 9 600.00 (cancelled) + 11 600.00 (draft)
      invoiceLines: '4',
      invoiceLineAmountPaise: '4520000',
      paymentsNotReversedPaise: '2350000', // 15 000 + 8 500; the reversed 5 000 is not counted
      fuelTotalPaise: '999021', // 45.50 L × ₹94.62 + 60.00 L × ₹94.75, half-up
      workLogs: '5',
      workLogWorkingHours: '2925', // 8.50 + 7.50 + 7.25 + 6.00 h; the draft has none
    }
    for (const [m, v] of Object.entries(expected)) expect(totals[m], m).toEqual({ source: v, database: v, ok: true })
    expect(Object.values(report.totals.find((t) => t.companyId === CO2)!.metrics).every((m) => m.database === '0')).toBe(true)

    // Straight from PostgreSQL as well.
    const paid = await env.db.payment.aggregate({ where: { companyId: CO, reversedAt: null }, _sum: { amountPaise: true } })
    expect(paid._sum.amountPaise).toBe(2_350_000n)
    expect(report.summary()).toContain('RECONCILED')
  })

  it('reports every bad record and keeps going', async () => {
    const report = await run({ fresh: true })
    expect(report.ok).toBe(true)
    const one = (code: string) => {
      const found = report.problems.filter((p) => p.code === code)
      expect(found, code).toHaveLength(1)
      return found[0]
    }
    expect(one('malformed')).toMatchObject({ severity: 'error', kind: 'companies/*/fuelEntries' })
    expect(one('malformed').message).toContain('companies.fuelEntries.ndjson:3')
    expect(one('invalid')).toMatchObject({ severity: 'error', path: `companies/${CO}/workLogs/${W.bad}` })
    expect(one('invalid').message).toContain('startReading')
    expect(one('orphan')).toMatchObject({ severity: 'error', path: `companies/${CO}/workLogs/${W.orphan}` })
    expect(one('orphan').message).toContain('siteId ffffffff-0000-4000-8000-00000000dead')
    expect(one('duplicate')).toMatchObject({ severity: 'error', path: `companies/${CO}/licenses/${LIC_COPY}` })
    expect(one('company_missing')).toMatchObject({ severity: 'error', path: expect.stringContaining(`companies/${GHOST}/clients/`) })
    expect(one('unmapped_collection')).toMatchObject({ severity: 'warning', kind: 'appConfig' })
    expect(one('skipped_collection')).toMatchObject({ severity: 'info', kind: 'rateLimits' })
    expect(one('user_from_membership')).toMatchObject({ severity: 'warning', path: `companies/${CO}/companyUsers/${U.manager}` })
    expect(report.problems.filter((p) => p.severity === 'error')).toHaveLength(5)

    // SQL orphan check: only the soft reference left by a number issued for an invoice never uploaded.
    expect(report.orphans).toEqual([
      expect.objectContaining({ severity: 'warning', check: 'issued_invoice_numbers.invoice_id→invoices', id: '7c8d9e0f-1a2b-4c3d-8e4f-5a6b7c8d9e04' }),
    ])
    expect(report.droppedFields.companies).toEqual({ nameLower: 2, schemaVersion: 2 })
    expect(report.droppedFields['companies/*/machines']).toEqual({ syncStatus: 1 })
    expect(await env.db.workLog.count({ where: { id: { in: [W.orphan, W.bad] } } })).toBe(0)
  })

  it('fails reconciliation for a truncated export, and exits 0 / 1 / 2 from the command line', async () => {
    const reports = await tempDir()
    const cli = (dir: string, ...args: string[]) =>
      spawnSync(join(BACKEND, 'node_modules/.bin/tsx'), ['src/scripts/importFirestore.ts', dir, '--quiet', '--report-dir', reports, ...args], {
        cwd: BACKEND,
        env: { ...process.env, DATABASE_URL: TEST_DATABASE_URL },
        encoding: 'utf8',
      })

    const ok = cli(FIXTURE, '--fresh')
    expect(ok.status, ok.stderr).toBe(0)
    expect(ok.stdout).toContain('RECONCILED')
    const written = JSON.parse(await readFile(join(reports, 'migration-report.json'), 'utf8'))
    expect(written).toMatchObject({ mode: 'import', fresh: true, reconciliation: { ok: true } })
    expect(await readFile(join(reports, 'migration-report.txt'), 'utf8')).toContain('Per-company totals')

    // A file that lost lines after the export: the manifest still has the original count.
    const truncated = await tempDir()
    await cp(FIXTURE, truncated, { recursive: true })
    const file = join(truncated, 'companies.payments.ndjson')
    const lines = (await readFile(file, 'utf8')).trim().split('\n')
    await writeFile(file, `${lines.slice(0, -1).join('\n')}\n`)
    const failed = cli(truncated, '--dry-run')
    expect(failed.status).toBe(1)
    expect(failed.stdout).toContain('RECONCILIATION FAILED')
    expect(failed.stdout).toContain('companies/*/payments: manifest.json counts 3 but the files have 2 line(s)')

    // --strict: rejected source records fail the run even though it reconciles.
    expect(cli(FIXTURE, '--dry-run', '--strict').status).toBe(1)
    expect(cli(join(truncated, 'nope')).status).toBe(2)
    expect(cli(FIXTURE, '--fresh').status).toBe(2) // the target is no longer empty
  }, 60_000)
})

describe('import: fidelity', () => {
  it('keeps Firebase UIDs, document IDs, revisions and timestamps', async () => {
    await run({ fresh: true })
    const db = env.db

    const owner = await db.user.findUniqueOrThrow({ where: { id: U.owner } })
    expect(owner).toMatchObject({ email: 'ravi.patil@saiearthmovers.in', passwordHash: null, status: 'active', lastLoginAt: new Date('2026-10-28T03:41:09Z') })
    expect(owner.createdAt).toEqual(new Date('2026-08-02T05:12:40Z'))
    expect(await db.user.findUniqueOrThrow({ where: { id: U.disabledOp } })).toMatchObject({ status: 'disabled' })
    // Only in companyUsers, with a mixed-case email: created, lower-cased, no password.
    expect(await db.user.findUniqueOrThrow({ where: { id: U.manager } })).toMatchObject({ email: 'prakash.kale@saiearthmovers.in', passwordHash: null })
    expect(await db.companyMember.findUniqueOrThrow({ where: { companyId_userId: { companyId: CO, userId: U.manager } } })).toMatchObject({ role: 'manager', status: 'active' })
    expect(await db.companyMember.findUniqueOrThrow({ where: { companyId_userId: { companyId: CO, userId: U.disabledOp } } })).toMatchObject({ status: 'disabled' })

    expect(await db.developerAdmin.findMany({ orderBy: { role: 'asc' } })).toEqual([
      expect.objectContaining({ userId: U.devSuper, role: 'super', permissions: [] }),
      expect.objectContaining({ userId: U.devSupport, role: 'support', permissions: ['licenses.manage', 'devices.revoke'] }),
    ])

    const company = await db.company.findUniqueOrThrow({ where: { id: CO } })
    expect(company).toMatchObject({ name: 'Sai Earthmovers', ownerUserId: U.owner, status: 'active', invoicePrefix: 'SAI', currency: 'INR' })
    expect(company.createdAt.toISOString()).toBe('2026-08-02T05:20:11.000Z') // Firestore had …11.000482: sub-millisecond part dropped
    expect(await db.company.findUniqueOrThrow({ where: { id: CO2 } })).toMatchObject({ status: 'pending', email: null, gstin: null })

    // The activation code customers already hold keeps working.
    const license = await db.license.findUniqueOrThrow({ where: { id: LIC } })
    expect(license).toMatchObject({ companyId: CO, status: 'active', maxDevices: 3, activationCodeHash: hashCode('JCBW-7KQ2-M9XD-PA4H') })
    expect(license.validUntil).toEqual(new Date('2027-08-03T00:00:00Z'))
    expect(await db.device.count({ where: { companyId: CO, status: 'active' } })).toBe(3)
    expect(await db.device.findUniqueOrThrow({ where: { companyId_id: { companyId: CO, id: '2c6e0a4b-8d1f-4b3e-9a5c-7e9b1d3f5a28' } } })).toMatchObject({
      status: 'revoked',
      replacedBy: 'e4a8c2f6-0b3d-4e9a-8c1f-5a7b9d2e4c06',
    })
    expect(await db.deviceReplacementRequest.findMany({ orderBy: { status: 'asc' }, select: { id: true, status: true } })).toEqual([
      { id: 'Pv7Jh1Xc5Nm9Ty3Gw6Fq', status: 'pending' },
      { id: 'Mn4Rt8Wx2Zb6Kd0Qp3Ls', status: 'approved' },
    ])
    expect(await db.issuedInvoiceNumber.findUniqueOrThrow({ where: { companyId_invoiceId: { companyId: CO, invoiceId: INV1 } } })).toMatchObject({
      invoiceNumber: 'SAI/2026-27/0001',
      financialYear: '2026-27',
    })
    expect(await db.invoiceNumberCounter.findUniqueOrThrow({ where: { companyId_financialYear: { companyId: CO, financialYear: '2026-27' } } })).toMatchObject({ last: 3 })

    // auditEvents: known fields to columns, the rest to details; `uid` doubles as the actor.
    const activate = await db.auditEvent.findUniqueOrThrow({ where: { id: '2Ke6Nr0Vz4Dp8Tx3Bm7Y' } })
    expect(activate).toMatchObject({ type: 'device.activate', actorId: U.owner, companyId: CO, licenseId: LIC, deviceId: DEV_OWNER, reason: null, at: new Date('2026-08-03T10:00:00Z') })
    expect(activate.details).toEqual({ uid: U.owner, deviceModel: 'Samsung Galaxy M34' })
    expect((await db.auditEvent.findUniqueOrThrow({ where: { id: '0Hc4Lp8Tx2Bn6Rv1Zk5W' } })).details).toEqual({ from: 'pending', to: 'active' })

    // Synced records: rev and server time preserved.
    const w1 = await db.workLog.findUniqueOrThrow({ where: { companyId_id: { companyId: CO, id: W.w1 } } })
    expect(w1).toMatchObject({ rev: 4, pushedBy: 'Bt9Hk4RmZ2xV7cN1qL5wP8sD3fG6', status: 'invoiced', invoiceId: INV1, workingHours: 850 })
    expect(w1.serverUpdatedAt).toEqual(new Date('2026-10-16T10:00:00Z'))
    expect((await db.workLog.findUniqueOrThrow({ where: { companyId_id: { companyId: CO, id: W.w5 } } })).rev).toBe(5)
    const deleted = await db.client.findUniqueOrThrow({ where: { companyId_id: { companyId: CO, id: '6a4c8e2b-0d9f-4b1e-a3c5-7e9f1b3d5c86' } } })
    expect(deleted).toMatchObject({ isActive: false, deletedAt: new Date('2026-09-01T07:00:00Z'), rev: 2 })
    const lines = await db.invoiceLine.findMany({ where: { companyId: CO, invoiceId: INV1 }, orderBy: { sortOrder: 'asc' } })
    expect(lines.map((l) => [l.workLogId, l.amountPaise])).toEqual([
      [W.w1, 1_275_000n],
      [W.w2, 1_125_000n],
    ])
  })

  it('numbers the change feed per company in (serverUpdatedAt, document ID) order', async () => {
    await run({ fresh: true })
    const rows = await env.db.$queryRawUnsafe<{ id: string; seq: bigint }[]>(
      SYNC_TABLES.map((t) => `SELECT id, sync_seq AS seq FROM ${t} WHERE company_id = $1`).join(' UNION ALL ') + ' ORDER BY seq',
      CO,
    )
    // Expected order straight from the fixture's serverUpdatedAt (ms, then ns) and IDs.
    const accepted: { id: string; ms: number; ns: number }[] = []
    for (const c of ['clients', 'sites', 'machines', 'operators', 'petrolPumps', 'workLogs', 'fuelEntries', 'invoices', 'payments', 'auditLogs']) {
      for (const d of await source(`companies/*/${c}`)) {
        if (!d.path.startsWith(`companies/${CO}/`) || d.id === W.orphan || d.id === W.bad) continue
        const t = d.data.serverUpdatedAt as { ms: number; ns?: number }
        accepted.push({ id: d.id, ms: t.ms, ns: t.ns ?? 0 })
      }
    }
    accepted.sort((a, b) => a.ms - b.ms || a.ns - b.ns || (a.id < b.id ? -1 : 1))
    expect(rows.map((r) => r.id)).toEqual(accepted.map((a) => a.id))
    expect(rows.map((r) => Number(r.seq))).toEqual(accepted.map((_, i) => i + 1))

    // Same millisecond: nanoseconds first (invoice), then document ID (logs, then the audit entry).
    const seq = Object.fromEntries(rows.map((r) => [r.id, r.seq]))
    expect(seq[INV1] < seq[W.w1] && seq[W.w1] < seq[W.w2] && seq[W.w2] < seq[AUDIT_LOG_FINALIZE]).toBe(true)
    expect(await env.db.companySyncState.findUniqueOrThrow({ where: { companyId: CO } })).toMatchObject({ seq: 23n })
    expect(await env.db.companySyncState.findUniqueOrThrow({ where: { companyId: CO2 } })).toMatchObject({ seq: 0n })
  })
})

describe('import: repeatable', () => {
  it('a second run changes nothing, and keeps a password set in between', async () => {
    await run({ fresh: true })
    await env.db.user.update({ where: { id: U.owner }, data: { passwordHash: await hashPassword(PASSWORD) } })
    const before = await dumpAll()
    const again = await run()
    expect(again.ok).toBe(true)
    expect(await dumpAll()).toEqual(before)
    await expect(run({ fresh: true })).rejects.toThrow(FatalImportError)
  })

  it('dry run validates and reconciles, then rolls everything back', async () => {
    const report = await run({ dryRun: true })
    expect(report).toMatchObject({ mode: 'dry-run', reconciled: true })
    expect(report.ok).toBe(true)
    expect(report.totals.find((t) => t.companyId === CO)!.metrics.invoiceTotalPaise.database).toBe('4470000')
    expect(report.problems.filter((p) => p.severity === 'error')).toHaveLength(5)
    const counts = Object.values(await dumpAll()).map((rows) => rows.length)
    expect(counts.every((n) => n === 0)).toBe(true)
  })

  it('rows the export does not contain are kept after the imported ones and fail reconciliation', async () => {
    await run({ fresh: true })
    const extra = { ...(await source('companies/*/clients')).find((d) => d.id === CLIENT)!.data }
    const data = { ...business(extra), id: 'client-created-after-export', name: 'New client' } as Json
    await env.db.$transaction((tx) =>
      saveRecord(tx as Tx, 'clients' as CollectionName, data, { rev: 1, syncSeq: 24n, serverUpdatedAt: new Date(), pushedBy: U.owner, deviceId: null }),
    )
    const again = await run()
    expect(again.ok).toBe(false)
    expect(again.failures.join('\n')).toContain('clients: 1 row(s) of the imported companies are not in the export')
    expect(again.problems.some((p) => p.code === 'target_only')).toBe(true)
    const row = await env.db.client.findUniqueOrThrow({ where: { companyId_id: { companyId: CO, id: 'client-created-after-export' } } })
    expect(row.syncSeq).toBe(24n)
    expect(await env.db.companySyncState.findUniqueOrThrow({ where: { companyId: CO } })).toMatchObject({ seq: 24n })
  })
})

describe('import: the API on imported data', () => {
  const login = (email: string, password: string) => env.request.post('/api/v1/auth/login').send({ email, password, client: 'mobile' })

  it('migrated users have no password until they reset it', async () => {
    await run({ fresh: true })
    const before = await login('ravi.patil@saiearthmovers.in', PASSWORD)
    expect(before.status).toBe(401)
    expect(before.body.error.reason).toBe('invalid_credentials')

    await env.request.post('/api/v1/auth/forgot-password').send({ email: 'ravi.patil@saiearthmovers.in' }).expect(204)
    const link = /https:\S+/.exec(env.mailer.sent.at(-1)!.text)![0]
    const token = new URL(link).searchParams.get('token')
    await env.request.post('/api/v1/auth/reset-password').send({ token, password: 'my new password 1' }).expect(204)
    expect((await login('ravi.patil@saiearthmovers.in', 'my new password 1')).status).toBe(200)
  })

  it('sync pull returns the source records unchanged, and new pushes continue the change feed', async () => {
    await run({ fresh: true })
    // A fixed moment inside the imported license's validity (undone in onTestFinished).
    const shift = Date.parse('2026-11-02T06:00:00Z') - env.clock.now().getTime()
    env.clock.advance(shift)
    onTestFinished(() => env.clock.advance(-shift))
    await env.db.user.update({ where: { id: U.owner }, data: { passwordHash: await hashPassword(PASSWORD) } })
    const auth = `Bearer ${await tokenFor(env, U.owner)}`
    const pull = async (c: string) => {
      const res = await env.request.get(`/api/v1/companies/${CO}/sync/${c}?limit=500`).set('Authorization', auth)
      expect(res.status, JSON.stringify(res.body)).toBe(200)
      return res.body.items as { id: string; rev: number; cursor: string; data: Json }[]
    }

    const logs = await pull('workLogs')
    expect(logs.map((i) => i.id)).toEqual([W.w1, W.w2, W.w5, W.w4, W.w3])
    const src = new Map((await source('companies/*/workLogs')).map((d) => [d.id, d.data]))
    for (const item of logs) {
      expect(item.rev).toBe(src.get(item.id)!.rev)
      expect(item.data).toEqual(business(src.get(item.id)!))
    }
    for (const c of ['clients', 'sites', 'machines', 'operators', 'petrolPumps', 'fuelEntries', 'invoices', 'payments', 'auditLogs']) {
      const docs = (await source(`companies/*/${c}`)).filter((d) => d.path.startsWith(`companies/${CO}/`))
      const items = await pull(c)
      expect(items.length, c).toBe(docs.length)
      for (const item of items) expect(item.data, `${c}/${item.id}`).toEqual(business(docs.find((d) => d.id === item.id)!.data))
    }

    // The owner's phone (imported device, imported license) edits an imported client.
    const client = (await pull('clients')).find((i) => i.id === CLIENT)!
    const res = await env.request
      .put(`/api/v1/companies/${CO}/sync/clients/${CLIENT}`)
      .set('Authorization', auth)
      .set('X-Device-Id', DEV_OWNER)
      .send({ baseRev: client.rev, data: { ...client.data, phone: '9000000000', version: 4 } })
    expect(res.status, JSON.stringify(res.body)).toBe(200)
    expect(res.body).toEqual({ rev: 4 })
    const after = await pull('clients')
    expect(after.at(-1)).toMatchObject({ id: CLIENT, rev: 4, cursor: `24|${CLIENT}` })
  })
})

describe('fixture', () => {
  it('covers every collection kind of the Firestore app', async () => {
    const manifest = JSON.parse(await readFile(join(FIXTURE, 'manifest.json'), 'utf8'))
    const kinds = Object.keys(manifest.counts)
    for (const k of [
      '__auth__',
      'developerAdmins',
      'companies',
      'auditEvents',
      'rateLimits',
      ...['companyUsers', 'licenses', 'authorizedDevices', 'deviceReplacementRequests', 'invoiceNumbers', 'counters'].map((c) => `companies/*/${c}`),
      ...['clients', 'sites', 'machines', 'operators', 'petrolPumps', 'workLogs', 'fuelEntries', 'invoices', 'payments', 'auditLogs'].map((c) => `companies/*/${c}`),
    ]) {
      expect(kinds).toContain(k)
    }
    expect((await readdir(FIXTURE)).filter((f) => f.endsWith('.ndjson'))).toHaveLength(kinds.length)
  })
})
