import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing'
import { deleteDoc, doc, getDoc, serverTimestamp, setDoc, Timestamp, updateDoc } from 'firebase/firestore'
import { readFileSync } from 'node:fs'
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest'

let env

const members = { owner: 'owner', admin: 'admin', mgr: 'manager', op: 'operator', op2: 'operator', acc: 'accounts' }

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-jcb-sync',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  })
})
afterAll(() => env.cleanup())

const DAY = 86_400_000

async function seedCompany(id = 'co', status = 'active', who = members) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore()
    await setDoc(doc(db, 'companies', id), { id, status, ownerUid: 'owner', invoicePrefix: 'SAI' })
    await setDoc(doc(db, 'companies', id, 'licenses', 'lic1'), {
      status: 'active',
      validFrom: Timestamp.fromMillis(Date.now() - DAY),
      validUntil: Timestamp.fromMillis(Date.now() + 365 * DAY),
      maxDevices: 10,
    })
    for (const [uid, role] of Object.entries(who)) {
      await setDoc(doc(db, 'companies', id, 'companyUsers', uid), { uid, companyId: id, role, status: 'active' })
      await setDoc(doc(db, 'companies', id, 'authorizedDevices', `dev-${uid}`), { deviceId: `dev-${uid}`, licenseId: 'lic1', userId: uid, status: 'active' })
    }
  })
}

async function patch(path, data) {
  await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), ...path), data))
}

beforeEach(async () => {
  await env.clearFirestore()
  await seedCompany()
})

const as = (uid) => env.authenticatedContext(uid).firestore()

/** What the app's sync engine writes: business fields + sync metadata. */
function push(uid, collection, id, data, { rev = 1, company = 'co', deviceId = `dev-${uid}` } = {}) {
  return setDoc(doc(as(uid), 'companies', company, collection, id), {
    id,
    companyId: company,
    updatedAt: 1,
    updatedBy: uid,
    version: rev,
    ...data,
    rev,
    serverUpdatedAt: serverTimestamp(),
    pushedBy: uid,
    deviceId,
  })
}

/** Server state written without rules (as if pushed earlier). */
async function existing(collection, id, data, rev = 1) {
  await env.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), 'companies', 'co', collection, id), { id, companyId: 'co', rev, updatedAt: 1, updatedBy: 'x', version: rev, ...data }),
  )
}

const client = { name: 'Patil', isActive: true }
const workLog = (o = {}) => ({
  createdBy: 'op', status: 'submitted', entryMode: 'manual', manualReason: 'no camera',
  startReading: 1000, endReading: 1800, workingHours: 800, ...o,
})
const fuel = (o = {}) => ({ createdBy: 'op', litresCl: 2550, pricePerLitrePaise: 10235, totalPaise: 260993, ...o })
const invoice = (o = {}) => ({ status: 'draft', invoiceNumber: null, subtotalPaise: 1000, discountPaise: 0, totalPaise: 1000, ...o })

describe('sync metadata and concurrency', () => {
  it('accepts a correctly formed first write', async () => {
    await assertSucceeds(push('owner', 'clients', 'c1', client))
  })

  it('revision must advance by exactly one (no silent overwrite)', async () => {
    await existing('clients', 'c1', client, 3)
    await assertFails(push('owner', 'clients', 'c1', client, { rev: 3 }))
    await assertFails(push('owner', 'clients', 'c1', client, { rev: 5 }))
    await assertSucceeds(push('owner', 'clients', 'c1', client, { rev: 4 }))
  })

  it('doc id, company and pushedBy must be truthful', async () => {
    await assertFails(setDoc(doc(as('owner'), 'companies', 'co', 'clients', 'c1'), { ...client, id: 'other', companyId: 'co', rev: 1, serverUpdatedAt: serverTimestamp(), pushedBy: 'owner' }))
    await assertFails(setDoc(doc(as('owner'), 'companies', 'co', 'clients', 'c1'), { ...client, id: 'c1', companyId: 'co', rev: 1, serverUpdatedAt: serverTimestamp(), pushedBy: 'someone-else' }))
  })

  it('records can never be hard-deleted', async () => {
    await existing('clients', 'c1', client)
    await assertFails(deleteDoc(doc(as('owner'), 'companies', 'co', 'clients', 'c1')))
  })

  it('inactive companies cannot write business data', async () => {
    await seedCompany('pending-co', 'pending', { owner: 'owner' })
    await assertFails(push('owner', 'clients', 'c1', client, { company: 'pending-co' }))
  })
})

