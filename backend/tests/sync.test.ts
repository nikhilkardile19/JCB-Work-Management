import { beforeEach, describe, expect, it } from 'vitest'
import { DAY, seedCompany } from './helpers/factories.js'
import { line, record, syncHelpers } from './helpers/sync.js'
import { useTestApp } from './helpers/testApp.js'

/**
 * Port of firebase/tests/sync.rules.test.js: every scenario the Firestore
 * rules enforced, now enforced by the API, plus the guarantees PostgreSQL adds.
 */
const env = useTestApp()
const { push, pull, existing, seedRefs } = syncHelpers(env)

const ok = (res: { status: number; body: unknown }) => expect(res.status, JSON.stringify(res.body)).toBe(200)
const refused = (res: { status: number; body: { error?: { code: string } } }, status = 403) => {
  expect(res.status, JSON.stringify(res.body)).toBe(status)
}

beforeEach(async () => {
  await seedCompany(env.db)
  await seedRefs()
})

const workLog = (o = {}) => o

describe('sync metadata and concurrency', () => {
  it('accepts a correctly formed first write and records who pushed it', async () => {
    const res = await push('owner', 'clients', 'c1')
    ok(res)
    expect(res.body).toEqual({ rev: 1 })
    const row = await env.db.client.findUniqueOrThrow({ where: { companyId_id: { companyId: 'co', id: 'c1' } } })
    expect(row).toMatchObject({ pushedBy: 'owner', deviceId: 'dev-owner', rev: 1 })
  })

  it('revision must advance by exactly one (no silent overwrite)', async () => {
    await existing('clients', 'c1', { name: 'Server copy' }, 3)
    const stale = await push('owner', 'clients', 'c1', {}, { baseRev: 2 })
    expect(stale.status).toBe(409)
    expect(stale.body.error.code).toBe('conflict')
    expect(stale.body.serverRev).toBe(3)
    expect(stale.body.serverData).toMatchObject({ id: 'c1', name: 'Server copy' })
    expect((await push('owner', 'clients', 'c1', {}, { baseRev: 4 })).status).toBe(409)
    const res = await push('owner', 'clients', 'c1', {}, { baseRev: 3 })
    ok(res)
    expect(res.body.rev).toBe(4)
  })

  it('a phone that never saw the record gets the server copy back', async () => {
    await existing('clients', 'c1')
    const res = await push('owner', 'clients', 'c1')
    expect(res.status).toBe(409)
    expect(res.body.serverRev).toBe(1)
  })

  it('baseRev 0 means "does not exist yet"', async () => {
    ok(await push('owner', 'clients', 'c1', {}, { baseRev: 0 }))
    const gone = await push('owner', 'clients', 'c2', {}, { baseRev: 5 })
    expect(gone.status).toBe(409)
    expect(gone.body).toMatchObject({ serverRev: 0, serverData: {} })
  })

  it('record id and company must match the URL; sync metadata cannot be sent', async () => {
    refused(await push('owner', 'clients', 'c1', {}, { data: record('clients', 'other') }), 400)
    refused(await push('owner', 'clients', 'c1', {}, { data: record('clients', 'c1', {}, 'co-x') }), 400)
    refused(await push('owner', 'clients', 'c1', { pushedBy: 'someone-else' }), 400)
    refused(await push('owner', 'clients', 'c1', { rev: 99 }), 400)
  })

  it('records can never be hard-deleted', async () => {
    await existing('clients', 'c1')
    const res = await env.request.delete('/api/v1/companies/co/sync/clients/c1')
    expect(res.status).toBe(404)
  })

  it('inactive companies cannot write business data (whole pass refused)', async () => {
    await seedCompany(env.db, { id: 'pending-co', status: 'pending', members: { owner: 'owner' } })
    const res = await push('owner', 'clients', 'c1', {}, { company: 'pending-co' })
    refused(res)
    expect(res.body.error.reason).toBe('company_inactive')
  })

  it('concurrent pushes against the same revision: exactly one wins', async () => {
    await existing('clients', 'c1')
    const results = await Promise.all([1, 2, 3, 4].map((i) => push('owner', 'clients', 'c1', { name: `Name ${i}` }, { baseRev: 1 })))
    expect(results.map((r) => r.status).sort()).toEqual([200, 409, 409, 409])
  })
})

