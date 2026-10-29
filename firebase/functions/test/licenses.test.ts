import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';
import { activateDevice, createLicense, generateActivationCode, hashCode, normalizeCode, validateLicense } from '../src/licenses.js';

if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run via npm run test:functions');
const projectId = process.env.GCLOUD_PROJECT ?? 'demo-jcb-fn';
if (!getApps().length) initializeApp({ projectId });
const db = getFirestore();

const NOW = new Date('2026-10-29T10:00:00Z');
const DAY = 86_400_000;

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: 'DELETE' });
  await db.doc('developerAdmins/dev').set({ email: 'dev@jcbworks.in', role: 'super' });
  await seedCompany('co1');
});

async function seedCompany(id: string, status = 'active', members: Record<string, string> = { owner: 'owner', op: 'operator', op2: 'operator' }) {
  await db.doc(`companies/${id}`).set({ status, invoicePrefix: 'SAI' });
  for (const [uid, role] of Object.entries(members)) {
    await db.doc(`companies/${id}/companyUsers/${uid}`).set({ uid, role, status: 'active' });
  }
}

async function license(opts: { maxDevices?: number; from?: number; until?: number; company?: string } = {}) {
  return createLicense(db, 'dev', {
    companyId: opts.company ?? 'co1',
    validFrom: opts.from ?? NOW.getTime() - DAY,
    validUntil: opts.until ?? NOW.getTime() + 365 * DAY,
    maxDevices: opts.maxDevices ?? 2,
  }, NOW);
}

const activate = (code: string, deviceId: string, uid = 'op', companyId = 'co1') =>
  activateDevice(db, uid, { companyId, activationCode: code, deviceId, deviceModel: 'Pixel 7', platform: 'android' }, NOW);

async function events(type: string) {
  return (await db.collection('auditEvents').where('type', '==', type).get()).docs.map((d) => d.data());
}

describe('activation codes', () => {
  it('are random, readable, and normalized for lookup', () => {
    const a = generateActivationCode();
    expect(a).toMatch(/^JCBW-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$/);
    expect(generateActivationCode()).not.toBe(a);
    expect(normalizeCode(' jcbw-7kq2 m9xd-pa4h ')).toBe('7KQ2M9XDPA4H');
    expect(hashCode('JCBW-7KQ2-M9XD-PA4H')).toBe(hashCode('7kq2-m9xd-pa4h'));
  });
});

