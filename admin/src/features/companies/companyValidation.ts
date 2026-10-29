import type { CompanyProfile } from '../../lib/adminApi'

export type Errors = Partial<Record<keyof CompanyProfile | 'ownerEmail', string>>

/** Client-side checks; the server validates again. */
export function validateCompany(p: CompanyProfile & { ownerEmail?: string }, needOwner: boolean): Errors {
  const e: Errors = {}
  if (p.name.trim().length < 2) e.name = 'Enter the company name'
  if (!p.contactPerson.trim()) e.contactPerson = 'Enter a contact person'
  if (!/^\+?[0-9]{10,13}$/.test(p.phone.replace(/[\s-]/g, ''))) e.phone = 'Enter a valid phone number'
  if (p.address.trim().length < 5) e.address = 'Enter the address'
  if (!/^[A-Z0-9-]{1,10}$/.test(p.invoicePrefix)) e.invoicePrefix = 'Up to 10 letters, numbers or dashes'
  if (p.gstin && !/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/.test(p.gstin)) e.gstin = 'GSTIN must be 15 characters, e.g. 27ABCDE1234F1Z5'
  if (p.email && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(p.email)) e.email = 'Enter a valid email'
  if (needOwner && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(p.ownerEmail ?? '')) e.ownerEmail = 'Enter the owner’s email'
  return e
}
