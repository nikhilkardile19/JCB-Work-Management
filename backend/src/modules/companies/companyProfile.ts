import type { Company } from '../../generated/prisma/client.js'
import { z } from '../../lib/validation.js'

const optional = (schema: z.ZodType<string>) =>
  z.preprocess((v) => (typeof v === 'string' && v.trim() === '' ? null : v), schema.nullable().optional())
    .transform((v) => v ?? null)

/**
 * Company profile validation — same limits as the mobile `CompanyValidators`,
 * the former `validCompanyProfile` rule and the admin Functions.
 */
export const CompanyProfileInput = z.object({
  name: z.string().trim().min(2, 'Enter the company name').max(120),
  contactPerson: z.string().trim().min(1, 'Enter a contact person').max(120),
  phone: z.string().trim().min(10, 'Enter a valid phone number').max(20),
  address: z.string().trim().min(5, 'Enter the company address').max(500),
  invoicePrefix: z.string().regex(/^[A-Z0-9-]{1,10}$/, 'Use up to 10 capital letters, numbers or dashes'),
  email: optional(z.string().trim().max(200).regex(/^[^@\s]+@[^@\s]+\.[^@\s]+$/, 'Enter a valid email address')),
  gstin: optional(
    z.string().trim().regex(/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/, 'GSTIN must be 15 characters, e.g. 27ABCDE1234F1Z5'),
  ),
})

export type CompanyProfile = z.infer<typeof CompanyProfileInput>

export const CompanyOut = z
  .object({
    id: z.string(),
    name: z.string(),
    contactPerson: z.string(),
    phone: z.string(),
    address: z.string(),
    invoicePrefix: z.string(),
    email: z.string().nullable(),
    gstin: z.string().nullable(),
    currency: z.string(),
    status: z.enum(['pending', 'active', 'suspended']),
    ownerUid: z.string(),
    createdAt: z.number().int().nullable(),
  })
  .openapi('Company')

export function companyOut(c: Company): z.infer<typeof CompanyOut> {
  return {
    id: c.id,
    name: c.name,
    contactPerson: c.contactPerson,
    phone: c.phone,
    address: c.address,
    invoicePrefix: c.invoicePrefix,
    email: c.email,
    gstin: c.gstin,
    currency: c.currency,
    status: c.status,
    ownerUid: c.ownerUserId,
    createdAt: c.createdAt.getTime(),
  }
}

/** Fields that differ between [before] and [after], as `{from, to}` pairs (audit). */
export function changedFields(before: Record<string, unknown>, after: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(after)
      .filter(([k, v]) => (before[k] ?? null) !== v)
      .map(([k, v]) => [k, { from: before[k] ?? null, to: v }]),
  )
}
