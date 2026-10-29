import { createHash, randomInt } from 'node:crypto';
import { FieldValue, Timestamp, type Firestore, type Transaction } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { requireAdmin } from './admin.js';
import { assertWithinLimit, consume, LIMITS } from './rateLimit.js';

/**
 * License model (sprint doc §5.5):
 *   companies/{companyId}/licenses/{licenseId}
 *     status: pending | active | suspended | expired | revoked
 *     validFrom, validUntil: Timestamp; maxDevices: number
 *     activationCodeHash: sha256 of the normalized code (plaintext never stored)
 *   companies/{companyId}/authorizedDevices/{deviceId}
 *     status: active | revoked; licenseId; userId; deviceModel; platform
 *   auditEvents/{id} — server-written history of license/device actions.
 */

export type LicenseStatus = 'pending' | 'active' | 'suspended' | 'expired' | 'revoked';

/** Unambiguous alphabet (no I, O, 0, 1) for codes read over the phone. */
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const CODE_PREFIX = 'JCBW';

/** Random activation code like `JCBW-7KQ2-M9XD-PA4H` (60 bits of entropy). */
export function generateActivationCode(): string {
  const groups = Array.from({ length: 3 }, () =>
    Array.from({ length: 4 }, () => ALPHABET[randomInt(ALPHABET.length)]).join(''),
  );
  return [CODE_PREFIX, ...groups].join('-');
}

/** Upper-case, drop spaces/dashes and the optional prefix. */
export function normalizeCode(code: string): string {
  const s = code.toUpperCase().replace(/[\s-]/g, '');
  return s.startsWith(CODE_PREFIX) ? s.slice(CODE_PREFIX.length) : s;
}

export function hashCode(code: string): string {
  return createHash('sha256').update(normalizeCode(code)).digest('hex');
}

/** Status after applying the dates: an active license past its end is expired. */
export function effectiveStatus(status: LicenseStatus, validFrom: Timestamp, validUntil: Timestamp, now: Date): LicenseStatus | 'not_started' {
  if (status !== 'active') return status;
  if (now.getTime() < validFrom.toMillis()) return 'not_started';
  if (now.getTime() > validUntil.toMillis()) return 'expired';
  return 'active';
}

export interface LicenseState {
  licenseId: string | null;
  licenseStatus: LicenseStatus | 'not_started' | 'none';
  deviceStatus: 'active' | 'revoked' | 'unknown';
  validUntil: number | null;
  maxDevices: number | null;
  serverTime: number;
}

export const str = (v: unknown, max = 200): v is string => typeof v === 'string' && v.length > 0 && v.length <= max && !v.includes('/');

async function audit(db: Firestore, event: Record<string, unknown>) {
  await db.collection('auditEvents').add({ ...event, at: FieldValue.serverTimestamp() });
}

export async function requireMember(db: Firestore, uid: string | undefined, companyId: string) {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  const [company, member] = await db.getAll(
    db.doc(`companies/${companyId}`),
    db.doc(`companies/${companyId}/companyUsers/${uid}`),
  );
  if (!member.exists || member.get('status') !== 'active') {
    throw new HttpsError('permission-denied', 'You are not a member of this company.');
  }
  if (!company.exists || company.get('status') !== 'active') {
    throw new HttpsError('failed-precondition', 'This company is not approved yet.');
  }
}

// --- createLicense (developer admins) ----------------------------------------

