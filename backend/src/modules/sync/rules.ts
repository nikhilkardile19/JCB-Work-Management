import type { Tx } from '../../database/prisma.js'
import type { CompanyRole } from '../../generated/prisma/client.js'
import { ApiError, invalid } from '../../lib/errors.js'
import { deepEqual } from './deepEqual.js'
import type { CollectionName, Json } from './collections.js'

/**
 * Record-level write rules, ported one-for-one from `firebase/firestore.rules`
 * (`workLogWrite`, `fuelWrite`, `invoiceWrite`, `paymentWrite`, masters,
 * append-only `auditLogs`), plus checks Firestore could not express (invoice
 * line math, one finalized invoice per work log, no overpayment).
 *
 * Company membership, company status and the phone's license (`writer()` and
 * `deviceLicensed()` in the rules) are checked once per request before these.
 */
export interface RuleInput {
  tx: Tx
  collection: CollectionName
  companyId: string
  uid: string
  role: CompanyRole
  /** Server copy before this write, or null for a new record. */
  before: Json | null
  data: Json
}

const refuse = (message: string) => new ApiError('permission_denied', message)

/** Fields every update may touch (the rules' `onlyChanged` extras). */
const ALWAYS_CHANGEABLE = ['updatedAt', 'updatedBy', 'version']

/** True if [data] differs from [before] only in [keys] (and the always-changeable ones). */
export function onlyChanged(before: Json | null, data: Json, keys: string[]): boolean {
  if (!before) return false
  const allowed = new Set([...keys, ...ALWAYS_CHANGEABLE])
  for (const k of new Set([...Object.keys(before), ...Object.keys(data)])) {
    if (!allowed.has(k) && !deepEqual(before[k], data[k])) return false
  }
  return true
}

const OWNER_ADMIN: CompanyRole[] = ['owner', 'admin']
const BILLING: CompanyRole[] = ['owner', 'admin', 'accounts']

function masters({ role }: RuleInput) {
  if (!OWNER_ADMIN.includes(role)) throw refuse('Only the owner or an admin can change masters.')
}

function workLogs({ role, uid, before, data }: RuleInput) {
  // validWorkLog()
  const start = data.startReading as number
  const end = data.endReading as number | null
  if (start < 0) throw invalid('The start reading cannot be negative.')
  if (end != null && (end < start || data.workingHours !== end - start)) {
    throw invalid('Working hours must equal end reading − start reading, and the end cannot be below the start.')
  }
  if (data.entryMode !== 'photo' && data.status !== 'draft' && typeof data.manualReason !== 'string') {
    throw invalid('A manual entry needs a reason.')
  }

  const prev = (before?.status as string | undefined) ?? null
  const status = data.status as string
  const unbilled = data.invoiceId == null
  switch (role) {
    case 'owner':
    case 'admin':
      // Anything, except that an invoiced log only changes through its
      // invoice (finalize, or cancellation releasing it).
      if (prev === 'invoiced' && !(['invoiced', 'approved'].includes(status) && onlyChanged(before, data, ['status', 'invoiceId']))) {
        throw refuse('An invoiced work log only changes through its invoice.')
      }
      return
    case 'manager':
      // Create and review; never touch approved or billed logs.
      if ((prev === null || ['draft', 'submitted', 'rejected'].includes(prev)) && status !== 'invoiced' && unbilled) return
      throw refuse('Managers can create and review work logs, but not change approved or billed ones.')
    case 'operator':
      // Only their own unapproved logs; can't approve or bill.
      if (
        data.createdBy === uid &&
        (prev === null || (before!.createdBy === uid && ['draft', 'rejected'].includes(prev))) &&
        ['draft', 'submitted', 'cancelled'].includes(status) &&
        unbilled
      ) {
        return
      }
      throw refuse('Operators can only change their own work logs before approval.')
    case 'accounts':
      // Only invoice reservation/state of approved logs.
      if (
        prev !== null &&
        ['approved', 'invoiced'].includes(prev) &&
        onlyChanged(before, data, ['status', 'invoiceId']) &&
        ['approved', 'invoiced'].includes(status)
      ) {
        return
      }
      throw refuse('Accounts can only link approved work logs to invoices.')
  }
}

function fuelEntries({ role, uid, before, data }: RuleInput) {
  const litres = data.litresCl as number
  const price = data.pricePerLitrePaise as number
  if (litres <= 0) throw invalid('Litres must be more than zero.')
  if (price < 0) throw invalid('The price per litre cannot be negative.')
  if (BigInt(data.totalPaise as number) !== (BigInt(litres) * BigInt(price) + 50n) / 100n) {
    throw invalid('The fuel total must equal litres × price per litre.')
  }
  if (OWNER_ADMIN.includes(role)) return
  if ((role === 'manager' || role === 'operator') && data.createdBy === uid && (!before || before.createdBy === uid)) return
  throw refuse(role === 'accounts' ? 'Accounts cannot record fuel.' : 'You can only change your own fuel entries.')
}

/** Paise for [hours] (hundredths) at [ratePaise] per hour, half-up (InvoiceMath.lineAmount). */
const lineAmount = (hours: number, rate: number) => (BigInt(hours) * BigInt(rate) + 50n) / 100n

