import type { Tx } from '../../database/prisma.js'
import { fromDb, objectSchema, t, toDb, type Fields } from './fields.js'

/**
 * The ten synced collections. Field lists mirror the app's Drift tables
 * (mobile/lib/data/local/*_tables.dart) minus `syncStatus` and device-only
 * paths; the strict schemas reject anything else.
 */
const n = t.nullable
const LONG = 5000

const audit = {
  createdAt: t.ts(),
  updatedAt: t.ts(),
  deletedAt: n(t.ts()),
  createdBy: t.id(),
  updatedBy: t.id(),
  version: t.int(),
}

/** MasterColumns: name 1–120 characters and isActive (the old `validMaster` rule). */
const master = {
  id: t.id(),
  companyId: t.id(),
  name: t.text(120, 1),
  notes: n(t.text(LONG)),
  isActive: t.bool(),
  ...audit,
}

const LOCATION = (prefix: string) => ({
  [`${prefix}CapturedAt`]: n(t.ts()),
  [`${prefix}Lat`]: n(t.real()),
  [`${prefix}Lng`]: n(t.real()),
  [`${prefix}Accuracy`]: n(t.real()),
  [`${prefix}LocationStatus`]: n(t.text(40)),
})

export const WORK_LOG_STATUSES = ['draft', 'submitted', 'approved', 'rejected', 'invoiced', 'cancelled'] as const

const FIELDS = {
  clients: {
    ...master,
    contactPerson: n(t.text(120)),
    phone: n(t.text(40)),
    email: n(t.text(200)),
    billingAddress: n(t.text(1000)),
    gstin: n(t.text(20)),
  },
  sites: {
    ...master,
    clientId: t.id(),
    address: n(t.text(1000)),
    contactPerson: n(t.text(120)),
    phone: n(t.text(40)),
    defaultHourlyRatePaise: n(t.money()),
  },
  machines: {
    ...master,
    registrationNumber: n(t.text(60)),
    serialNumber: n(t.text(60)),
    model: n(t.text(120)),
    initialMeterReading: t.int(),
    meterUnit: t.text(20, 1),
  },
  operators: { ...master, phone: n(t.text(40)), code: n(t.text(40)) },
  petrolPumps: { ...master, phone: n(t.text(40)), address: n(t.text(1000)) },
  workLogs: {
    id: t.id(),
    companyId: t.id(),
    workDate: t.date(),
    clientId: t.id(),
    siteId: t.id(),
    machineId: t.id(),
    operatorId: n(t.id()),
    operatorName: n(t.text(120)),
    startReading: t.int(),
    ...LOCATION('start'),
    endReading: n(t.int()),
    ...LOCATION('end'),
    workingHours: n(t.int()),
    entryMode: t.enum(['photo', 'manual']),
    manualReason: n(t.text(LONG)),
    notes: n(t.text(LONG)),
    anomalyFlags: n(t.text(500)),
    status: t.enum(WORK_LOG_STATUSES),
    statusReason: n(t.text(LONG)),
    approvedBy: n(t.id()),
    approvedAt: n(t.ts()),
    invoiceId: n(t.id()),
    ...audit,
  },
  fuelEntries: {
    id: t.id(),
    companyId: t.id(),
    filledAt: t.ts(),
    fuelDate: t.date(),
    machineId: t.id(),
    pumpId: t.id(),
    clientId: n(t.id()),
    siteId: n(t.id()),
    litresCl: t.int(),
    pricePerLitrePaise: t.money(),
    totalPaise: t.money(),
    receiptCapturedAt: n(t.ts()),
    receiptLat: n(t.real()),
    receiptLng: n(t.real()),
    receiptAccuracy: n(t.real()),
    receiptLocationStatus: n(t.text(40)),
    notes: n(t.text(LONG)),
    ...audit,
  },
  invoices: {
    id: t.id(),
    companyId: t.id(),
    clientId: t.id(),
    invoiceNumber: n(t.text(60)),
    status: t.enum(['draft', 'finalized', 'cancelled']),
    invoiceDate: t.date(),
    periodFrom: t.date(),
    periodTo: t.date(),
    paymentTermsDays: t.int(),
    dueDate: t.date(),
    notes: n(t.text(LONG)),
    subtotalPaise: t.money(),
    discountPaise: t.money(),
    totalPaise: t.money(),
    companySnapshot: n(t.text(20_000)),
    clientSnapshot: n(t.text(20_000)),
    finalizedAt: n(t.ts()),
    finalizedBy: n(t.id()),
    cancelledAt: n(t.ts()),
    cancelledBy: n(t.id()),
    cancelReason: n(t.text(LONG)),
    ...audit,
  },
  payments: {
    id: t.id(),
    companyId: t.id(),
    invoiceId: t.id(),
    paymentDate: t.date(),
    amountPaise: t.money(),
    method: t.enum(['cash', 'bank', 'upi', 'cheque', 'other']),
    reference: n(t.text(200)),
    notes: n(t.text(LONG)),
    reversedAt: n(t.ts()),
    reversedBy: n(t.id()),
    reverseReason: n(t.text(LONG)),
    createdAt: t.ts(),
    updatedAt: t.ts(),
    createdBy: t.id(),
    updatedBy: t.id(),
    version: t.int(),
  },
  auditLogs: {
    id: t.id(),
    companyId: t.id(),
    actorId: t.id(),
    action: t.text(80, 1),
    entityType: t.text(80, 1),
    entityId: t.id(),
    details: n(t.text(200_000)),
    createdAt: t.ts(),
  },
} satisfies Record<string, Fields>

