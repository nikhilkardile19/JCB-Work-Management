import { randomBytes } from 'node:crypto';
import type { Auth } from 'firebase-admin/auth';
import { FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { generateActivationCode, hashCode } from './licenses.js';

/**
 * Developer-admin operations. Admins are `developerAdmins/{uid}` with
 *   role: 'super' | 'support' (missing = 'support', least privilege)
 *   permissions: string[]  (extra grants for support admins)
 * Super admins may do everything; support admins only what is granted.
 * Every change is written to `auditEvents` with before/after values.
 */
export type AdminPermission =
  | 'companies.manage'
  | 'licenses.manage'
  | 'devices.revoke';

export async function requireAdmin(db: Firestore, uid: string | undefined, permission?: AdminPermission) {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  const admin = await db.doc(`developerAdmins/${uid}`).get();
  if (!admin.exists) throw new HttpsError('permission-denied', 'Developer admins only.');
  const role = admin.get('role') === 'super' ? 'super' : 'support';
  const granted: string[] = admin.get('permissions') ?? [];
  if (permission && role !== 'super' && !granted.includes(permission)) {
    throw new HttpsError('permission-denied', `Your admin role does not allow ${permission}.`);
  }
  return { role, email: (admin.get('email') as string | undefined) ?? null };
}

const str = (v: unknown, min = 1, max = 200): v is string => typeof v === 'string' && v.trim().length >= min && v.length <= max;
const id = (v: unknown): v is string => str(v, 1, 128) && !(v as string).includes('/');

function reason(d: Record<string, unknown>): string {
  if (!str(d.reason, 3, 500)) throw new HttpsError('invalid-argument', 'A reason (3–500 characters) is required.');
  return (d.reason as string).trim();
}

async function audit(db: Firestore, actorId: string, type: string, fields: Record<string, unknown>) {
  await db.collection('auditEvents').add({ type, actorId, ...fields, at: FieldValue.serverTimestamp() });
}

async function existing(db: Firestore, path: string, what: string) {
  const snap = await db.doc(path).get();
  if (!snap.exists) throw new HttpsError('not-found', `${what} not found.`);
  return snap;
}

// --- Companies ----------------------------------------------------------------

const COMPANY_STATUSES = ['pending', 'active', 'suspended'] as const;

/** Approve, suspend or reactivate a company. */
export async function setCompanyStatus(db: Firestore, uid: string | undefined, data: unknown) {
  await requireAdmin(db, uid, 'companies.manage');
  const d = (data ?? {}) as Record<string, unknown>;
  if (!id(d.companyId) || !COMPANY_STATUSES.includes(d.status as never)) {
    throw new HttpsError('invalid-argument', 'companyId and a valid status are required.');
  }
  const why = reason(d);
  const before = await existing(db, `companies/${d.companyId}`, 'Company');
  await before.ref.update({ status: d.status, updatedAt: FieldValue.serverTimestamp(), updatedBy: uid });
  await audit(db, uid!, 'company.status', { companyId: d.companyId, from: before.get('status'), to: d.status, reason: why });
  return { status: d.status };
}

interface ProfileInput {
  name: string;
  contactPerson: string;
  phone: string;
  address: string;
  invoicePrefix: string;
  email: string | null;
  gstin: string | null;
}

function profile(d: Record<string, unknown>): ProfileInput {
  const ok = str(d.name, 2, 120) && str(d.contactPerson, 1, 120) && str(d.phone, 10, 20) && str(d.address, 5, 500)
    && typeof d.invoicePrefix === 'string' && /^[A-Z0-9-]{1,10}$/.test(d.invoicePrefix)
    && (d.gstin == null || (typeof d.gstin === 'string' && /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/.test(d.gstin)))
    && (d.email == null || (typeof d.email === 'string' && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(d.email)));
  if (!ok) throw new HttpsError('invalid-argument', 'Check the company details (name, contact, phone, address, invoice prefix, GSTIN, email).');
  return {
    name: (d.name as string).trim(),
    contactPerson: (d.contactPerson as string).trim(),
    phone: (d.phone as string).trim(),
    address: (d.address as string).trim(),
    invoicePrefix: d.invoicePrefix as string,
    email: (d.email as string | null) ?? null,
    gstin: (d.gstin as string | null) ?? null,
  };
}

/**
 * Create a company on behalf of a customer. The owner account is created if
 * needed (random password; the owner sets their own with "Forgot password").
 */
export async function adminCreateCompany(db: Firestore, auth: Auth, uid: string | undefined, data: unknown) {
  await requireAdmin(db, uid, 'companies.manage');
  const d = (data ?? {}) as Record<string, unknown>;
  const p = profile(d);
  if (typeof d.ownerEmail !== 'string' || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(d.ownerEmail)) {
    throw new HttpsError('invalid-argument', 'A valid owner email is required.');
  }
  const ownerEmail = d.ownerEmail.trim().toLowerCase();
  let owner;
  let newUser = false;
  try {
    owner = await auth.getUserByEmail(ownerEmail);
  } catch {
    owner = await auth.createUser({ email: ownerEmail, password: randomBytes(24).toString('base64url') });
    newUser = true;
  }
  const ref = db.collection('companies').doc();
  const batch = db.batch();
  batch.set(ref, {
    ...p,
    id: ref.id,
    nameLower: p.name.toLowerCase(),
    currency: 'INR',
    status: 'active',
    ownerUid: owner.uid,
    createdBy: uid,
    updatedBy: uid,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    schemaVersion: 1,
  });
  batch.set(ref.collection('companyUsers').doc(owner.uid), {
    uid: owner.uid,
    companyId: ref.id,
    email: ownerEmail,
    role: 'owner',
    status: 'active',
    createdAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  await audit(db, uid!, 'company.create', { companyId: ref.id, name: p.name, ownerEmail, newUser });
  return { companyId: ref.id, ownerUid: owner.uid, newUser };
}

/** Edit a company profile (never status, owner or id). */
export async function adminUpdateCompany(db: Firestore, uid: string | undefined, data: unknown) {
  await requireAdmin(db, uid, 'companies.manage');
  const d = (data ?? {}) as Record<string, unknown>;
  if (!id(d.companyId)) throw new HttpsError('invalid-argument', 'companyId is required.');
  const p = profile(d);
  const before = await existing(db, `companies/${d.companyId}`, 'Company');
  await before.ref.update({ ...p, nameLower: p.name.toLowerCase(), updatedAt: FieldValue.serverTimestamp(), updatedBy: uid });
  const changed = Object.fromEntries(
    Object.entries(p).filter(([k, v]) => before.get(k) !== v).map(([k, v]) => [k, { from: before.get(k) ?? null, to: v }]),
  );
  await audit(db, uid!, 'company.update', { companyId: d.companyId, changed });
  return { ok: true };
}

// --- Licenses -----------------------------------------------------------------

const LICENSE_STATUSES = ['active', 'suspended', 'revoked'] as const;

/** Suspend, reactivate or revoke a license (expiry is by date). */
export async function setLicenseStatus(db: Firestore, uid: string | undefined, data: unknown) {
  await requireAdmin(db, uid, 'licenses.manage');
  const d = (data ?? {}) as Record<string, unknown>;
  if (!id(d.companyId) || !id(d.licenseId) || !LICENSE_STATUSES.includes(d.status as never)) {
    throw new HttpsError('invalid-argument', 'companyId, licenseId and status (active/suspended/revoked) are required.');
  }
  const why = reason(d);
  const before = await existing(db, `companies/${d.companyId}/licenses/${d.licenseId}`, 'License');
  if (before.get('status') === 'revoked') throw new HttpsError('failed-precondition', 'A revoked license cannot be changed. Create a new license.');
  if (d.status === 'active' && (before.get('validUntil') as Timestamp).toMillis() < Date.now()) {
    throw new HttpsError('failed-precondition', 'This license has ended. Extend it before reactivating.');
  }
  await before.ref.update({ status: d.status, updatedAt: FieldValue.serverTimestamp() });
  await audit(db, uid!, 'license.status', { companyId: d.companyId, licenseId: d.licenseId, from: before.get('status'), to: d.status, reason: why });
  return { status: d.status };
}

/** Change the end date (renewal) and/or the device limit. */
export async function updateLicense(db: Firestore, uid: string | undefined, data: unknown) {
  await requireAdmin(db, uid, 'licenses.manage');
  const d = (data ?? {}) as Record<string, unknown>;
  if (!id(d.companyId) || !id(d.licenseId)) throw new HttpsError('invalid-argument', 'companyId and licenseId are required.');
  const why = reason(d);
  const before = await existing(db, `companies/${d.companyId}/licenses/${d.licenseId}`, 'License');
  if (before.get('status') === 'revoked') throw new HttpsError('failed-precondition', 'A revoked license cannot be changed.');
  const changes: Record<string, unknown> = {};
  const changed: Record<string, unknown> = {};
  if (d.validUntil !== undefined) {
    if (typeof d.validUntil !== 'number' || d.validUntil <= (before.get('validFrom') as Timestamp).toMillis()) {
      throw new HttpsError('invalid-argument', 'validUntil must be after the start date.');
    }
    changes.validUntil = Timestamp.fromMillis(d.validUntil);
    changed.validUntil = { from: (before.get('validUntil') as Timestamp).toMillis(), to: d.validUntil };
    // A renewed license that had lapsed by date becomes active again.
    if (before.get('status') === 'expired' && d.validUntil > Date.now()) {
      changes.status = 'active';
      changed.status = { from: 'expired', to: 'active' };
    }
  }
  if (d.maxDevices !== undefined) {
    const n = d.maxDevices;
    if (typeof n !== 'number' || !Number.isInteger(n) || n < 1 || n > 100) {
      throw new HttpsError('invalid-argument', 'maxDevices must be 1–100.');
    }
    const active = await db.collection(`companies/${d.companyId}/authorizedDevices`)
      .where('licenseId', '==', d.licenseId).where('status', '==', 'active').count().get();
    if (n < active.data().count) {
      throw new HttpsError('failed-precondition', `${active.data().count} devices are active. Revoke some before lowering the limit to ${n}.`);
    }
    changes.maxDevices = n;
    changed.maxDevices = { from: before.get('maxDevices'), to: n };
  }
  if (!Object.keys(changes).length) throw new HttpsError('invalid-argument', 'Nothing to change.');
  await before.ref.update({ ...changes, updatedAt: FieldValue.serverTimestamp() });
  await audit(db, uid!, 'license.update', { companyId: d.companyId, licenseId: d.licenseId, changed, reason: why });
  return { ok: true };
}

/** Issue a new activation code; the old one stops working. Shown once. */
export async function rotateActivationCode(db: Firestore, uid: string | undefined, data: unknown) {
  await requireAdmin(db, uid, 'licenses.manage');
  const d = (data ?? {}) as Record<string, unknown>;
  if (!id(d.companyId) || !id(d.licenseId)) throw new HttpsError('invalid-argument', 'companyId and licenseId are required.');
  const why = reason(d);
  const before = await existing(db, `companies/${d.companyId}/licenses/${d.licenseId}`, 'License');
  if (before.get('status') === 'revoked') throw new HttpsError('failed-precondition', 'A revoked license cannot be changed.');
  const activationCode = generateActivationCode();
  await before.ref.update({ activationCodeHash: hashCode(activationCode), updatedAt: FieldValue.serverTimestamp() });
  await audit(db, uid!, 'license.rotate_code', { companyId: d.companyId, licenseId: d.licenseId, reason: why });
  return { activationCode };
}

// --- Devices ------------------------------------------------------------------

/** Deactivate a phone; it loses write access as soon as it reconnects. */
export async function revokeDevice(db: Firestore, uid: string | undefined, data: unknown) {
  await requireAdmin(db, uid, 'devices.revoke');
  const d = (data ?? {}) as Record<string, unknown>;
  if (!id(d.companyId) || !id(d.deviceId)) throw new HttpsError('invalid-argument', 'companyId and deviceId are required.');
  const why = reason(d);
  const before = await existing(db, `companies/${d.companyId}/authorizedDevices/${d.deviceId}`, 'Device');
  if (before.get('status') === 'revoked') throw new HttpsError('failed-precondition', 'This device is already revoked.');
  await before.ref.update({ status: 'revoked', revokedAt: FieldValue.serverTimestamp(), revokedBy: uid, revokeReason: why });
  await audit(db, uid!, 'device.revoke', { companyId: d.companyId, deviceId: d.deviceId, licenseId: before.get('licenseId'), reason: why });
  return { ok: true };
}