function checkLines(companyId: string, data: Json) {
  const lines = data.lines as Json[]
  let subtotal = 0n
  for (const l of lines) {
    if (l.companyId !== companyId || l.invoiceId !== data.id) throw invalid('Invoice lines must belong to this invoice.')
    if (l.workingHours !== (l.endReading as number) - (l.startReading as number) || (l.endReading as number) < (l.startReading as number)) {
      throw invalid('Each line’s hours must equal its end reading − start reading.')
    }
    if ((l.ratePaise as number) < 0 || BigInt(l.amountPaise as number) !== lineAmount(l.workingHours as number, l.ratePaise as number)) {
      throw invalid('Each line amount must equal hours × rate.')
    }
    subtotal += BigInt(l.amountPaise as number)
  }
  if (BigInt(data.subtotalPaise as number) !== subtotal) throw invalid('The subtotal must equal the sum of the lines.')
  if (new Set(lines.map((l) => l.workLogId)).size !== lines.length) throw invalid('A work log can appear only once on an invoice.')
}

async function invoices({ tx, role, companyId, before, data }: RuleInput) {
  if (!BILLING.includes(role)) throw refuse('Only the owner, admins and accounts can change invoices.')
  const discount = data.discountPaise as number
  const total = data.totalPaise as number
  if (discount < 0 || total < 0 || total !== (data.subtotalPaise as number) - discount) {
    throw invalid('The total must equal subtotal − discount, and neither may be negative.')
  }
  const prev = (before?.status as string | undefined) ?? null
  const status = data.status as string

  // Drafts are freely editable but carry no number.
  if (status === 'draft' && data.invoiceNumber == null && (prev === null || prev === 'draft')) {
    checkLines(companyId, data)
    return
  }
  // Finalizing: the number must be the one the server issued.
  if (status === 'finalized' && (prev === null || prev === 'draft')) {
    const issued = await tx.issuedInvoiceNumber.findUnique({ where: { companyId_invoiceId: { companyId, invoiceId: data.id as string } } })
    if (!issued || issued.invoiceNumber !== data.invoiceNumber) throw refuse('Finalizing needs the invoice number issued by the server.')
    checkLines(companyId, data)
    await assertNotBilledElsewhere(tx, companyId, data)
    return
  }
  // Finalized invoices change only by cancellation, with a reason.
  if (
    prev === 'finalized' &&
    status === 'cancelled' &&
    typeof data.cancelReason === 'string' &&
    onlyChanged(before, data, ['status', 'cancelledAt', 'cancelledBy', 'cancelReason'])
  ) {
    return
  }
  // Re-sending identical content (lost reply) is harmless.
  if (onlyChanged(before, data, [])) return
  throw refuse(prev === 'finalized' || prev === 'cancelled' ? 'A finalized invoice can only be cancelled, with a reason.' : 'This invoice change is not allowed.')
}

/** A work log can be on only one finalized invoice (US-07, no double billing). */
async function assertNotBilledElsewhere(tx: Tx, companyId: string, data: Json) {
  const workLogIds = (data.lines as Json[]).map((l) => l.workLogId as string)
  if (!workLogIds.length) return
  const clash = await tx.invoiceLine.findFirst({
    where: { companyId, workLogId: { in: workLogIds }, invoiceId: { not: data.id as string }, invoice: { status: 'finalized' } },
    include: { invoice: { select: { invoiceNumber: true } } },
  })
  if (clash) throw invalid(`A work log on this invoice is already billed on invoice ${clash.invoice.invoiceNumber}.`)
}

async function payments({ tx, role, companyId, before, data }: RuleInput) {
  if (!BILLING.includes(role)) throw refuse('Only the owner, admins and accounts can record payments.')
  if (!before) {
    if ((data.amountPaise as number) <= 0 || data.reversedAt != null) throw invalid('A payment must be more than zero.')
    const invoice = await tx.invoice.findUnique({ where: { companyId_id: { companyId, id: data.invoiceId as string } } })
    if (!invoice || invoice.status !== 'finalized') throw invalid('Payments can only be recorded on finalized invoices.')
    const paid = await tx.payment.aggregate({
      where: { companyId, invoiceId: invoice.id, reversedAt: null },
      _sum: { amountPaise: true },
    })
    if ((paid._sum.amountPaise ?? 0n) + BigInt(data.amountPaise as number) > invoice.totalPaise) {
      throw invalid('This payment is more than the amount outstanding on the invoice.')
    }
    return
  }
  // After recording, a payment can only be reversed (with a reason).
  if (before.reversedAt == null && typeof data.reverseReason === 'string' && onlyChanged(before, data, ['reversedAt', 'reversedBy', 'reverseReason'])) {
    return
  }
  if (onlyChanged(before, data, [])) return
  throw refuse('A recorded payment can only be reversed, with a reason.')
}

function auditLogs({ before }: RuleInput) {
  // History is append-only.
  if (before) throw refuse('History entries cannot be changed.')
}

const RULES: Record<CollectionName, (input: RuleInput) => void | Promise<void>> = {
  clients: masters,
  sites: masters,
  machines: masters,
  operators: masters,
  petrolPumps: masters,
  workLogs,
  fuelEntries,
  invoices,
  payments,
  auditLogs,
}

export const checkWrite = (input: RuleInput) => RULES[input.collection](input)
