import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { requireAdmin } from './admin.js';
import { effectiveStatus, hashCode, requireMember, str } from './licenses.js';
import { assertWithinLimit, consume, LIMITS } from './rateLimit.js';

/**
 * Device replacement (sprint doc §5.5): a phone that can't activate because
 * the license is full asks for a replacement; a developer admin approves by
 * revoking an old phone and authorizing the new one in one transaction, so
 * the device limit can never be exceeded. Old phones need not take part
 * (lost/damaged): they become read-only when they next reconnect, and their
 * local data is never touched.
 *
 *   companies/{companyId}/deviceReplacementRequests/{requestId}
 *     status: pending | approved | rejected
 *     licenseId, newDeviceId, newDeviceModel, requestedBy, requesterEmail,
 *     reason, createdAt, reviewedBy, reviewedAt, reviewReason, revokedDeviceId
 */

async function audit(db: Firestore, fields: Record<string, unknown>) {
  await db.collection('auditEvents').add({ ...fields, at: FieldValue.serverTimestamp() });
}

export async function requestDeviceReplacement(db: Firestore, uid: string | undefined, data: unknown, now = new Date()) {
  const d = (data ?? {}) as Record<string, unknown>;
  if (!str(d.companyId) || !str(d.activationCode, 40) || !str(d.newDeviceId, 64)) {
    throw new HttpsError('invalid-argument', 'companyId, activationCode and newDeviceId are required.');
  }
  if (typeof d.reason !== 'string' || d.reason.trim().length < 3 || d.reason.length > 500) {
    throw new HttpsError('invalid-argument', 'Say why the phone is being replaced.');
  }
  const companyId = d.companyId;
  const newDeviceId = d.newDeviceId;
  await requireMember(db, uid, companyId);
  const codeKey = `codeFailures_${uid}`;
  await assertWithinLimit(db, codeKey, LIMITS.codeFailures, now.getTime());

  // The activation code proves the requester was given access by the company.
  const matches = await db.collection(`companies/${companyId}/licenses`).where('activationCodeHash', '==', hashCode(d.activationCode)).limit(1).get();
  if (matches.empty) {
    await consume(db, codeKey, LIMITS.codeFailures, now.getTime());
    throw new HttpsError('failed-precondition', 'That activation code is not valid for this company.', { reason: 'invalid_code' });
  }
  const license = matches.docs[0];
  const status = effectiveStatus(license.get('status'), license.get('validFrom'), license.get('validUntil'), now);
  if (status !== 'active') throw new HttpsError('failed-precondition', `The license is ${status.replace('_', ' ')}.`, { reason: status });

  const device = await db.doc(`companies/${companyId}/authorizedDevices/${newDeviceId}`).get();
  if (device.exists && device.get('status') === 'active') return { requestId: null, status: 'already_active' };
  if (device.exists && device.get('status') === 'revoked') {
    throw new HttpsError('failed-precondition', 'This phone was deactivated. Reinstall the app to register it as a new phone.', { reason: 'device_revoked' });
  }

  const requests = db.collection(`companies/${companyId}/deviceReplacementRequests`);
  const open = await requests.where('newDeviceId', '==', newDeviceId).where('status', '==', 'pending').limit(1).get();
  if (!open.empty) return { requestId: open.docs[0].id, status: 'pending' };

  await consume(db, `replacementRequests_${uid}`, LIMITS.replacementRequests, now.getTime());
  const member = await db.doc(`companies/${companyId}/companyUsers/${uid}`).get();
  const ref = requests.doc();
  await ref.set({
    requestId: ref.id,
    companyId,
    companyName: (await db.doc(`companies/${companyId}`).get()).get('name') ?? null,
    licenseId: license.id,
    newDeviceId,
    newDeviceModel: str(d.newDeviceModel, 100) ? d.newDeviceModel : null,
    requestedBy: uid,
    requesterEmail: member.get('email') ?? null,
    reason: d.reason.trim(),
    status: 'pending',
    createdAt: FieldValue.serverTimestamp(),
  });
  await audit(db, { type: 'replacement.request', companyId, licenseId: license.id, deviceId: newDeviceId, actorId: uid, requestId: ref.id, reason: d.reason.trim() });
  return { requestId: ref.id, status: 'pending' };
}