describe('tenant isolation', () => {
  beforeEach(async () => {
    await seedCompany('co-b', 'active', { bob: 'owner' })
    await existing('clients', 'c1', client)
  })

  it("company B can't read or write company A's records", async () => {
    await assertFails(getDoc(doc(as('bob'), 'companies', 'co', 'clients', 'c1')))
    await assertFails(push('bob', 'clients', 'c2', client))
    await assertFails(push('bob', 'clients', 'c1', client, { company: 'co-b', rev: 1 }).then(() => getDoc(doc(as('bob'), 'companies', 'co', 'clients', 'c1'))))
  })

  it('every member can read masters', async () => {
    await assertSucceeds(getDoc(doc(as('op'), 'companies', 'co', 'clients', 'c1')))
  })
})

describe('masters', () => {
  it('only owner/admin can write masters, with a valid name', async () => {
    await assertSucceeds(push('admin', 'machines', 'm1', { name: 'JCB 3DX', isActive: true }))
    for (const uid of ['mgr', 'op', 'acc']) {
      await assertFails(push(uid, 'machines', `m-${uid}`, { name: 'X', isActive: true }))
    }
    await assertFails(push('owner', 'machines', 'm2', { name: '', isActive: true }))
  })
})

describe('work logs', () => {
  it('validates hours = end − start and end ≥ start', async () => {
    await assertSucceeds(push('op', 'workLogs', 'w1', workLog()))
    await assertFails(push('op', 'workLogs', 'w2', workLog({ workingHours: 999 })))
    await assertFails(push('op', 'workLogs', 'w3', workLog({ endReading: 900, workingHours: -100 })))
  })

  it('manual entries need a reason', async () => {
    await assertFails(push('op', 'workLogs', 'w1', workLog({ manualReason: null })))
    await assertSucceeds(push('op', 'workLogs', 'w2', workLog({ entryMode: 'photo', manualReason: null })))
  })

  it("operators can't approve, or write other people's logs", async () => {
    await assertFails(push('op', 'workLogs', 'w1', workLog({ status: 'approved' })))
    await assertFails(push('op2', 'workLogs', 'w2', workLog()))
    await existing('workLogs', 'w3', workLog())
    await assertFails(push('op2', 'workLogs', 'w3', workLog({ createdBy: 'op2' }), { rev: 2 }))
  })

  it('managers approve', async () => {
    await existing('workLogs', 'w1', workLog())
    await assertSucceeds(push('mgr', 'workLogs', 'w1', workLog({ status: 'approved' }), { rev: 2 }))
  })

  it('accounts may only change invoice reservation/state', async () => {
    await existing('workLogs', 'w1', workLog({ status: 'approved', invoiceId: null }))
    await assertSucceeds(push('acc', 'workLogs', 'w1', workLog({ status: 'invoiced', invoiceId: 'i1' }), { rev: 2 }))
    await existing('workLogs', 'w2', workLog({ status: 'approved', invoiceId: null }))
    await assertFails(push('acc', 'workLogs', 'w2', workLog({ status: 'approved', endReading: 2000, workingHours: 1000 }), { rev: 2 }))
  })

  // Sprint 11 security review findings.
  it('accounts cannot approve work by flipping the status', async () => {
    await existing('workLogs', 'w1', workLog({ status: 'submitted', invoiceId: null }))
    await assertFails(push('acc', 'workLogs', 'w1', workLog({ status: 'approved', invoiceId: null }), { rev: 2 }))
    await existing('workLogs', 'w2', workLog({ status: 'rejected', invoiceId: null }))
    await assertFails(push('acc', 'workLogs', 'w2', workLog({ status: 'invoiced', invoiceId: 'i1' }), { rev: 2 }))
  })

  it('operators cannot rewrite their own approved or invoiced logs', async () => {
    await existing('workLogs', 'w1', workLog({ status: 'approved' }))
    await assertFails(push('op', 'workLogs', 'w1', workLog({ status: 'submitted', endReading: 2500, workingHours: 1500 }), { rev: 2 }))
    await assertFails(push('op', 'workLogs', 'w1', workLog({ status: 'cancelled' }), { rev: 2 }))
    await existing('workLogs', 'w2', workLog({ status: 'invoiced', invoiceId: 'i1' }))
    await assertFails(push('op', 'workLogs', 'w2', workLog({ status: 'cancelled', invoiceId: 'i1' }), { rev: 2 }))
    // Their drafts and rejected logs stay editable.
    await existing('workLogs', 'w3', workLog({ status: 'rejected' }))
    await assertSucceeds(push('op', 'workLogs', 'w3', workLog({ status: 'submitted', endReading: 1900, workingHours: 900 }), { rev: 2 }))
    await existing('workLogs', 'w4', workLog({ status: 'draft' }))
    await assertSucceeds(push('op', 'workLogs', 'w4', workLog({ status: 'cancelled' }), { rev: 2 }))
  })

  it('operators cannot reserve logs for invoices', async () => {
    await assertFails(push('op', 'workLogs', 'w1', workLog({ status: 'draft', invoiceId: 'i1' })))
  })

  it('managers cannot change approved or invoiced logs', async () => {
    await existing('workLogs', 'w1', workLog({ status: 'approved' }))
    await assertFails(push('mgr', 'workLogs', 'w1', workLog({ status: 'approved', endReading: 2500, workingHours: 1500 }), { rev: 2 }))
    await assertFails(push('mgr', 'workLogs', 'w1', workLog({ status: 'invoiced', invoiceId: 'i1' }), { rev: 2 }))
    await existing('workLogs', 'w2', workLog({ status: 'invoiced', invoiceId: 'i1' }))
    await assertFails(push('mgr', 'workLogs', 'w2', workLog({ status: 'cancelled', invoiceId: 'i1' }), { rev: 2 }))
    // A manager's own entry lands approved (product decision #6).
    await assertSucceeds(push('mgr', 'workLogs', 'w3', workLog({ createdBy: 'mgr', status: 'approved' })))
  })

  it('invoiced logs change only through their invoice, even for owners', async () => {
    await existing('workLogs', 'w1', workLog({ status: 'invoiced', invoiceId: 'i1' }))
    await assertFails(push('owner', 'workLogs', 'w1', workLog({ status: 'invoiced', invoiceId: 'i1', endReading: 2500, workingHours: 1500 }), { rev: 2 }))
    await assertFails(push('owner', 'workLogs', 'w1', workLog({ status: 'cancelled', invoiceId: 'i1' }), { rev: 2 }))
    // Cancelling the invoice releases the log back to approved.
    await assertSucceeds(push('owner', 'workLogs', 'w1', workLog({ status: 'approved', invoiceId: null }), { rev: 2 }))
    // Owners still correct approved, unbilled logs.
    await existing('workLogs', 'w2', workLog({ status: 'approved', invoiceId: null }))
    await assertSucceeds(push('owner', 'workLogs', 'w2', workLog({ status: 'approved', invoiceId: null, endReading: 1900, workingHours: 900 }), { rev: 2 }))
  })
})