describe('tenant isolation', () => {
  beforeEach(async () => {
    await seedCompany(env.db, { id: 'co-b', members: { bob: 'owner' } })
    await existing('clients', 'c1')
  })

  it("company B can't read or write company A's records", async () => {
    const read = await pull('bob', 'clients')
    refused(read)
    const write = await push('bob', 'clients', 'c2')
    refused(write)
    expect(write.body.error.reason).toBe('not_member')
  })

  it("the same ID in another company is a different record", async () => {
    ok(await push('bob', 'clients', 'c1', { name: 'Bob client' }, { company: 'co-b' }))
    const mine = await pull('owner', 'clients')
    expect(mine.body.items.find((i: { id: string }) => i.id === 'c1').data.name).toBe('Patil')
  })

  it("records can't reference another company's records (composite foreign keys)", async () => {
    const res = await push('bob', 'sites', 's1', { clientId: 'c1' }, { company: 'co-b' })
    refused(res, 400)
    expect(res.body.error.message).toMatch(/not on the server yet/)
  })

  it('every member can read masters', async () => {
    const res = await pull('op', 'clients')
    ok(res)
    expect(res.body.items.map((i: { id: string }) => i.id)).toContain('c1')
  })
})

describe('masters', () => {
  it('only owner/admin can write masters, with a valid name', async () => {
    ok(await push('admin', 'machines', 'm1', { name: 'JCB 3DX' }))
    for (const uid of ['mgr', 'op', 'acc']) refused(await push(uid, 'machines', `m-${uid}`, { name: 'X' }))
    refused(await push('owner', 'machines', 'm2', { name: '' }), 400)
  })

  it('soft deletion is an ordinary update', async () => {
    await existing('operators', 'o1')
    ok(await push('owner', 'operators', 'o1', { deletedAt: 5, isActive: false }, { baseRev: 1 }))
  })

  it('rejects unknown fields and out-of-range numbers without a server error', async () => {
    refused(await push('owner', 'clients', 'c9', { favouriteColour: 'red' }), 400)
    refused(await push('owner', 'machines', 'm9', { initialMeterReading: 2 ** 40 }), 400)
    refused(await push('owner', 'clients', 'c9', { createdAt: 'yesterday' }), 400)
  })
})

