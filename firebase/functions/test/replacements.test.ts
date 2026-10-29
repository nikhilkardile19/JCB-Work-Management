import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';
import { activateDevice, createLicense, validateLicense } from '../src/licenses.js';
import { requestDeviceReplacement, reviewReplacement } from '../src/replacements.js';
import { inviteCompanyUser, setCompanyUserRole, setCompanyUserStatus } from '../src/users.js';

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error('Run via npm run test:functions');
const projectId = process.env.GCLOUD_PROJECT ?? 'demo-jcb-fn';
if (!getApps().length) initializeApp({ projectId });
const db = getFirestore();
const auth = getAuth();
const DAY = 86_400_000;
let code = '';

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: 'DELETE' });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: 'DELETE' });
  await db.doc('developerAdmins/super').set({ role: 'super' });
  await db.doc('developerAdmins/reader').set({ role: 'support' });
  await db.doc('companies/co1').set({ name: 'Sai Earthmovers', status: 'active' });
  for (const [uid, role] of Object.entries({ owner: 'owner', admin: 'admin', mgr: 'manager', op: 'operator' })) {
    await db.doc(`companies/co1/companyUsers/${uid}`).set({ uid, role, status: 'active', email: `${uid}@sai.in` });
  }
  code = (await createLicense(db, 'super', { companyId: 'co1', validFrom: Date.now() - DAY, validUntil: Date.now() + 365 * DAY, maxDevices: 2 })).activationCode;
  await activateDevice(db, 'owner', { companyId: 'co1', activationCode: code, deviceId: 'old-owner' });
  await activateDevice(db, 'op', { companyId: 'co1', activationCode: code, deviceId: 'old-op' });
});

const request = (uid: string, newDeviceId: string, extra: Record<string, unknown> = {}) =>
  requestDeviceReplacement(db, uid, { companyId: 'co1', activationCode: code, newDeviceId, newDeviceModel: 'android 15', reason: 'Phone fell in a trench', ...extra });

const review = (requestId: string, decision: 'approve' | 'reject', extra: Record<string, unknown> = {}) =>
  reviewReplacement(db, 'super', { companyId: 'co1', requestId, decision, reason: 'Verified with owner', ...extra });

const device = async (id: string) => (await db.doc(`companies/co1/authorizedDevices/${id}`).get()).data();
const activeCount = async () => (await db.collection('companies/co1/authorizedDevices').where('status', '==', 'active').get()).size;
const events = async (type: string) => (await db.collection('auditEvents').where('type', '==', type).get()).docs.map((d) => d.data());

