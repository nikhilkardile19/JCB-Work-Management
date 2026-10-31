import type { AuditEvent, Device, DeviceReplacementRequest, License } from '../../generated/prisma/client.js'
import { ms } from '../../lib/time.js'
import { z } from '../../lib/validation.js'

/** Response shapes — exactly the portal's types in admin/src/lib/adminApi.ts. */
export const LicenseOut = z
  .object({
    id: z.string(),
    companyId: z.string(),
    companyName: z.string().nullable(),
    status: z.enum(['pending', 'active', 'suspended', 'expired', 'revoked']),
    validFrom: z.number().int(),
    validUntil: z.number().int(),
    maxDevices: z.number().int(),
    lastValidatedAt: z.number().int().nullable(),
    activationCodeUsedAt: z.number().int().nullable().openapi({ description: 'When the current code was used (codes work once); null while unused' }),
    activationCodeDeviceId: z.string().nullable(),
  })
  .openapi('License')

export const licenseOut = (l: License & { company?: { name: string } | null }): z.infer<typeof LicenseOut> => ({
  id: l.id,
  companyId: l.companyId,
  companyName: l.company?.name ?? null,
  status: l.status,
  validFrom: l.validFrom.getTime(),
  validUntil: l.validUntil.getTime(),
  maxDevices: l.maxDevices,
  lastValidatedAt: ms(l.lastValidatedAt),
  activationCodeUsedAt: ms(l.activationCodeUsedAt),
  activationCodeDeviceId: l.activationCodeDeviceId,
})

export const DeviceOut = z
  .object({
    id: z.string(),
    companyId: z.string(),
    licenseId: z.string(),
    userId: z.string(),
    deviceModel: z.string().nullable(),
    status: z.enum(['active', 'revoked']),
    activatedAt: z.number().int().nullable(),
    lastSeenAt: z.number().int().nullable(),
    revokeReason: z.string().nullable(),
    replacementForDeviceId: z.string().nullable(),
    replacedBy: z.string().nullable(),
  })
  .openapi('Device')

export const deviceOut = (d: Device): z.infer<typeof DeviceOut> => ({
  id: d.id,
  companyId: d.companyId,
  licenseId: d.licenseId,
  userId: d.userId,
  deviceModel: d.deviceModel,
  status: d.status,
  activatedAt: ms(d.activatedAt),
  lastSeenAt: ms(d.lastSeenAt),
  revokeReason: d.revokeReason,
  replacementForDeviceId: d.replacementForDeviceId,
  replacedBy: d.replacedBy,
})

export const RequestOut = z
  .object({
    id: z.string(),
    companyId: z.string(),
    companyName: z.string().nullable(),
    licenseId: z.string(),
    newDeviceId: z.string(),
    newDeviceModel: z.string().nullable(),
    requestedBy: z.string(),
    requesterEmail: z.string().nullable(),
    reason: z.string(),
    status: z.enum(['pending', 'approved', 'rejected']),
    createdAt: z.number().int().nullable(),
    reviewReason: z.string().nullable(),
    revokedDeviceId: z.string().nullable(),
  })
  .openapi('ReplacementRequest')

export const requestOut = (
  r: DeviceReplacementRequest & { company: { name: string }; requesterEmail: string | null },
): z.infer<typeof RequestOut> => ({
  id: r.id,
  companyId: r.companyId,
  companyName: r.company.name,
  licenseId: r.licenseId,
  newDeviceId: r.newDeviceId,
  newDeviceModel: r.newDeviceModel,
  requestedBy: r.requestedBy,
  requesterEmail: r.requesterEmail,
  reason: r.reason,
  status: r.status,
  createdAt: ms(r.createdAt),
  reviewReason: r.reviewReason,
  revokedDeviceId: r.revokedDeviceId,
})

export const EventOut = z
  .object({
    id: z.string(),
    type: z.string(),
    actorId: z.string().nullable(),
    companyId: z.string().nullable(),
    licenseId: z.string().nullable(),
    deviceId: z.string().nullable(),
    reason: z.string().nullable(),
    at: z.number().int().nullable(),
    details: z.record(z.string(), z.unknown()),
  })
  .openapi('AuditEvent')

export const eventOut = (e: AuditEvent): z.infer<typeof EventOut> => ({
  id: e.id,
  type: e.type,
  actorId: e.actorId,
  companyId: e.companyId,
  licenseId: e.licenseId,
  deviceId: e.deviceId,
  reason: e.reason,
  at: ms(e.at),
  details: (e.details ?? {}) as Record<string, unknown>,
})

export const pageOf = <T extends z.ZodType>(item: T, name: string) =>
  z.object({ items: z.array(item), next: z.string().nullable() }).openapi(name)