describe('work logs', () => {
  it('validates hours = end − start and end ≥ start', async () => {
    ok(await push('op', 'workLogs', 'w1', workLog()))
    refused(await push('op', 'workLogs', 'w2', workLog({ workingHours: 999 })), 400)
    refused(await push('op', 'workLogs', 'w3', workLog({ endReading: 900, workingHours: -100 })), 400)
  })

  it('manual entries need a reason', async () => {
    refused(await push('op', 'workLogs', 'w1', workLog({ manualReason: null })), 400)
    ok(await push('op', 'workLogs', 'w2', workLog({ entryMode: 'photo', manualReason: null })))
  })

  it("operators can't approve, or write other people's logs", async () => {
    refused(await push('op', 'workLogs', 'w1', workLog({ status: 'approved' })))
    refused(await push('op2', 'workLogs', 'w2', workLog()))
    await existing('workLogs', 'w3', workLog())
    refused(await push('op2', 'workLogs', 'w3', workLog({ createdBy: 'op2' }), { baseRev: 1 }))
  })

  it('managers approve', async () => {
    await existing('workLogs', 'w1', workLog())
    ok(await push('mgr', 'workLogs', 'w1', workLog({ status: 'approved' }), { baseRev: 1 }))
  })

  it('accounts may only change invoice reservation/state', async () => {
    await existing('workLogs', 'w1', workLog({ status: 'approved' }))
    ok(await push('acc', 'workLogs', 'w1', workLog({ status: 'invoiced', invoiceId: 'i1' }), { baseRev: 1 }))
    await existing('workLogs', 'w2', workLog({ status: 'approved' }))
    refused(await push('acc', 'workLogs', 'w2', workLog({ status: 'approved', endReading: 2000, workingHours: 1000 }), { baseRev: 1 }))
  })

  it('accounts cannot approve work by flipping the status', async () => {
    await existing('workLogs', 'w1', workLog({ status: 'submitted' }))
    refused(await push('acc', 'workLogs', 'w1', workLog({ status: 'approved' }), { baseRev: 1 }))
    await existing('workLogs', 'w2', workLog({ status: 'rejected' }))
    refused(await push('acc', 'workLogs', 'w2', workLog({ status: 'invoiced', invoiceId: 'i1' }), { baseRev: 1 }))
  })

  it('operators cannot rewrite their own approved or invoiced logs', async () => {
    await existing('workLogs', 'w1', workLog({ status: 'approved' }))
    refused(await push('op', 'workLogs', 'w1', workLog({ status: 'submitted', endReading: 2500, workingHours: 1500 }), { baseRev: 1 }))
    refused(await push('op', 'workLogs', 'w1', workLog({ status: 'cancelled' }), { baseRev: 1 }))
    await existing('workLogs', 'w2', workLog({ status: 'invoiced', invoiceId: 'i1' }))
    refused(await push('op', 'workLogs', 'w2', workLog({ status: 'cancelled', invoiceId: 'i1' }), { baseRev: 1 }))
    // Their drafts and rejected logs stay editable.
    await existing('workLogs', 'w3', workLog({ status: 'rejected' }))
    ok(await push('op', 'workLogs', 'w3', workLog({ status: 'submitted', endReading: 1900, workingHours: 900 }), { baseRev: 1 }))
    await existing('workLogs', 'w4', workLog({ status: 'draft' }))
    ok(await push('op', 'workLogs', 'w4', workLog({ status: 'cancelled' }), { baseRev: 1 }))
  })

  it('operators cannot reserve logs for invoices', async () => {
    refused(await push('op', 'workLogs', 'w1', workLog({ status: 'draft', invoiceId: 'i1' })))
  })

  it('managers cannot change approved or invoiced logs', async () => {
    await existing('workLogs', 'w1', workLog({ status: 'approved' }))
    refused(await push('mgr', 'workLogs', 'w1', workLog({ status: 'approved', endReading: 2500, workingHours: 1500 }), { baseRev: 1 }))
    refused(await push('mgr', 'workLogs', 'w1', workLog({ status: 'invoiced', invoiceId: 'i1' }), { baseRev: 1 }))
    await existing('workLogs', 'w2', workLog({ status: 'invoiced', invoiceId: 'i1' }))
    refused(await push('mgr', 'workLogs', 'w2', workLog({ status: 'cancelled', invoiceId: 'i1' }), { baseRev: 1 }))
    // A manager's own entry lands approved (product decision #6).
    ok(await push('mgr', 'workLogs', 'w3', workLog({ createdBy: 'mgr', status: 'approved' })))
  })

  it('invoiced logs change only through their invoice, even for owners', async () => {
    await existing('workLogs', 'w1', workLog({ status: 'invoiced', invoiceId: 'i1' }))
    refused(await push('owner', 'workLogs', 'w1', workLog({ status: 'invoiced', invoiceId: 'i1', endReading: 2500, workingHours: 1500 }), { baseRev: 1 }))
    refused(await push('owner', 'workLogs', 'w1', workLog({ status: 'cancelled', invoiceId: 'i1' }), { baseRev: 1 }))
    // Cancelling the invoice releases the log back to approved.
    ok(await push('owner', 'workLogs', 'w1', workLog({ status: 'approved', invoiceId: null }), { baseRev: 1 }))
    // Owners still correct approved, unbilled logs.
    await existing('workLogs', 'w2', workLog({ status: 'approved' }))
    ok(await push('owner', 'workLogs', 'w2', workLog({ status: 'approved', endReading: 1900, workingHours: 900 }), { baseRev: 1 }))
  })

  it('keeps location doubles and dates exact through a round trip', async () => {
    const data = record('workLogs', 'w1', { startLat: 18.5204, startLng: 73.8567, startAccuracy: 5, workDate: '2026-02-28' })
    ok(await push('op', 'workLogs', 'w1', {}, { data }))
    const back = (await pull('op', 'workLogs')).body.items.find((i: { id: string }) => i.id === 'w1').data
    expect(back).toEqual(data)
    refused(await push('op', 'workLogs', 'w2', { workDate: '2026-02-30' }), 400)
  })
})