describe('fuel', () => {
  it('total must equal litres × price (half-up paise)', async () => {
    await assertSucceeds(push('op', 'fuelEntries', 'f1', fuel()))
    await assertFails(push('op', 'fuelEntries', 'f2', fuel({ totalPaise: 260000 })))
    await assertFails(push('op', 'fuelEntries', 'f3', fuel({ litresCl: 0, totalPaise: 0 })))
  })

  it('operators edit only their own entries; accounts cannot record fuel', async () => {
    await existing('fuelEntries', 'f1', fuel())
    await assertFails(push('op2', 'fuelEntries', 'f1', fuel({ createdBy: 'op2' }), { rev: 2 }))
    await assertSucceeds(push('owner', 'fuelEntries', 'f1', fuel(), { rev: 2 }))
    await assertFails(push('acc', 'fuelEntries', 'f2', fuel({ createdBy: 'acc' })))
  })
})

describe('invoices and payments', () => {
  it('drafts carry no number; billing roles only', async () => {
    await assertSucceeds(push('acc', 'invoices', 'i1', invoice()))
    await assertFails(push('acc', 'invoices', 'i2', invoice({ invoiceNumber: 'SAI/2026-27/0099' })))
    await assertFails(push('mgr', 'invoices', 'i3', invoice()))
    await assertFails(push('op', 'invoices', 'i4', invoice()))
    await assertFails(push('acc', 'invoices', 'i5', invoice({ totalPaise: 5 })))
    await assertFails(push('acc', 'invoices', 'i6', invoice({ discountPaise: -500, totalPaise: 1500 })))
    await assertFails(push('acc', 'invoices', 'i7', invoice({ discountPaise: 2000, totalPaise: -1000 })))
  })

  it('finalizing requires the server-issued number', async () => {
    await existing('invoices', 'i1', invoice())
    await assertFails(push('acc', 'invoices', 'i1', invoice({ status: 'finalized', invoiceNumber: 'SAI/2026-27/0001' }), { rev: 2 }))
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'companies', 'co', 'invoiceNumbers', 'i1'), { invoiceNumber: 'SAI/2026-27/0001' }),
    )
    await assertFails(push('acc', 'invoices', 'i1', invoice({ status: 'finalized', invoiceNumber: 'SAI/2026-27/0002' }), { rev: 2 }))
    await assertSucceeds(push('acc', 'invoices', 'i1', invoice({ status: 'finalized', invoiceNumber: 'SAI/2026-27/0001' }), { rev: 2 }))
  })

  it('finalized invoices are immutable except audited cancellation', async () => {
    const fin = invoice({ status: 'finalized', invoiceNumber: 'SAI/2026-27/0001' })
    await existing('invoices', 'i1', fin)
    await assertFails(push('owner', 'invoices', 'i1', { ...fin, totalPaise: 1, subtotalPaise: 1 }, { rev: 2 }))
    await assertFails(push('owner', 'invoices', 'i1', { ...fin, status: 'draft', invoiceNumber: null }, { rev: 2 }))
    await assertFails(push('owner', 'invoices', 'i1', { ...fin, status: 'cancelled' }, { rev: 2 }))
    await assertSucceeds(push('owner', 'invoices', 'i1', { ...fin, status: 'cancelled', cancelReason: 'Wrong rate', cancelledAt: 5, cancelledBy: 'owner' }, { rev: 2 }))
  })

  it('payments: positive on create; afterwards only reversal with a reason', async () => {
    await assertFails(push('acc', 'payments', 'p0', { invoiceId: 'i1', amountPaise: 0, reversedAt: null }))
    await assertSucceeds(push('acc', 'payments', 'p1', { invoiceId: 'i1', amountPaise: 5000, reversedAt: null }))
    await existing('payments', 'p2', { invoiceId: 'i1', amountPaise: 5000, reversedAt: null })
    await assertFails(push('acc', 'payments', 'p2', { invoiceId: 'i1', amountPaise: 9000, reversedAt: null }, { rev: 2 }))
    await assertSucceeds(push('acc', 'payments', 'p2', { invoiceId: 'i1', amountPaise: 5000, reversedAt: 7, reversedBy: 'acc', reverseReason: 'Bounced' }, { rev: 2 }))
    await assertFails(push('op', 'payments', 'p3', { invoiceId: 'i1', amountPaise: 100, reversedAt: null }))
  })

  it("operators can't read billing; managers can", async () => {
    await existing('invoices', 'i1', invoice())
    await assertFails(getDoc(doc(as('op'), 'companies', 'co', 'invoices', 'i1')))
    await assertSucceeds(getDoc(doc(as('mgr'), 'companies', 'co', 'invoices', 'i1')))
  })
})

