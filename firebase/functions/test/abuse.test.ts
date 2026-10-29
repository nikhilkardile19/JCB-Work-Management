import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';
import { activateDevice, createLicense } from '../src/licenses.js';
import { assertWithinLimit, consume, LIMITS } from '../src/rateLimit.js';
import { requestDeviceReplacement } from '../src/replacements.js';
import { inviteCompanyUser } from '../src/users.js';

// Sprint 11: rate limits and abuse controls.
if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error('Run via npm run test:functions');
const projectId = process.env.GCLOUD_PROJECT ?? 'demo-jcb-fn';
if (!getApps().length) initializeApp({ projectId });
const db = getFirestore();
const auth = getAuth();
const DAY = 86_400_000;
const HOUR = 3_600_000;
let code = '';

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: 'DELETE' });
  await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/emulator/v1/projects/${projectId}/accounts`, { method: 'DELETE' });
  await db.doc('developerAdmins/super').set({ role: 'super' });
  await db.doc('companies/co1').set({ name: 'Sai Earthmovers', status: 'active' });
  for (const [uid, role] of Object.entries({ owner: 'owner', admin: 'admin', op: 'operator' })) {
    await db.doc(`companies/co1/companyUsers/${uid}`).set({ uid, role, status: 'active', email: `${uid}@sai.in` });
  }
  code = (await createLicense(db, 'super', { companyId: 'co1', validFrom: Date.now() - DAY, validUntil: Date.now() + 365 * DAY, maxDevices: 1 })).activationCode;
});

const WRONG = 'JCBW-AAAA-BBBB-CCCC';
const activate = (uid: string, activationCode: string, deviceId = `phone-${uid}`) =>
  activateDevice(db, uid, { companyId: 'co1', activationCode, deviceId });

describe('fixed-window counter', () => {
  const limit = { max: 3, windowMs: HOUR, message: 'Slow down' };

  it('allows max uses per window, then refuses until the window ends', async () => {
    const t = 1_000_000;
    for (let i = 0; i < 3; i++) await consume(db, 'k', limit, t + i);
    await expect(consume(db, 'k', limit, t + 10)).rejects.toMatchObject({ code: 'resource-exhausted', details: { reason: 'rate_limited' } });
    await expect(assertWithinLimit(db, 'k', limit, t + 10)).rejects.toMatchObject({ code: 'resource-exhausted' });
    await assertWithinLimit(db, 'k', limit, t + HOUR);
    await consume(db, 'k', limit, t + HOUR);
    const doc = (await db.doc('rateLimits/k').get()).data()!;
    expect(doc).toMatchObject({ windowStart: t + HOUR, count: 1 });
    expect(doc.expiresAt.toMillis()).toBe(t + 2 * HOUR);
  });

  it('keys are independent', async () => {
    for (let i = 0; i < 3; i++) await consume(db, 'a', limit);
    await consume(db, 'b', limit);
  });
});

describe('activation code guessing', () => {
  it('locks a user out after 10 wrong codes, even with the right code', async () => {
    for (let i = 0; i < LIMITS.codeFailures.max; i++) {
      await expect(activate('op', WRONG)).rejects.toMatchObject({ details: { reason: 'invalid_code' } });
    }
    await expect(activate('op', code)).rejects.toMatchObject({ code: 'resource-exhausted' });
    // Other users are unaffected.
    expect((await activate('owner', code)).deviceStatus).toBe('active');
  });

  it('successful activations and other refusals do not count', async () => {
    for (let i = 0; i < 12; i++) await activate('owner', code); // re-validation of the same phone
    await expect(activate('op', code)).rejects.toMatchObject({ details: { reason: 'device_limit' } });
    expect((await db.doc('rateLimits/codeFailures_owner').get()).exists).toBe(false);
    expect((await db.doc('rateLimits/codeFailures_op').get()).exists).toBe(false);
  });

  it('wrong codes on replacement requests count towards the same limit', async () => {
    const ask = (activationCode: string, newDeviceId = 'new-op') =>
      requestDeviceReplacement(db, 'op', { companyId: 'co1', activationCode, newDeviceId, reason: 'Phone lost' });
    for (let i = 0; i < 5; i++) await expect(activate('op', WRONG)).rejects.toBeTruthy();
    for (let i = 0; i < 5; i++) await expect(ask(WRONG)).rejects.toMatchObject({ details: { reason: 'invalid_code' } });
    await expect(ask(code)).rejects.toMatchObject({ code: 'resource-exhausted' });
  });

  it('activation codes have a sane length', async () => {
    await expect(activate('op', 'X'.repeat(5000))).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});

describe('replacement request flooding', () => {
  it('limits new requests per user per day; repeating a pending one is free', async () => {
    const ask = (newDeviceId: string) =>
      requestDeviceReplacement(db, 'op', { companyId: 'co1', activationCode: code, newDeviceId, reason: 'Phone lost' });
    for (let i = 0; i < LIMITS.replacementRequests.max; i++) await ask(`new-${i}`);
    await ask('new-0'); // already pending: returns the same request
    await expect(ask('new-x')).rejects.toMatchObject({ code: 'resource-exhausted' });
  });
});

describe('user invitations', () => {
  it('limits users added per company per day', async () => {
    await db.doc('rateLimits/invites_co1').set({ windowStart: Date.now(), count: LIMITS.invites.max });
    await expect(inviteCompanyUser(db, auth, 'owner', { companyId: 'co1', email: 'x@sai.in', role: 'operator' })).rejects.toMatchObject({ code: 'resource-exhausted' });
    expect((await auth.listUsers()).users).toHaveLength(0); // no account was created
  });

  it('an admin cannot re-enable an admin the owner disabled', async () => {
    const { userId } = await inviteCompanyUser(db, auth, 'owner', { companyId: 'co1', email: 'a2@sai.in', role: 'admin' });
    await db.doc(`companies/co1/companyUsers/${userId}`).update({ status: 'disabled' });
    await expect(inviteCompanyUser(db, auth, 'admin', { companyId: 'co1', email: 'a2@sai.in', role: 'operator' })).rejects.toMatchObject({ code: 'permission-denied' });
    await inviteCompanyUser(db, auth, 'owner', { companyId: 'co1', email: 'a2@sai.in', role: 'manager' });
  });

  it('rejects oversized emails', async () => {
    await expect(inviteCompanyUser(db, auth, 'owner', { companyId: 'co1', email: `${'a'.repeat(300)}@sai.in`, role: 'operator' })).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