describe('fuel', () => {
  it('total must equal litres × price (half-up paise)', async () => {
    ok(await push('op', 'fuelEntries', 'f1'))
    refused(await push('op', 'fuelEntries', 'f2', { totalPaise: 260000 }), 400)
    refused(await push('op', 'fuelEntries', 'f3', { litresCl: 0, totalPaise: 0 }), 400)
  })

  it('operators edit only their own entries; accounts cannot record fuel', async () => {
    await existing('fuelEntries', 'f1')
    refused(await push('op2', 'fuelEntries', 'f1', { createdBy: 'op2' }, { baseRev: 1 }))
    ok(await push('owner', 'fuelEntries', 'f1', {}, { baseRev: 1 }))
    refused(await push('acc', 'fuelEntries', 'f2', { createdBy: 'acc' }))
  })
})

describe('invoices and payments', () => {
  const issue = (invoiceId: string, invoiceNumber: string) =>
    env.db.issuedInvoiceNumber.create({ data: { companyId: 'co', invoiceId, invoiceNumber, financialYear: '2026-27', issuedBy: 'acc' } })
  const fin = (o = {}) => ({ status: 'finalized', invoiceNumber: 'SAI/2026-27/0001', ...o })

  it('drafts carry no number; billing roles only', async () => {
    ok(await push('acc', 'invoices', 'i1'))
    refused(await push('acc', 'invoices', 'i2', { invoiceNumber: 'SAI/2026-27/0099' }))
    refused(await push('mgr', 'invoices', 'i3'))
    refused(await push('op', 'invoices', 'i4'))
    refused(await push('acc', 'invoices', 'i5', { totalPaise: 5 }), 400)
    refused(await push('acc', 'invoices', 'i6', { discountPaise: -500, totalPaise: 1500 }), 400)
    refused(await push('acc', 'invoices', 'i7', { discountPaise: 2000, totalPaise: -1000 }), 400)
  })

  it('lines must add up: amount = hours × rate (half-up), subtotal = Σ amounts', async () => {
    refused(await push('acc', 'invoices', 'i1', { lines: [line('i1', 'w-billed', { amountPaise: 999 })] }), 400)
    refused(await push('acc', 'invoices', 'i2', { subtotalPaise: 2000, totalPaise: 2000 }), 400)
    const odd = line('i3', 'w-billed', { workingHours: 33, endReading: 1033, ratePaise: 150050, amountPaise: 49517 })
    ok(await push('acc', 'invoices', 'i3', { lines: [odd], subtotalPaise: 49517, totalPaise: 49517 }))
  })

  it('stores lines in invoice_lines and returns them inline', async () => {
    ok(await push('acc', 'invoices', 'i1'))
    expect(await env.db.invoiceLine.count({ where: { invoiceId: 'i1' } })).toBe(1)
    const pulled = (await pull('acc', 'invoices')).body.items[0]
    expect(pulled.data).toEqual(record('invoices', 'i1'))
  })

  it('finalizing requires the server-issued number', async () => {
    await existing('invoices', 'i1')
    refused(await push('acc', 'invoices', 'i1', fin(), { baseRev: 1 }))
    await issue('i1', 'SAI/2026-27/0001')
    refused(await push('acc', 'invoices', 'i1', fin({ invoiceNumber: 'SAI/2026-27/0002' }), { baseRev: 1 }))
    ok(await push('acc', 'invoices', 'i1', fin(), { baseRev: 1 }))
  })

  it('a work log can be on only one finalized invoice', async () => {
    await existing('invoices', 'i1', fin())
    await existing('invoices', 'i2')
    await issue('i2', 'SAI/2026-27/0002')
    const res = await push('acc', 'invoices', 'i2', fin({ invoiceNumber: 'SAI/2026-27/0002' }), { baseRev: 1 })
    refused(res, 400)
    expect(res.body.error.message).toMatch(/already billed on invoice SAI\/2026-27\/0001/)
  })

  it('finalized invoices are immutable except audited cancellation', async () => {
    await existing('invoices', 'i1', fin())
    refused(await push('owner', 'invoices', 'i1', fin({ totalPaise: 1, subtotalPaise: 1 }), { baseRev: 1 }))
    refused(await push('owner', 'invoices', 'i1', { status: 'draft', invoiceNumber: null }, { baseRev: 1 }))
    refused(await push('owner', 'invoices', 'i1', fin({ status: 'cancelled' }), { baseRev: 1 }))
    ok(await push('owner', 'invoices', 'i1', fin({ status: 'cancelled', cancelReason: 'Wrong rate', cancelledAt: 5, cancelledBy: 'owner' }), { baseRev: 1 }))
  })

  it('re-sending identical content is harmless', async () => {
    await existing('invoices', 'i1', fin())
    ok(await push('owner', 'invoices', 'i1', fin({ updatedAt: 99, version: 2 }), { baseRev: 1 }))
  })

  describe('payments', () => {
    beforeEach(async () => {
      await existing('invoices', 'i-fin', fin({ invoiceNumber: 'SAI/2026-27/0007', lines: [line('i-fin', 'w-billed', { workingHours: 1000, endReading: 2000, amountPaise: 10000 })], subtotalPaise: 10000, totalPaise: 10000 }))
    })

    it('positive on create; afterwards only reversal with a reason', async () => {
      refused(await push('acc', 'payments', 'p0', { amountPaise: 0 }), 400)
      ok(await push('acc', 'payments', 'p1'))
      await existing('payments', 'p2')
      refused(await push('acc', 'payments', 'p2', { amountPaise: 9000 }, { baseRev: 1 }))
      ok(await push('acc', 'payments', 'p2', { reversedAt: 7, reversedBy: 'acc', reverseReason: 'Bounced' }, { baseRev: 1 }))
      refused(await push('op', 'payments', 'p3', { amountPaise: 100 }))
    })

    it('blocks overpayment; reversed payments do not count', async () => {
      ok(await push('acc', 'payments', 'p1', { amountPaise: 6000 }))
      refused(await push('acc', 'payments', 'p2', { amountPaise: 5000 }), 400)
      await existing('payments', 'p3', { amountPaise: 4000, reversedAt: 3, reversedBy: 'acc', reverseReason: 'Bounced' })
      ok(await push('acc', 'payments', 'p4', { amountPaise: 4000 }))
    })

    it('only on finalized invoices', async () => {
      await existing('invoices', 'i-draft')
      refused(await push('acc', 'payments', 'p1', { invoiceId: 'i-draft' }), 400)
    })
  })

  it("operators can't read billing; managers can", async () => {
    await existing('invoices', 'i1')
    refused(await pull('op', 'invoices'))
    const mgr = await pull('mgr', 'invoices')
    ok(mgr)
    expect(mgr.body.items).toHaveLength(1)
  })

  it("a conflict never reveals billing data to roles that can't read it", async () => {
    await existing('invoices', 'i1')
    const res = await push('op', 'invoices', 'i1', {}, { baseRev: 7 })
    refused(res)
    expect(res.body.serverData).toBeUndefined()
  })
})

