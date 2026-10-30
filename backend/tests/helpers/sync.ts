import type { Tx } from '../../src/database/prisma.js'
import { saveRecord, type CollectionName, type Json } from '../../src/modules/sync/collections.js'
import { tokens } from './factories.js'
import type { TestEnv } from './testApp.js'

const audit = { createdAt: 1, updatedAt: 1, deletedAt: null, createdBy: 'owner', updatedBy: 'owner', version: 1 }
const master = (name: string) => ({ name, notes: null, isActive: true, ...audit })
const location = (p: string) => ({
  [`${p}CapturedAt`]: null,
  [`${p}Lat`]: null,
  [`${p}Lng`]: null,
  [`${p}Accuracy`]: null,
  [`${p}LocationStatus`]: null,
})

/** Complete records as the app's Drift `toJson()` produces them. */
const DEFAULTS: Record<CollectionName, () => Json> = {
  clients: () => ({ ...master('Patil'), contactPerson: null, phone: null, email: null, billingAddress: null, gstin: null }),
  sites: () => ({ ...master('Hinjewadi'), clientId: 'c-ref', address: null, contactPerson: null, phone: null, defaultHourlyRatePaise: 150000 }),
  machines: () => ({ ...master('JCB 3DX'), registrationNumber: null, serialNumber: null, model: null, initialMeterReading: 0, meterUnit: 'hours' }),
  operators: () => ({ ...master('Suresh'), phone: null, code: null }),
  petrolPumps: () => ({ ...master('HP Pump'), phone: null, address: null }),
  workLogs: () => ({
    workDate: '2026-10-01',
    clientId: 'c-ref',
    siteId: 's-ref',
    machineId: 'm-ref',
    operatorId: null,
    operatorName: null,
    startReading: 1000,
    ...location('start'),
    endReading: 1800,
    ...location('end'),
    workingHours: 800,
    entryMode: 'manual',
    manualReason: 'no camera',
    notes: null,
    anomalyFlags: null,
    status: 'submitted',
    statusReason: null,
    approvedBy: null,
    approvedAt: null,
    invoiceId: null,
    ...audit,
    createdBy: 'op',
  }),
  fuelEntries: () => ({
    filledAt: 1_790_000_000_000,
    fuelDate: '2026-10-01',
    machineId: 'm-ref',
    pumpId: 'p-ref',
    clientId: null,
    siteId: null,
    litresCl: 2550,
    pricePerLitrePaise: 10235,
    totalPaise: 260993,
    receiptCapturedAt: null,
    receiptLat: null,
    receiptLng: null,
    receiptAccuracy: null,
    receiptLocationStatus: null,
    notes: null,
    ...audit,
    createdBy: 'op',
  }),
  invoices: () => ({
    clientId: 'c-ref',
    invoiceNumber: null,
    status: 'draft',
    invoiceDate: '2026-10-31',
    periodFrom: '2026-10-01',
    periodTo: '2026-10-31',
    paymentTermsDays: 15,
    dueDate: '2026-11-15',
    notes: null,
    subtotalPaise: 1000,
    discountPaise: 0,
    totalPaise: 1000,
    companySnapshot: null,
    clientSnapshot: null,
    finalizedAt: null,
    finalizedBy: null,
    cancelledAt: null,
    cancelledBy: null,
    cancelReason: null,
    ...audit,
  }),
  payments: () => ({
    invoiceId: 'i-fin',
    paymentDate: '2026-11-01',
    amountPaise: 5000,
    method: 'upi',
    reference: null,
    notes: null,
    reversedAt: null,
    reversedBy: null,
    reverseReason: null,
    createdAt: 1,
    updatedAt: 1,
    createdBy: 'acc',
    updatedBy: 'acc',
    version: 1,
  }),
  auditLogs: () => ({ actorId: 'op', action: 'create', entityType: 'workLogs', entityId: 'w1', details: null, createdAt: 1 }),
}

/** One invoice line: 1 hour (100 hundredths) at ₹10 = 1000 paise, for work log [workLogId]. */
export function line(invoiceId: string, workLogId = 'w-billed', o: Json = {}, companyId = 'co'): Json {
  return {
    id: `${invoiceId}-${workLogId}`,
    companyId,
    invoiceId,
    workLogId,
    workDate: '2026-10-01',
    siteId: 's-ref',
    siteName: 'Hinjewadi',
    machineId: 'm-ref',
    machineName: 'JCB 3DX',
    startReading: 1000,
    endReading: 1100,
    workingHours: 100,
    ratePaise: 1000,
    amountPaise: 1000,
    description: null,
    sortOrder: 0,
    ...o,
  }
}

export function record(collection: CollectionName, id: string, o: Json = {}, companyId = 'co'): Json {
  const r: Json = { id, companyId, ...DEFAULTS[collection](), ...o }
  if (collection === 'invoices' && !('lines' in o)) r.lines = [line(id, 'w-billed', {}, companyId)]
  return r
}

export function syncHelpers(env: TestEnv) {
  const token = tokens(env)
  let seq = 1_000_000n

  /** What the sync engine sends. `baseRev` = the revision the phone last saw. */
  async function push(uid: string, collection: CollectionName, id: string, o: Json = {}, opts: { baseRev?: number | null; company?: string; deviceId?: string; data?: Json } = {}) {
    const company = opts.company ?? 'co'
    const auth = `Bearer ${await token(uid)}`
    return env.request
      .put(`/api/v1/companies/${company}/sync/${collection}/${id}`)
      .set('Authorization', auth)
      .set('X-Device-Id', opts.deviceId ?? `dev-${uid}`)
      .send({ baseRev: opts.baseRev ?? null, data: opts.data ?? record(collection, id, o, company) })
  }

  async function pull(uid: string, collection: CollectionName, opts: { company?: string; after?: string; limit?: number } = {}) {
    const q = new URLSearchParams()
    if (opts.after) q.set('after', opts.after)
    if (opts.limit) q.set('limit', String(opts.limit))
    const auth = `Bearer ${await token(uid)}`
    return env.request.get(`/api/v1/companies/${opts.company ?? 'co'}/sync/${collection}?${q}`).set('Authorization', auth)
  }

  /** Server state written without rules (as if pushed earlier). */
  async function existing(collection: CollectionName, id: string, o: Json = {}, rev = 1, company = 'co') {
    await env.db.$transaction((tx) =>
      saveRecord(tx as Tx, collection, record(collection, id, o, company), {
        rev,
        syncSeq: seq++,
        serverUpdatedAt: new Date(),
        pushedBy: 'owner',
        deviceId: null,
      }),
    )
  }

  /** Masters and an approved work log that sample records refer to. */
  async function seedRefs(company = 'co') {
    await existing('clients', 'c-ref', {}, 1, company)
    await existing('sites', 's-ref', {}, 1, company)
    await existing('machines', 'm-ref', {}, 1, company)
    await existing('petrolPumps', 'p-ref', {}, 1, company)
    await existing('workLogs', 'w-billed', { status: 'approved', startReading: 1000, endReading: 1100, workingHours: 100 }, 1, company)
  }

  return { push, pull, existing, seedRefs, token }
}