export const INVOICE_LINE_FIELDS = {
  id: t.id(),
  companyId: t.id(),
  invoiceId: t.id(),
  workLogId: t.id(),
  workDate: t.date(),
  siteId: t.id(),
  siteName: t.text(120),
  machineId: t.id(),
  machineName: t.text(120),
  startReading: t.int(),
  endReading: t.int(),
  workingHours: t.int(),
  ratePaise: t.money(),
  amountPaise: t.money(),
  description: n(t.text(LONG)),
  sortOrder: t.int(),
} satisfies Fields

export type CollectionName = keyof typeof FIELDS
export const COLLECTIONS = Object.keys(FIELDS) as CollectionName[]

/** Prisma delegate per collection. */
const MODEL: Record<CollectionName, string> = {
  clients: 'client',
  sites: 'site',
  machines: 'machine',
  operators: 'operator',
  petrolPumps: 'petrolPump',
  workLogs: 'workLog',
  fuelEntries: 'fuelEntry',
  invoices: 'invoice',
  payments: 'payment',
  auditLogs: 'auditLog',
}

export type Json = Record<string, unknown>

export interface SyncMeta {
  rev: number
  syncSeq: bigint
  serverUpdatedAt: Date
  pushedBy: string
  deviceId: string | null
}

export interface StoredRecord {
  rev: number
  syncSeq: bigint
  data: Json
}

// Prisma delegates share this shape; typed loosely so one code path serves all ten.
interface Delegate {
  findUnique(args: object): Promise<Json | null>
  findMany(args: object): Promise<Json[]>
  upsert(args: object): Promise<unknown>
}

const lineSchema = objectSchema(INVOICE_LINE_FIELDS)
export const SCHEMAS = Object.fromEntries(
  COLLECTIONS.map((c) => [
    c,
    c === 'invoices' ? objectSchema(FIELDS.invoices).extend({ lines: lineSchema.array().max(1000) }) : objectSchema(FIELDS[c]),
  ]),
) as Record<CollectionName, ReturnType<typeof objectSchema>>

export const isCollection = (c: string): c is CollectionName => c in FIELDS

/** Only owner/admin/manager/accounts may read (and therefore sync) these. */
export const BILLING_COLLECTIONS = new Set<CollectionName>(['invoices', 'payments'])

const delegate = (tx: Tx, c: CollectionName) => (tx as unknown as Record<string, Delegate>)[MODEL[c]]

const withLines = (c: CollectionName) =>
  c === 'invoices' ? { include: { lines: { orderBy: [{ sortOrder: 'asc' }, { id: 'asc' }] } } } : {}

/** Business JSON of a stored row, exactly as the app's Drift `toJson()` shapes it. */
export function rowToJson(c: CollectionName, row: Json): Json {
  const data = fromDb(FIELDS[c], row)
  if (c === 'invoices') data.lines = (row.lines as Json[]).map((l) => fromDb(INVOICE_LINE_FIELDS, l))
  return data
}

export async function loadRecord(tx: Tx, c: CollectionName, companyId: string, id: string): Promise<StoredRecord | null> {
  const row = await delegate(tx, c).findUnique({ where: { companyId_id: { companyId, id } }, ...withLines(c) })
  if (!row) return null
  return { rev: row.rev as number, syncSeq: row.syncSeq as bigint, data: rowToJson(c, row) }
}

export async function saveRecord(tx: Tx, c: CollectionName, data: Json, meta: SyncMeta) {
  const { lines, ...fields } = data
  const values = { ...toDb(FIELDS[c], fields), ...meta }
  const { companyId, id } = fields as { companyId: string; id: string }
  await delegate(tx, c).upsert({ where: { companyId_id: { companyId, id } }, create: values, update: values })
  if (c === 'invoices') {
    await tx.invoiceLine.deleteMany({ where: { companyId, invoiceId: id } })
    if ((lines as Json[]).length) {
      await tx.invoiceLine.createMany({ data: (lines as Json[]).map((l) => toDb(INVOICE_LINE_FIELDS, l)) as never })
    }
  }
}

export async function changesAfter(tx: Tx, c: CollectionName, companyId: string, afterSeq: bigint, limit: number) {
  const rows = await delegate(tx, c).findMany({
    where: { companyId, syncSeq: { gt: afterSeq } },
    orderBy: { syncSeq: 'asc' },
    take: limit,
    ...withLines(c),
  })
  return rows.map((row) => ({
    id: row.id as string,
    rev: row.rev as number,
    cursor: `${row.syncSeq as bigint}|${row.id as string}`,
    data: rowToJson(c, row),
  }))
}