describe('requesting a replacement', () => {
  it('the full license refuses activation; the new phone files a request instead', async () => {
    await expect(activateDevice(db, 'op', { companyId: 'co1', activationCode: code, deviceId: 'new-op' })).rejects.toMatchObject({ details: { reason: 'device_limit' } });
    const r = await request('op', 'new-op');
    expect(r.status).toBe('pending');
    const doc = (await db.doc(`companies/co1/deviceReplacementRequests/${r.requestId}`).get()).data()!;
    expect(doc).toMatchObject({ status: 'pending', newDeviceId: 'new-op', requestedBy: 'op', requesterEmail: 'op@sai.in', companyName: 'Sai Earthmovers' });
    expect(await events('replacement.request')).toHaveLength(1);
  });

  it('is idempotent per new phone and needs the activation code and a reason', async () => {
    const a = await request('op', 'new-op');
    const b = await request('op', 'new-op');
    expect(b.requestId).toBe(a.requestId);
    await expect(request('op', 'x', { activationCode: 'JCBW-AAAA-BBBB-CCCC' })).rejects.toMatchObject({ details: { reason: 'invalid_code' } });
    await expect(request('op', 'y', { reason: '' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(request('stranger', 'z')).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('an already-active phone needs nothing; a revoked phone must reinstall', async () => {
    expect(await request('op', 'old-op')).toEqual({ requestId: null, status: 'already_active' });
    await db.doc('companies/co1/authorizedDevices/old-op').update({ status: 'revoked' });
    await expect(request('op', 'old-op')).rejects.toMatchObject({ details: { reason: 'device_revoked' } });
  });
});

describe('reviewing', () => {
  it('approve swaps phones atomically; the limit is never exceeded', async () => {
    const { requestId } = await request('op', 'new-op');
    // Without choosing a phone to replace, a full license refuses.
    await expect(review(requestId!, 'approve')).rejects.toMatchObject({ details: { reason: 'device_limit' } });
    expect(await activeCount()).toBe(2);
    const r = await review(requestId!, 'approve', { revokeDeviceId: 'old-op' });
    expect(r).toEqual({ status: 'approved', revokedDeviceId: 'old-op' });
    expect(await device('old-op')).toMatchObject({ status: 'revoked', replacedBy: 'new-op' });
    expect(await device('new-op')).toMatchObject({ status: 'active', userId: 'op', replacementForDeviceId: 'old-op', licenseId: expect.any(String) });
    expect(await activeCount()).toBe(2);
    // The new phone is licensed; the old one is told it's revoked.
    expect(await validateLicense(db, 'op', { companyId: 'co1', deviceId: 'new-op' })).toMatchObject({ licenseStatus: 'active', deviceStatus: 'active' });
    expect(await validateLicense(db, 'op', { companyId: 'co1', deviceId: 'old-op' })).toMatchObject({ deviceStatus: 'revoked' });
    expect(await events('replacement.approve')).toHaveLength(1);
    expect((await events('device.revoke'))[0]).toMatchObject({ deviceId: 'old-op', requestId });
  });

  it('old phone lost or destroyed: approval needs nothing from it', async () => {
    // The old phone never reconnects; its record still says active.
    const { requestId } = await request('owner', 'new-owner', { reason: 'Phone stolen at site' });
    await review(requestId!, 'approve', { revokeDeviceId: 'old-owner' });
    expect(await device('old-owner')).toMatchObject({ status: 'revoked' });
    // If the stolen phone turns up online later, it cannot reactivate itself.
    await expect(activateDevice(db, 'owner', { companyId: 'co1', activationCode: code, deviceId: 'old-owner' })).rejects.toMatchObject({ details: { reason: 'device_revoked' } });
  });

  it('a free slot allows approval without revoking anything', async () => {
    await db.doc('companies/co1/authorizedDevices/old-op').update({ status: 'revoked' });
    const { requestId } = await request('op', 'new-op');
    expect(await review(requestId!, 'approve')).toEqual({ status: 'approved', revokedDeviceId: null });
    expect(await activeCount()).toBe(2);
  });

  it('reject keeps the new phone inactive and records the reason', async () => {
    const { requestId } = await request('op', 'new-op');
    await review(requestId!, 'reject', { reason: 'Not a company phone' });
    expect(await device('new-op')).toBeUndefined();
    expect((await db.doc(`companies/co1/deviceReplacementRequests/${requestId}`).get()).data()).toMatchObject({ status: 'rejected', reviewReason: 'Not a company phone', reviewedBy: 'super' });
    await expect(activateDevice(db, 'op', { companyId: 'co1', activationCode: code, deviceId: 'new-op' })).rejects.toMatchObject({ details: { reason: 'device_limit' } });
    await expect(review(requestId!, 'approve', { revokeDeviceId: 'old-op' })).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('two approvals racing for the last slot cannot both win', async () => {
    await db.doc('companies/co1/authorizedDevices/old-op').update({ status: 'revoked' });
    const a = await request('op', 'new-a');
    const b = await request('mgr', 'new-b');
    const results = await Promise.allSettled([review(a.requestId!, 'approve'), review(b.requestId!, 'approve')]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect(await activeCount()).toBe(2);
  });

  it('only admins with devices.revoke can review; reasons are required; inactive licenses refuse', async () => {
    const { requestId } = await request('op', 'new-op');
    await expect(reviewReplacement(db, 'reader', { companyId: 'co1', requestId, decision: 'reject', reason: 'no' })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(reviewReplacement(db, 'owner', { companyId: 'co1', requestId, decision: 'reject', reason: 'nope' })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(review(requestId!, 'reject', { reason: '' })).rejects.toMatchObject({ code: 'invalid-argument' });
    const lic = (await db.collection('companies/co1/licenses').get()).docs[0];
    await lic.ref.update({ status: 'suspended' });
    await expect(review(requestId!, 'approve', { revokeDeviceId: 'old-op' })).rejects.toMatchObject({ code: 'failed-precondition' });
  });
});

describe('company users', () => {
  it('owner invites, changes roles and disables; actions are audited', async () => {
    const r = await inviteCompanyUser(db, auth, 'owner', { companyId: 'co1', email: 'New.Op@Sai.in', role: 'operator' });
    expect(r.newUser).toBe(true);
    const m = (await db.doc(`companies/co1/companyUsers/${r.userId}`).get()).data()!;
    expect(m).toMatchObject({ email: 'new.op@sai.in', role: 'operator', status: 'active', invitedBy: 'owner' });
    await expect(inviteCompanyUser(db, auth, 'owner', { companyId: 'co1', email: 'new.op@sai.in', role: 'operator' })).rejects.toMatchObject({ code: 'already-exists' });
    await setCompanyUserRole(db, 'owner', { companyId: 'co1', userId: r.userId, role: 'manager' });
    await setCompanyUserStatus(db, 'owner', { companyId: 'co1', userId: r.userId, status: 'disabled' });
    expect((await db.doc(`companies/co1/companyUsers/${r.userId}`).get()).get('status')).toBe('disabled');
    // Re-inviting a disabled member re-enables them.
    await inviteCompanyUser(db, auth, 'owner', { companyId: 'co1', email: 'new.op@sai.in', role: 'accounts' });
    expect((await db.doc(`companies/co1/companyUsers/${r.userId}`).get()).data()).toMatchObject({ status: 'active', role: 'accounts' });
    expect((await events('user.role'))[0]).toMatchObject({ from: 'operator', to: 'manager', actorId: 'owner' });
  });

  it('admins manage staff but not admins or the owner; nobody changes themselves', async () => {
    await expect(inviteCompanyUser(db, auth, 'admin', { companyId: 'co1', email: 'a2@sai.in', role: 'admin' })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(setCompanyUserRole(db, 'admin', { companyId: 'co1', userId: 'op', role: 'admin' })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(setCompanyUserStatus(db, 'admin', { companyId: 'co1', userId: 'owner', status: 'disabled' })).rejects.toMatchObject({ code: 'failed-precondition' });
    await expect(setCompanyUserStatus(db, 'admin', { companyId: 'co1', userId: 'admin', status: 'disabled' })).rejects.toMatchObject({ code: 'failed-precondition' });
    await expect(setCompanyUserRole(db, 'owner', { companyId: 'co1', userId: 'owner', role: 'operator' })).rejects.toMatchObject({ code: 'failed-precondition' });
    await setCompanyUserRole(db, 'admin', { companyId: 'co1', userId: 'op', role: 'manager' });
    await setCompanyUserRole(db, 'owner', { companyId: 'co1', userId: 'admin', role: 'manager' });
  });

  it('managers, operators and outsiders cannot manage users', async () => {
    for (const uid of ['mgr', 'op', 'stranger']) {
      await expect(inviteCompanyUser(db, auth, uid, { companyId: 'co1', email: 'x@sai.in', role: 'operator' })).rejects.toMatchObject({ code: 'permission-denied' });
    }
    await expect(inviteCompanyUser(db, auth, 'owner', { companyId: 'co1', email: 'x@sai.in', role: 'owner' })).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