describe('history', () => {
  it('audit entries are append-only', async () => {
    ok(await push('op', 'auditLogs', 'a1'))
    await existing('auditLogs', 'a2')
    refused(await push('owner', 'auditLogs', 'a2', { action: 'tampered' }, { baseRev: 1 }))
  })
})

describe('device and license enforcement', () => {
  const reason = (res: { body: { error?: { reason?: string } } }) => res.body.error?.reason

  it('writes need an active device registered to the same user', async () => {
    expect(reason(await push('owner', 'clients', 'c1', {}, { deviceId: 'unknown-device' }))).toBe('device_not_licensed')
    expect(reason(await push('owner', 'clients', 'c2', {}, { deviceId: 'dev-admin' }))).toBe('device_not_licensed')
    ok(await push('owner', 'clients', 'c3'))
  })

  it('a revoked device is cut off', async () => {
    await env.db.device.update({ where: { companyId_id: { companyId: 'co', id: 'dev-owner' } }, data: { status: 'revoked' } })
    expect(reason(await push('owner', 'clients', 'c1'))).toBe('device_not_licensed')
  })

  it('suspended, expired or not-yet-started licenses block writes', async () => {
    const lic = (data: object) => env.db.license.update({ where: { id: 'lic-co' }, data })
    await lic({ status: 'suspended' })
    expect(reason(await push('owner', 'clients', 'c1'))).toBe('device_not_licensed')
    await lic({ status: 'active', validUntil: new Date(Date.now() - 1000) })
    expect(reason(await push('owner', 'clients', 'c2'))).toBe('device_not_licensed')
    await lic({ validFrom: new Date(Date.now() + DAY), validUntil: new Date(Date.now() + 2 * DAY) })
    expect(reason(await push('owner', 'clients', 'c3'))).toBe('device_not_licensed')
  })

  it('reads of existing data keep working while the license is suspended', async () => {
    await existing('clients', 'c1')
    await env.db.license.update({ where: { id: 'lic-co' }, data: { status: 'suspended' } })
    ok(await pull('owner', 'clients'))
  })

  it('disabled members lose access immediately', async () => {
    await env.db.companyMember.update({ where: { companyId_userId: { companyId: 'co', userId: 'op' } }, data: { status: 'disabled' } })
    expect(reason(await push('op', 'workLogs', 'w1'))).toBe('not_member')
    refused(await pull('op', 'clients'))
  })

  it('there is no sync path to licenses, devices or other server-owned data', async () => {
    for (const c of ['licenses', 'devices', 'companyUsers', 'invoiceNumbers', 'auditEvents']) {
      const res = await env.request.put(`/api/v1/companies/co/sync/${c}/x`).send({ baseRev: null, data: {} })
      expect([400, 401]).toContain(res.status)
    }
  })
})

describe('pull feed', () => {
  it('returns changes oldest first, pages with the cursor, and moves updated records to the end', async () => {
    for (const id of ['a', 'b', 'c']) ok(await push('owner', 'operators', id))
    const page1 = await pull('op', 'operators', { limit: 2 })
    expect(page1.body.items.map((i: { id: string }) => i.id)).toEqual(['a', 'b'])
    const page2 = await pull('op', 'operators', { after: page1.body.items[1].cursor })
    expect(page2.body.items.map((i: { id: string }) => i.id)).toEqual(['c'])
    ok(await push('owner', 'operators', 'a', { name: 'Renamed' }, { baseRev: 1 }))
    const page3 = await pull('op', 'operators', { after: page2.body.items[0].cursor })
    expect(page3.body.items).toHaveLength(1)
    expect(page3.body.items[0]).toMatchObject({ id: 'a', rev: 2, data: { name: 'Renamed' } })
    expect(page3.body.items[0].cursor).toMatch(/^\d+\|a$/)
  })

  it('rejects a malformed cursor', async () => {
    refused(await pull('op', 'operators', { after: 'not-a-cursor' }), 400)
  })
})