export async function createLicense(
  db: Firestore,
  uid: string | undefined,
  data: unknown,
  now = new Date(),
): Promise<{ licenseId: string; activationCode: string }> {
  await requireAdmin(db, uid, 'licenses.manage');
  const d = (data ?? {}) as Record<string, unknown>;
  const maxDevices = d.maxDevices;
  if (!str(d.companyId) || typeof d.validFrom !== 'number' || typeof d.validUntil !== 'number'
      || typeof maxDevices !== 'number' || !Number.isInteger(maxDevices) || maxDevices < 1 || maxDevices > 100
      || d.validUntil <= d.validFrom) {
    throw new HttpsError('invalid-argument', 'companyId, validFrom < validUntil (ms) and maxDevices (1–100) are required.');
  }
  const company = await db.doc(`companies/${d.companyId}`).get();
  if (!company.exists) throw new HttpsError('not-found', 'Company not found.');

  const activationCode = generateActivationCode();
  const ref = db.collection(`companies/${d.companyId}/licenses`).doc();
  await ref.set({
    licenseId: ref.id,
    companyId: d.companyId,
    companyName: company.get('name') ?? null,
    status: 'active',
    validFrom: Timestamp.fromMillis(d.validFrom),
    validUntil: Timestamp.fromMillis(d.validUntil),
    maxDevices,
    activationCodeHash: hashCode(activationCode),
    createdAt: FieldValue.serverTimestamp(),
    createdBy: uid,
    updatedAt: FieldValue.serverTimestamp(),
  });
  await audit(db, { type: 'license.create', companyId: d.companyId, licenseId: ref.id, actorId: uid, maxDevices });
  // The plaintext code is returned once and never stored.
  return { licenseId: ref.id, activationCode };
}

/** Persists `expired` on an active license whose end date has passed. */
async function markExpired(db: Firestore, companyId: string, licenseId: string, now: Date) {
  const ref = db.doc(`companies/${companyId}/licenses/${licenseId}`);
  await db.runTransaction(async (tx) => {
    const l = await tx.get(ref);
    if (l.get('status') === 'active' && now.getTime() > (l.get('validUntil') as Timestamp).toMillis()) {
      tx.update(ref, { status: 'expired', updatedAt: FieldValue.serverTimestamp() });
    }
  });
}

// --- activateDevice ----------------------------------------------------------

type DenyReason = 'invalid_code' | 'not_started' | 'expired' | 'suspended' | 'revoked' | 'pending' | 'device_limit' | 'device_revoked';

const DENY_MESSAGES: Record<DenyReason, string> = {
  invalid_code: 'That activation code is not valid for this company.',
  not_started: 'This license has not started yet.',
  expired: 'This license has expired. Contact support to renew.',
  suspended: 'This license is suspended. Contact support.',
  revoked: 'This license has been revoked. Contact support.',
  pending: 'This license is not active yet. Contact support.',
  device_limit: 'All devices allowed by this license are in use. Request a device replacement or contact support.',
  device_revoked: 'This device has been deactivated. Request a device replacement or contact support.',
};

class Denied extends Error {
  constructor(readonly reason: DenyReason, readonly licenseId?: string) {
    super(DENY_MESSAGES[reason]);
  }
}