describe('history', () => {
  it('audit entries are append-only', async () => {
    await assertSucceeds(push('op', 'auditLogs', 'a1', { action: 'create' }))
    await existing('auditLogs', 'a2', { action: 'create' })
    await assertFails(push('owner', 'auditLogs', 'a2', { action: 'tampered' }, { rev: 2 }))
  })
})

describe('device and license enforcement', () => {
  it('writes need an active device registered to the same user', async () => {
    await assertFails(push('owner', 'clients', 'c1', client, { deviceId: 'unknown-device' }))
    await assertFails(push('owner', 'clients', 'c2', client, { deviceId: 'dev-admin' }))
    await assertSucceeds(push('owner', 'clients', 'c3', client))
  })

  it('a revoked device is cut off', async () => {
    await patch(['companies', 'co', 'authorizedDevices', 'dev-owner'], { status: 'revoked' })
    await assertFails(push('owner', 'clients', 'c1', client))
  })

  it('suspended, expired or not-yet-started licenses block writes', async () => {
    await patch(['companies', 'co', 'licenses', 'lic1'], { status: 'suspended' })
    await assertFails(push('owner', 'clients', 'c1', client))
    await patch(['companies', 'co', 'licenses', 'lic1'], { status: 'active', validUntil: Timestamp.fromMillis(Date.now() - 1000) })
    await assertFails(push('owner', 'clients', 'c2', client))
    await patch(['companies', 'co', 'licenses', 'lic1'], { validFrom: Timestamp.fromMillis(Date.now() + DAY), validUntil: Timestamp.fromMillis(Date.now() + 2 * DAY) })
    await assertFails(push('owner', 'clients', 'c3', client))
  })

  it('reads of existing data keep working while the license is suspended', async () => {
    await existing('clients', 'c1', client)
    await patch(['companies', 'co', 'licenses', 'lic1'], { status: 'suspended' })
    await assertSucceeds(getDoc(doc(as('owner'), 'companies', 'co', 'clients', 'c1')))
  })

  it('clients cannot grant themselves licenses or devices, or read license secrets', async () => {
    await assertFails(setDoc(doc(as('owner'), 'companies', 'co', 'licenses', 'mine'), { status: 'active', maxDevices: 999 }))
    await assertFails(updateDoc(doc(as('owner'), 'companies', 'co', 'licenses', 'lic1'), { maxDevices: 999 }))
    await assertFails(setDoc(doc(as('op'), 'companies', 'co', 'authorizedDevices', 'new-phone'), { status: 'active', licenseId: 'lic1', userId: 'op' }))
    await assertFails(updateDoc(doc(as('owner'), 'companies', 'co', 'authorizedDevices', 'dev-op'), { status: 'revoked' }))
    await assertFails(getDoc(doc(as('owner'), 'companies', 'co', 'licenses', 'lic1')))
    await assertFails(getDoc(doc(as('owner'), 'auditEvents', 'x')))
  })
})

