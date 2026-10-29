import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';
import {
  adminCreateCompany,
  adminUpdateCompany,
  revokeDevice,
  rotateActivationCode,
  setCompanyStatus,
  setLicenseStatus,
  updateLicense,
} from '../src/admin.js';
import { activateDevice, createLicense, hashCode } from '../src/licenses.js';

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error('Run via npm run test:functions');
const projectId = process.env.GCLOUD_PROJECT ?? 'demo-jcb-fn';
if (!getApps().length) initializeApp({ projectId });
const db = getFirestore();
const auth = getAuth();
const DAY = 86_400_000;

const profile = {
  name: 'Shinde Earthmovers',
  contactPerson: 'Amol Shinde',
  phone: '9876543210',
  address: 'Chakan, Pune',
  invoicePrefix: 'SHE',
  email: null,
  gstin: null,
};

beforeEach(async () => {
  const host = (v: string) => process.env[v];
  await fetch(`http://${host('FIRESTORE_EMULATOR_HOST')}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: 'DELETE' });
  await fetch(`http://${host('FIREBASE_AUTH_EMULATOR_HOST')}/emulator/v1/projects/${projectId}/accounts`, { method: 'DELETE' });
  await db.doc('developerAdmins/super').set({ email: 's@jcbworks.in', role: 'super' });
  await db.doc('developerAdmins/support').set({ email: 'h@jcbworks.in' }); // role missing → support
  await db.doc('developerAdmins/helper').set({ email: 'x@jcbworks.in', role: 'support', permissions: ['devices.revoke'] });
  await db.doc('companies/co1').set({ ...profile, id: 'co1', status: 'pending', ownerUid: 'owner' });
  await db.doc('companies/co1/companyUsers/owner').set({ uid: 'owner', role: 'owner', status: 'active' });
});

async function events(type: string) {
  return (await db.collection('auditEvents').where('type', '==', type).get()).docs.map((d) => d.data());
}

async function activeLicense(maxDevices = 2) {
  await db.doc('companies/co1').update({ status: 'active' });
  return createLicense(db, 'super', { companyId: 'co1', validFrom: Date.now() - DAY, validUntil: Date.now() + 30 * DAY, maxDevices });
}

describe('admin roles', () => {
  it('non-admins and members are refused everywhere', async () => {
    for (const fn of [
      () => setCompanyStatus(db, 'owner', { companyId: 'co1', status: 'active', reason: 'ok' }),
      () => adminUpdateCompany(db, 'owner', { companyId: 'co1', ...profile }),
      () => setLicenseStatus(db, undefined, {}),
      () => revokeDevice(db, 'owner', { companyId: 'co1', deviceId: 'd', reason: 'x' }),
    ]) {
      await expect(fn()).rejects.toMatchObject({ code: expect.stringMatching(/permission-denied|unauthenticated/) });
    }
  });

  it('support admins need explicit grants; super admins can do everything', async () => {
    await expect(setCompanyStatus(db, 'support', { companyId: 'co1', status: 'active', reason: 'Verified' })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(createLicense(db, 'support', { companyId: 'co1', validFrom: 0, validUntil: 1, maxDevices: 1 })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(setCompanyStatus(db, 'super', { companyId: 'co1', status: 'active', reason: 'Verified by phone' })).resolves.toEqual({ status: 'active' });
  });
});

describe('companies', () => {
  it('approve and suspend need a reason and are audited', async () => {
    await expect(setCompanyStatus(db, 'super', { companyId: 'co1', status: 'active' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(setCompanyStatus(db, 'super', { companyId: 'co1', status: 'deleted', reason: 'xyz' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await setCompanyStatus(db, 'super', { companyId: 'co1', status: 'active', reason: 'Verified by phone' });
    await setCompanyStatus(db, 'super', { companyId: 'co1', status: 'suspended', reason: 'Unpaid subscription' });
    expect((await db.doc('companies/co1').get()).get('status')).toBe('suspended');
    const e = await events('company.status');
    expect(e.map((x) => [x.from, x.to])).toEqual(expect.arrayContaining([['pending', 'active'], ['active', 'suspended']]));
    expect(e.find((x) => x.to === 'suspended')).toMatchObject({ actorId: 'super', reason: 'Unpaid subscription', companyId: 'co1' });
  });

  it('creates a company with an owner account (new or existing user)', async () => {
    const r = await adminCreateCompany(db, auth, 'super', { ...profile, ownerEmail: 'Owner@Shinde.in' });
    expect(r.newUser).toBe(true);
    const c = (await db.doc(`companies/${r.companyId}`).get()).data()!;
    expect(c).toMatchObject({ status: 'active', ownerUid: r.ownerUid, nameLower: 'shinde earthmovers', invoicePrefix: 'SHE' });
    const m = (await db.doc(`companies/${r.companyId}/companyUsers/${r.ownerUid}`).get()).data()!;
    expect(m).toMatchObject({ role: 'owner', status: 'active', email: 'owner@shinde.in' });
    const again = await adminCreateCompany(db, auth, 'super', { ...profile, name: 'Second Co', ownerEmail: 'owner@shinde.in' });
    expect(again).toMatchObject({ newUser: false, ownerUid: r.ownerUid });
    expect(await events('company.create')).toHaveLength(2);
  });

  it('validates company details', async () => {
    await expect(adminCreateCompany(db, auth, 'super', { ...profile, invoicePrefix: 'bad/x', ownerEmail: 'a@b.in' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(adminCreateCompany(db, auth, 'super', { ...profile, ownerEmail: 'nope' })).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('edits a profile and audits the changed fields only', async () => {
    await adminUpdateCompany(db, 'super', { companyId: 'co1', ...profile, name: 'Shinde Infra', phone: '9000000000' });
    const c = (await db.doc('companies/co1').get()).data()!;
    expect(c).toMatchObject({ name: 'Shinde Infra', nameLower: 'shinde infra', status: 'pending', ownerUid: 'owner' });
    const [e] = await events('company.update');
    expect(Object.keys(e.changed).sort()).toEqual(['name', 'phone']);
  });
});

describe('licenses', () => {
  it('suspend → reactivate → revoke (final); reason required', async () => {
    const { licenseId } = await activeLicense();
    const base = { companyId: 'co1', licenseId };
    await expect(setLicenseStatus(db, 'super', { ...base, status: 'suspended' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await setLicenseStatus(db, 'super', { ...base, status: 'suspended', reason: 'Payment overdue' });
    await setLicenseStatus(db, 'super', { ...base, status: 'active', reason: 'Paid' });
    await setLicenseStatus(db, 'super', { ...base, status: 'revoked', reason: 'Contract ended' });
    await expect(setLicenseStatus(db, 'super', { ...base, status: 'active', reason: 'Oops' })).rejects.toMatchObject({ code: 'failed-precondition' });
    expect((await events('license.status')).map((e) => e.to)).toEqual(expect.arrayContaining(['suspended', 'active', 'revoked']));
  });

  it('renewing an expired license reactivates it; ended licenses must be extended first', async () => {
    const { licenseId } = await activeLicense();
    const ref = db.doc(`companies/co1/licenses/${licenseId}`);
    await ref.update({ status: 'expired', validUntil: Timestamp.fromMillis(Date.now() - DAY) });
    await expect(setLicenseStatus(db, 'super', { companyId: 'co1', licenseId, status: 'active', reason: 'renew' })).rejects.toMatchObject({ code: 'failed-precondition' });
    const until = Date.now() + 365 * DAY;
    await updateLicense(db, 'super', { companyId: 'co1', licenseId, validUntil: until, reason: 'Annual renewal' });
    const l = (await ref.get()).data()!;
    expect(l.status).toBe('active');
    expect((l.validUntil as Timestamp).toMillis()).toBe(until);
    const [e] = await events('license.update');
    expect(e.changed.status).toEqual({ from: 'expired', to: 'active' });
  });

  it('device limit cannot drop below active devices', async () => {
    const { licenseId, activationCode } = await activeLicense(3);
    await activateDevice(db, 'owner', { companyId: 'co1', activationCode, deviceId: 'd1' });
    await activateDevice(db, 'owner', { companyId: 'co1', activationCode, deviceId: 'd2' });
    await expect(updateLicense(db, 'super', { companyId: 'co1', licenseId, maxDevices: 1, reason: 'downgrade' })).rejects.toMatchObject({ code: 'failed-precondition' });
    await updateLicense(db, 'super', { companyId: 'co1', licenseId, maxDevices: 2, reason: 'downgrade' });
    expect((await db.doc(`companies/co1/licenses/${licenseId}`).get()).get('maxDevices')).toBe(2);
  });

  it('rotating the code invalidates the old one', async () => {
    const { licenseId, activationCode: old } = await activeLicense();
    const { activationCode } = await rotateActivationCode(db, 'super', { companyId: 'co1', licenseId, reason: 'Code leaked' });
    const l = (await db.doc(`companies/co1/licenses/${licenseId}`).get()).data()!;
    expect(l.activationCodeHash).toBe(hashCode(activationCode));
    await expect(activateDevice(db, 'owner', { companyId: 'co1', activationCode: old, deviceId: 'd1' })).rejects.toMatchObject({ details: { reason: 'invalid_code' } });
    await expect(activateDevice(db, 'owner', { companyId: 'co1', activationCode, deviceId: 'd1' })).resolves.toMatchObject({ licenseStatus: 'active' });
    expect(await events('license.rotate_code')).toHaveLength(1);
  });

  it('stores the company name for listing', async () => {
    const { licenseId } = await activeLicense();
    expect((await db.doc(`companies/co1/licenses/${licenseId}`).get()).get('companyName')).toBe('Shinde Earthmovers');
  });
});

describe('devices', () => {
  it('revoke needs devices.revoke; revoked devices lose access', async () => {
    const { activationCode } = await activeLicense();
    await activateDevice(db, 'owner', { companyId: 'co1', activationCode, deviceId: 'd1' });
    await expect(revokeDevice(db, 'support', { companyId: 'co1', deviceId: 'd1', reason: 'Lost phone' })).rejects.toMatchObject({ code: 'permission-denied' });
    await revokeDevice(db, 'helper', { companyId: 'co1', deviceId: 'd1', reason: 'Lost phone' });
    const d = (await db.doc('companies/co1/authorizedDevices/d1').get()).data()!;
    expect(d).toMatchObject({ status: 'revoked', revokedBy: 'helper', revokeReason: 'Lost phone' });
    await expect(revokeDevice(db, 'super', { companyId: 'co1', deviceId: 'd1', reason: 'again' })).rejects.toMatchObject({ code: 'failed-precondition' });
    await expect(activateDevice(db, 'owner', { companyId: 'co1', activationCode, deviceId: 'd1' })).rejects.toMatchObject({ details: { reason: 'device_revoked' } });
    expect(await events('device.revoke')).toHaveLength(1);
  });
});