export async function activateDevice(
  db: Firestore,
  uid: string | undefined,
  data: unknown,
  now = new Date(),
): Promise<LicenseState> {
  const d = (data ?? {}) as Record<string, unknown>;
  if (!str(d.companyId) || !str(d.activationCode, 40) || !str(d.deviceId, 64)) {
    throw new HttpsError('invalid-argument', 'companyId, activationCode and deviceId are required.');
  }
  const companyId = d.companyId;
  const deviceId = d.deviceId;
  await requireMember(db, uid, companyId);
  const limitKey = `codeFailures_${uid}`;
  await assertWithinLimit(db, limitKey, LIMITS.codeFailures, now.getTime());

  const hash = hashCode(d.activationCode);
  const matches = await db.collection(`companies/${companyId}/licenses`).where('activationCodeHash', '==', hash).limit(1).get();
  const base = { companyId, deviceId, uid, deviceModel: str(d.deviceModel, 100) ? d.deviceModel : null };

  try {
    if (matches.empty) throw new Denied('invalid_code');
    const licenseRef = matches.docs[0].ref;
    const state = await db.runTransaction(async (tx: Transaction) => {
      const license = await tx.get(licenseRef);
      const status = effectiveStatus(license.get('status'), license.get('validFrom'), license.get('validUntil'), now);
      if (status !== 'active') throw new Denied(status as DenyReason, licenseRef.id);

      const deviceRef = db.doc(`companies/${companyId}/authorizedDevices/${deviceId}`);
      const device = await tx.get(deviceRef);
      if (device.exists && device.get('status') === 'revoked') throw new Denied('device_revoked', licenseRef.id);

      const alreadyActive = device.exists && device.get('status') === 'active' && device.get('licenseId') === licenseRef.id;
      if (!alreadyActive) {
        const active = await tx.get(
          db.collection(`companies/${companyId}/authorizedDevices`)
            .where('licenseId', '==', licenseRef.id)
            .where('status', '==', 'active'),
        );
        if (active.size >= license.get('maxDevices')) throw new Denied('device_limit', licenseRef.id);
      }
      tx.set(deviceRef, {
        deviceId,
        companyId,
        licenseId: licenseRef.id,
        userId: uid,
        deviceModel: base.deviceModel,
        platform: str(d.platform, 20) ? d.platform : 'android',
        status: 'active',
        lastSeenAt: FieldValue.serverTimestamp(),
        ...(alreadyActive ? {} : { activatedAt: FieldValue.serverTimestamp() }),
      }, { merge: true });
      tx.update(licenseRef, { lastValidatedAt: FieldValue.serverTimestamp() });
      return {
        licenseId: licenseRef.id,
        licenseStatus: 'active' as const,
        deviceStatus: 'active' as const,
        validUntil: (license.get('validUntil') as Timestamp).toMillis(),
        maxDevices: license.get('maxDevices') as number,
        serverTime: now.getTime(),
        reactivated: alreadyActive,
      };
    });
    await audit(db, { type: state.reactivated ? 'device.revalidate' : 'device.activate', ...base, licenseId: state.licenseId });
    const { reactivated: _, ...result } = state;
    return result;
  } catch (e) {
    if (e instanceof Denied) {
      // Record date-based expiry outside the refused transaction (which rolls back).
      if (e.reason === 'expired' && e.licenseId) await markExpired(db, companyId, e.licenseId, now);
      if (e.reason === 'invalid_code') await consume(db, limitKey, LIMITS.codeFailures, now.getTime());
      await audit(db, { type: 'device.activate_denied', reason: e.reason, ...base, licenseId: e.licenseId ?? null });
      throw new HttpsError('failed-precondition', e.message, { reason: e.reason });
    }
    throw e;
  }
}

// --- validateLicense ---------------------------------------------------------

/**
 * Current license and device state for a device. Never throws for a
 * suspended/expired/revoked state — the app needs to show it.
 */
export async function validateLicense(
  db: Firestore,
  uid: string | undefined,
  data: unknown,
  now = new Date(),
): Promise<LicenseState> {
  const d = (data ?? {}) as Record<string, unknown>;
  if (!str(d.companyId) || !str(d.deviceId, 64)) {
    throw new HttpsError('invalid-argument', 'companyId and deviceId are required.');
  }
  await requireMember(db, uid, d.companyId);
  const deviceRef = db.doc(`companies/${d.companyId}/authorizedDevices/${d.deviceId}`);
  const device = await deviceRef.get();
  if (!device.exists || device.get('userId') !== uid) {
    return { licenseId: null, licenseStatus: 'none', deviceStatus: 'unknown', validUntil: null, maxDevices: null, serverTime: now.getTime() };
  }
  const licenseRef = db.doc(`companies/${d.companyId}/licenses/${device.get('licenseId')}`);
  const license = await licenseRef.get();
  const status = license.exists
    ? effectiveStatus(license.get('status'), license.get('validFrom'), license.get('validUntil'), now)
    : 'revoked';
  const batch = db.batch();
  if (status === 'expired' && license.get('status') === 'active') {
    batch.update(licenseRef, { status: 'expired', updatedAt: FieldValue.serverTimestamp() });
  }
  if (license.exists) batch.update(licenseRef, { lastValidatedAt: FieldValue.serverTimestamp() });
  if (device.get('status') === 'active') batch.update(deviceRef, { lastSeenAt: FieldValue.serverTimestamp() });
  await batch.commit();
  return {
    licenseId: license.exists ? license.id : null,
    licenseStatus: status,
    deviceStatus: device.get('status') === 'active' ? 'active' : 'revoked',
    validUntil: license.exists ? (license.get('validUntil') as Timestamp).toMillis() : null,
    maxDevices: license.exists ? (license.get('maxDevices') as number) : null,
    serverTime: now.getTime(),
  };
}
