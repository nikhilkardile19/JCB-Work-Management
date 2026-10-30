import type { Db, Tx } from '../../database/prisma.js'
import { newId } from '../../lib/ids.js'

export interface AuditEventInput {
  type: string
  actorId?: string | null
  companyId?: string | null
  licenseId?: string | null
  deviceId?: string | null
  reason?: string | null
  /** Anything else worth keeping (before/after values, emails, request IDs). */
  [detail: string]: unknown
}

/**
 * Appends a server-written history entry (license, device, company and user
 * administration). Replaces the Functions' `auditEvents` collection.
 */
export async function recordEvent(db: Db | Tx, at: Date, event: AuditEventInput) {
  const { type, actorId, companyId, licenseId, deviceId, reason, ...details } = event
  await db.auditEvent.create({
    data: {
      id: newId(),
      type,
      actorId: actorId ?? null,
      companyId: companyId ?? null,
      licenseId: licenseId ?? null,
      deviceId: deviceId ?? null,
      reason: reason ?? null,
      details: JSON.parse(JSON.stringify(details)),
      at,
    },
  })
}