describe('createLicense', () => {
  it('only developer admins can create licenses; the code is stored only as a hash', async () => {
    await expect(createLicense(db, 'owner', { companyId: 'co1', validFrom: 0, validUntil: 1, maxDevices: 1 })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(createLicense(db, undefined, {})).rejects.toMatchObject({ code: 'unauthenticated' });
    const { licenseId, activationCode } = await license();
    const doc = (await db.doc(`companies/co1/licenses/${licenseId}`).get()).data()!;
    expect(doc.status).toBe('active');
    expect(doc.activationCodeHash).toBe(hashCode(activationCode));
    expect(JSON.stringify(doc)).not.toContain(normalizeCode(activationCode));
    expect(await events('license.create')).toHaveLength(1);
  });

  it('validates input', async () => {
    for (const bad of [{}, { companyId: 'co1', validFrom: 10, validUntil: 5, maxDevices: 1 }, { companyId: 'co1', validFrom: 0, validUntil: 5, maxDevices: 0 }]) {
      await expect(createLicense(db, 'dev', bad)).rejects.toMatchObject({ code: 'invalid-argument' });
    }
    await expect(createLicense(db, 'dev', { companyId: 'nope', validFrom: 0, validUntil: 5, maxDevices: 1 })).rejects.toMatchObject({ code: 'not-found' });
  });
});

describe('activateDevice', () => {
  it('activates a device with a valid code and is idempotent for that device', async () => {
    const { activationCode, licenseId } = await license();
    const state = await activate(activationCode, 'dev-a');
    expect(state).toMatchObject({ licenseId, licenseStatus: 'active', deviceStatus: 'active', maxDevices: 2 });
    const device = (await db.doc('companies/co1/authorizedDevices/dev-a').get()).data()!;
    expect(device).toMatchObject({ status: 'active', licenseId, userId: 'op', deviceModel: 'Pixel 7' });
    await activate(activationCode, 'dev-a'); // reinstall / retry
    expect((await db.collection('companies/co1/authorizedDevices').get()).size).toBe(1);
    expect(await events('device.activate')).toHaveLength(1);
    expect(await events('device.revalidate')).toHaveLength(1);
  });

  it('enforces the device limit on the server', async () => {
    const { activationCode } = await license({ maxDevices: 2 });
    await activate(activationCode, 'dev-a');
    await activate(activationCode, 'dev-b', 'op2');
    await expect(activate(activationCode, 'dev-c', 'owner')).rejects.toMatchObject({ code: 'failed-precondition', details: { reason: 'device_limit' } });
    const denied = await events('device.activate_denied');
    expect(denied[0]).toMatchObject({ reason: 'device_limit', deviceId: 'dev-c' });
  });

  it('concurrent activations never exceed the limit', async () => {
    const { activationCode } = await license({ maxDevices: 3 });
    const results = await Promise.allSettled(Array.from({ length: 8 }, (_, i) => activate(activationCode, `dev-${i}`)));
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(3);
    const active = await db.collection('companies/co1/authorizedDevices').where('status', '==', 'active').get();
    expect(active.size).toBe(3);
  });

  it('denies wrong codes, codes of another company, and non-members', async () => {
    const { activationCode } = await license();
    await seedCompany('co2', 'active', { bob: 'owner' });
    await expect(activate('JCBW-AAAA-BBBB-CCCC', 'dev-a')).rejects.toMatchObject({ details: { reason: 'invalid_code' } });
    await expect(activate(activationCode, 'dev-b', 'bob', 'co2')).rejects.toMatchObject({ details: { reason: 'invalid_code' } });
    await expect(activate(activationCode, 'dev-c', 'stranger')).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(activateDevice(db, undefined, { companyId: 'co1', activationCode, deviceId: 'dev-d' }, NOW)).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('denies inactive companies', async () => {
    await seedCompany('pending-co', 'pending', { owner: 'owner' });
    await expect(activate('JCBW-AAAA-BBBB-CCCC', 'dev-a', 'owner', 'pending-co')).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('denies suspended, revoked, expired and not-yet-started licenses', async () => {
    for (const [status, reason] of [['suspended', 'suspended'], ['revoked', 'revoked']] as const) {
      const { activationCode, licenseId } = await license();
      await db.doc(`companies/co1/licenses/${licenseId}`).update({ status });
      await expect(activate(activationCode, `dev-${status}`)).rejects.toMatchObject({ details: { reason } });
    }
    const expired = await license({ from: NOW.getTime() - 400 * DAY, until: NOW.getTime() - DAY });
    await expect(activate(expired.activationCode, 'dev-x')).rejects.toMatchObject({ details: { reason: 'expired' } });
    expect((await db.doc(`companies/co1/licenses/${expired.licenseId}`).get()).get('status')).toBe('expired');
    const future = await license({ from: NOW.getTime() + DAY });
    await expect(activate(future.activationCode, 'dev-y')).rejects.toMatchObject({ details: { reason: 'not_started' } });
  });

  it('a revoked device cannot re-activate itself', async () => {
    const { activationCode } = await license();
    await activate(activationCode, 'dev-a');
    await db.doc('companies/co1/authorizedDevices/dev-a').update({ status: 'revoked' });
    await expect(activate(activationCode, 'dev-a')).rejects.toMatchObject({ details: { reason: 'device_revoked' } });
  });
});

describe('validateLicense', () => {
  it('reports active state and refreshes lastSeen', async () => {
    const { activationCode, licenseId } = await license();
    await activate(activationCode, 'dev-a');
    const s = await validateLicense(db, 'op', { companyId: 'co1', deviceId: 'dev-a' }, NOW);
    expect(s).toMatchObject({ licenseId, licenseStatus: 'active', deviceStatus: 'active' });
    expect((await db.doc(`companies/co1/licenses/${licenseId}`).get()).get('lastValidatedAt')).toBeTruthy();
  });

  it('reports unknown devices, revoked devices and expiry without throwing', async () => {
    const { activationCode, licenseId } = await license();
    expect(await validateLicense(db, 'op', { companyId: 'co1', deviceId: 'never' }, NOW)).toMatchObject({ licenseStatus: 'none', deviceStatus: 'unknown' });
    await activate(activationCode, 'dev-a');
    // Another user can't use someone else's device record.
    expect(await validateLicense(db, 'op2', { companyId: 'co1', deviceId: 'dev-a' }, NOW)).toMatchObject({ deviceStatus: 'unknown' });
    await db.doc('companies/co1/authorizedDevices/dev-a').update({ status: 'revoked' });
    expect(await validateLicense(db, 'op', { companyId: 'co1', deviceId: 'dev-a' }, NOW)).toMatchObject({ deviceStatus: 'revoked' });
    await db.doc('companies/co1/authorizedDevices/dev-a').update({ status: 'active' });
    await db.doc(`companies/co1/licenses/${licenseId}`).update({ validUntil: Timestamp.fromMillis(NOW.getTime() - 1) });
    expect(await validateLicense(db, 'op', { companyId: 'co1', deviceId: 'dev-a' }, NOW)).toMatchObject({ licenseStatus: 'expired' });
    await db.doc(`companies/co1/licenses/${licenseId}`).update({ status: 'suspended' });
    expect(await validateLicense(db, 'op', { companyId: 'co1', deviceId: 'dev-a' }, NOW)).toMatchObject({ licenseStatus: 'suspended' });
  });

  it('non-members are refused', async () => {
    await expect(validateLicense(db, 'stranger', { companyId: 'co1', deviceId: 'x' }, NOW)).rejects.toMatchObject({ code: 'permission-denied' });
  });
});
