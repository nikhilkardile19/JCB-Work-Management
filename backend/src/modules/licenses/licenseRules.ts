import type { Db, Tx } from '../../database/prisma.js'
import type { LicenseStatus } from '../../generated/prisma/client.js'

export type EffectiveStatus = LicenseStatus | 'not_started'

/** Status after applying the dates: an active license past its end is expired. */
export function effectiveStatus(status: LicenseStatus, validFrom: Date, validUntil: Date, now: Date): EffectiveStatus {
  if (status !== 'active') return status
  if (now.getTime() < validFrom.getTime()) return 'not_started'
  if (now.getTime() > validUntil.getTime()) return 'expired'
  return 'active'
}

export interface LicenseState {
  licenseId: string | null
  licenseStatus: EffectiveStatus | 'none'
  deviceStatus: 'active' | 'revoked' | 'unknown'
  validUntil: number | null
  maxDevices: number | null
  serverTime: number
}

/**
 * Whether [deviceId] may write for [userId] in [companyId] right now: an
 * active device registered to the same user, on a license that is active and
 * within its dates (the former `deviceLicensed()` rule).
 */
export async function deviceLicensed(db: Db | Tx, companyId: string, deviceId: string | undefined, userId: string, now: Date) {
  if (!deviceId) return false
  const device = await db.device.findUnique({
    where: { companyId_id: { companyId, id: deviceId } },
    include: { license: true },
  })
  return (
    !!device &&
    device.status === 'active' &&
    device.userId === userId &&
    effectiveStatus(device.license.status, device.license.validFrom, device.license.validUntil, now) === 'active'
  )
}

/** Locks a license row for the rest of the transaction (device-limit checks). */
export async function lockLicense(tx: Tx, licenseId: string) {
  await tx.$queryRaw`SELECT id FROM licenses WHERE id = ${licenseId} FOR UPDATE`
}

export const countActiveDevices = (db: Db | Tx, companyId: string, licenseId: string) =>
  db.device.count({ where: { companyId, licenseId, status: 'active' } })