export async function reviewReplacement(db: Firestore, uid: string | undefined, data: unknown, now = new Date()) {
  await requireAdmin(db, uid, 'devices.revoke');
  const d = (data ?? {}) as Record<string, unknown>;
  if (!str(d.companyId) || !str(d.requestId) || !['approve', 'reject'].includes(d.decision as string)) {
    throw new HttpsError('invalid-argument', 'companyId, requestId and decision (approve/reject) are required.');
  }
  if (typeof d.reason !== 'string' || d.reason.trim().length < 3) {
    throw new HttpsError('invalid-argument', 'A reason (at least 3 characters) is required.');
  }
  const reason = d.reason.trim();
  const companyId = d.companyId;
  const reqRef = db.doc(`companies/${companyId}/deviceReplacementRequests/${d.requestId}`);

  const outcome = await db.runTransaction(async (tx) => {
    const req = await tx.get(reqRef);
    if (!req.exists) throw new HttpsError('not-found', 'Request not found.');
    if (req.get('status') !== 'pending') throw new HttpsError('failed-precondition', `This request was already ${req.get('status')}.`);
    const review = { reviewedBy: uid, reviewedAt: FieldValue.serverTimestamp(), reviewReason: reason };

    if (d.decision === 'reject') {
      tx.update(reqRef, { status: 'rejected', ...review });
      return { status: 'rejected', revoked: null as string | null, req: req.data()! };
    }

    const licenseRef = db.doc(`companies/${companyId}/licenses/${req.get('licenseId')}`);
    const license = await tx.get(licenseRef);
    if (effectiveStatus(license.get('status'), license.get('validFrom'), license.get('validUntil'), now) !== 'active') {
      throw new HttpsError('failed-precondition', 'The license is not active; renew or reactivate it first.');
    }
    const newId = req.get('newDeviceId') as string;
    const newRef = db.doc(`companies/${companyId}/authorizedDevices/${newId}`);
    const [active, newDevice] = await Promise.all([
      tx.get(db.collection(`companies/${companyId}/authorizedDevices`).where('licenseId', '==', license.id).where('status', '==', 'active')),
      tx.get(newRef),
    ]);
    if (newDevice.exists && newDevice.get('status') === 'revoked') {
      throw new HttpsError('failed-precondition', 'The new phone was deactivated; it must reinstall the app.');
    }
    const revokeId = str(d.revokeDeviceId, 64) ? d.revokeDeviceId : null;
    if (revokeId && !active.docs.some((x) => x.id === revokeId)) {
      throw new HttpsError('invalid-argument', 'The phone to replace must be an active phone on this license.');
    }
    const alreadyActive = newDevice.exists && newDevice.get('status') === 'active';
    const activeAfter = active.size - (revokeId ? 1 : 0) + (alreadyActive ? 0 : 1);
    if (activeAfter > (license.get('maxDevices') as number)) {
      throw new HttpsError('failed-precondition', 'The license is full. Choose which phone this one replaces.', { reason: 'device_limit' });
    }
    if (revokeId) {
      tx.update(db.doc(`companies/${companyId}/authorizedDevices/${revokeId}`), {
        status: 'revoked',
        revokedAt: FieldValue.serverTimestamp(),
        revokedBy: uid,
        revokeReason: `Replaced by another phone: ${reason}`,
        replacedBy: newId,
      });
    }
    if (!alreadyActive) {
      tx.set(newRef, {
        deviceId: newId,
        companyId,
        licenseId: license.id,
        userId: req.get('requestedBy'),
        deviceModel: req.get('newDeviceModel') ?? null,
        platform: 'android',
        status: 'active',
        activatedAt: FieldValue.serverTimestamp(),
        lastSeenAt: FieldValue.serverTimestamp(),
        replacementForDeviceId: revokeId,
      });
    }
    tx.update(reqRef, { status: 'approved', revokedDeviceId: revokeId, ...review });
    return { status: 'approved', revoked: revokeId, req: req.data()! };
  });

  const base = { companyId, licenseId: outcome.req.licenseId, actorId: uid, requestId: d.requestId, reason };
  if (outcome.status === 'rejected') {
    await audit(db, { type: 'replacement.reject', ...base, deviceId: outcome.req.newDeviceId });
  } else {
    await audit(db, { type: 'replacement.approve', ...base, deviceId: outcome.req.newDeviceId, oldDeviceId: outcome.revoked });
    if (outcome.revoked) await audit(db, { type: 'device.revoke', ...base, deviceId: outcome.revoked });
    await audit(db, { type: 'device.activate', ...base, deviceId: outcome.req.newDeviceId, replacementFor: outcome.revoked });
  }
  return { status: outcome.status, revokedDeviceId: outcome.revoked };
}