describe('device replacement requests', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'companies', 'co', 'deviceReplacementRequests', 'r1'), { requestedBy: 'op', status: 'pending', newDeviceId: 'new-phone' }),
    )
  })

  it('the requester and owner/admins can read; other members cannot', async () => {
    await assertSucceeds(getDoc(doc(as('op'), 'companies', 'co', 'deviceReplacementRequests', 'r1')))
    await assertSucceeds(getDoc(doc(as('owner'), 'companies', 'co', 'deviceReplacementRequests', 'r1')))
    await assertFails(getDoc(doc(as('op2'), 'companies', 'co', 'deviceReplacementRequests', 'r1')))
    await assertFails(getDoc(doc(as('mgr'), 'companies', 'co', 'deviceReplacementRequests', 'r1')))
  })

  it('nobody can create or approve requests from a client', async () => {
    await assertFails(setDoc(doc(as('op'), 'companies', 'co', 'deviceReplacementRequests', 'r2'), { requestedBy: 'op', status: 'pending' }))
    await assertFails(updateDoc(doc(as('owner'), 'companies', 'co', 'deviceReplacementRequests', 'r1'), { status: 'approved' }))
  })
})

describe('company users', () => {
  it('members cannot change roles or add people from the client', async () => {
    await assertFails(updateDoc(doc(as('owner'), 'companies', 'co', 'companyUsers', 'op'), { role: 'admin' }))
    await assertFails(setDoc(doc(as('owner'), 'companies', 'co', 'companyUsers', 'newbie'), { uid: 'newbie', role: 'operator', status: 'active' }))
  })
})
