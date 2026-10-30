import type { AppContext } from '../../context.js'
import { denied, precondition } from '../../lib/errors.js'
import type { Api } from '../../lib/http.js'
import { idSchema, z } from '../../lib/validation.js'
import { requireMember } from '../companies/access.js'
import { deviceLicensed } from '../licenses/licenseRules.js'

/** Roles allowed to finalize invoices (mobile: Permission.manageInvoices). */
const INVOICE_ROLES = new Set(['owner', 'admin', 'accounts'])

const FinancialYear = z
  .string()
  .regex(/^(\d{4})-(\d{2})$/, 'must look like 2026-27')
  .refine((fy) => (Number(fy.slice(0, 4)) + 1) % 100 === Number(fy.slice(5)), 'must look like 2026-27')

/**
 * Issues the next official invoice number for a company and financial year,
 * e.g. `JCB/2026-27/0007` (ported from `allocateInvoiceNumber`). The counter
 * row is locked for the transaction, so concurrent phones never get the same
 * number, and the call is idempotent per invoice: a retry after a lost
 * response returns the number already issued. The database additionally
 * enforces one number per (company, invoice number).
 */
async function allocate(ctx: AppContext, uid: string, companyId: string, invoiceId: string, financialYear: string, deviceId: string | undefined) {
  const now = ctx.clock()
  const access = await requireMember(ctx.db, companyId, uid)
  if (!INVOICE_ROLES.has(access.role)) throw denied('Not allowed to finalize invoices for this company.')
  if (access.company.status !== 'active') throw precondition('This company is not active yet.')
  // Same check as for the invoice upload itself, so an unlicensed phone
  // can't use up numbers and leave gaps in the GST invoice series.
  if (!(await deviceLicensed(ctx.db, companyId, deviceId, uid, now))) {
    throw precondition('This phone is not activated on an active license.', 'license')
  }

  return ctx.db.$transaction(async (tx) => {
    // One allocation per company at a time; NO KEY UPDATE leaves foreign-key
    // checks of concurrent sync writes unblocked.
    await tx.$queryRaw`SELECT id FROM companies WHERE id = ${companyId} FOR NO KEY UPDATE`
    const issued = await tx.issuedInvoiceNumber.findUnique({ where: { companyId_invoiceId: { companyId, invoiceId } } })
    if (issued) return { invoiceNumber: issued.invoiceNumber }
    const [counter] = await tx.$queryRaw<{ last: number }[]>`
      INSERT INTO invoice_number_counters (company_id, financial_year, last, updated_at)
      VALUES (${companyId}, ${financialYear}, 1, ${now})
      ON CONFLICT (company_id, financial_year)
      DO UPDATE SET last = invoice_number_counters.last + 1, updated_at = ${now}
      RETURNING last`
    const prefix = access.company.invoicePrefix || 'INV'
    const invoiceNumber = `${prefix}/${financialYear}/${String(counter.last).padStart(4, '0')}`
    await tx.issuedInvoiceNumber.create({ data: { companyId, invoiceId, invoiceNumber, financialYear, issuedBy: uid, issuedAt: now } })
    return { invoiceNumber }
  })
}

export function registerInvoiceNumberRoutes(api: Api) {
  const { ctx } = api
  api.route(
    {
      method: 'post',
      path: '/companies/:companyId/invoice-numbers',
      tag: 'Billing',
      summary: 'Issue the official number for an invoice being finalized (idempotent per invoice)',
      description: 'Requires the `X-Device-Id` header of an active phone on an active license.',
      params: z.object({ companyId: idSchema() }),
      body: z.object({ invoiceId: idSchema(), financialYear: FinancialYear }),
      response: z.object({ invoiceNumber: z.string() }),
      errors: [403, 409],
    },
    ({ params, body, user, req }) =>
      allocate(ctx, user.id, params.companyId, body.invoiceId, body.financialYear, req.get('x-device-id')),
  )
}
