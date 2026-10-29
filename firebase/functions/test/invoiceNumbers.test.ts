import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { beforeEach, describe, expect, it } from 'vitest';
import { allocateInvoiceNumber } from '../src/invoiceNumbers.js';

// Runs against the Firestore emulator (FIRESTORE_EMULATOR_HOST set by
// `firebase emulators:exec`).
if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Run via npm run test:functions');
const projectId = process.env.GCLOUD_PROJECT ?? 'demo-jcb-fn';
if (!getApps().length) initializeApp({ projectId });
const db = getFirestore();

async function seed(companyId: string, opts: { status?: string; prefix?: string; members?: Record<string, [string, string]> } = {}) {
  const c = db.collection('companies').doc(companyId);
  await c.set({ status: opts.status ?? 'active', invoicePrefix: opts.prefix ?? 'SAI' });
  await c.collection('licenses').doc('lic1').set({
    status: 'active',
    validFrom: Timestamp.fromMillis(Date.now() - 86_400_000),
    validUntil: Timestamp.fromMillis(Date.now() + 365 * 86_400_000),
    maxDevices: 10,
  });
  for (const [uid, [role, status]] of Object.entries(opts.members ?? { owner: ['owner', 'active'] })) {
    await c.collection('companyUsers').doc(uid).set({ uid, role, status });
    await c.collection('authorizedDevices').doc(`dev-${uid}`).set({ licenseId: 'lic1', userId: uid, status: 'active' });
  }
}

/** Calls from the member's own activated phone unless [deviceId] says otherwise. */
const alloc = (uid: string | undefined, r: Record<string, unknown>, deviceId = `dev-${uid}`) =>
  allocateInvoiceNumber(db, uid, { deviceId, ...r });

const req = (invoiceId: string, financialYear = '2026-27', companyId = 'co1') => ({ companyId, invoiceId, financialYear });

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: 'DELETE' });
});

describe('allocateInvoiceNumber', () => {
  it('issues sequential numbers per company and financial year with the company prefix', async () => {
    await seed('co1');
    expect(await alloc('owner', req('a'))).toEqual({ invoiceNumber: 'SAI/2026-27/0001' });
    expect((await alloc('owner', req('b'))).invoiceNumber).toBe('SAI/2026-27/0002');
    expect((await alloc('owner', req('c', '2027-28'))).invoiceNumber).toBe('SAI/2027-28/0001');
  });

  it('is idempotent per invoice (safe to retry)', async () => {
    await seed('co1');
    const first = await alloc('owner', req('a'));
    const retry = await alloc('owner', req('a'));
    expect(retry).toEqual(first);
    expect((await alloc('owner', req('b'))).invoiceNumber).toBe('SAI/2026-27/0002');
  });

  it('never issues duplicates under concurrent requests from many devices', async () => {
    await seed('co1');
    const results = await Promise.all(Array.from({ length: 12 }, (_, i) => alloc('owner', req(`inv-${i}`))));
    const numbers = results.map((r) => r.invoiceNumber).sort();
    expect(new Set(numbers).size).toBe(12);
    expect(numbers[0]).toBe('SAI/2026-27/0001');
    expect(numbers[11]).toBe('SAI/2026-27/0012');
  });

  it('companies have independent sequences', async () => {
    await seed('co1');
    await seed('co2', { prefix: 'PATIL' });
    await alloc('owner', req('a'));
    expect((await alloc('owner', req('a', '2026-27', 'co2'))).invoiceNumber).toBe('PATIL/2026-27/0001');
  });

  it('rejects unauthenticated, non-members, wrong roles and inactive members', async () => {
    await seed('co1', { members: { owner: ['owner', 'active'], op: ['operator', 'active'], acc: ['accounts', 'active'], gone: ['admin', 'disabled'] } });
    await expect(alloc(undefined, req('a'))).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(alloc('stranger', req('a'))).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(alloc('op', req('a'))).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(alloc('gone', req('a'))).rejects.toMatchObject({ code: 'permission-denied' });
    expect((await alloc('acc', req('a'))).invoiceNumber).toBe('SAI/2026-27/0001');
  });

  it('a member of company A cannot number company B invoices', async () => {
    await seed('co1');
    await seed('co2', { members: { other: ['owner', 'active'] } });
    await expect(alloc('owner', req('a', '2026-27', 'co2'))).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('requires an active company', async () => {
    await seed('co1', { status: 'pending' });
    await expect(alloc('owner', req('a'))).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('only an activated phone on an active license can take numbers', async () => {
    await seed('co1');
    await expect(alloc('owner', req('a'), 'unknown-phone')).rejects.toMatchObject({ details: { reason: 'license' } });
    await db.doc('companies/co1/authorizedDevices/dev-other').set({ licenseId: 'lic1', userId: 'someone-else', status: 'active' });
    await expect(alloc('owner', req('a'), 'dev-other')).rejects.toMatchObject({ details: { reason: 'license' } });
    await db.doc('companies/co1/authorizedDevices/dev-owner').update({ status: 'revoked' });
    await expect(alloc('owner', req('a'))).rejects.toMatchObject({ details: { reason: 'license' } });
    await db.doc('companies/co1/authorizedDevices/dev-owner').update({ status: 'active' });
    await db.doc('companies/co1/licenses/lic1').update({ validUntil: Timestamp.fromMillis(Date.now() - 1000) });
    await expect(alloc('owner', req('a'))).rejects.toMatchObject({ details: { reason: 'license' } });
    await db.doc('companies/co1/licenses/lic1').update({ validUntil: Timestamp.fromMillis(Date.now() + 86_400_000), status: 'suspended' });
    await expect(alloc('owner', req('a'))).rejects.toMatchObject({ details: { reason: 'license' } });
    // No number was used up by the refused calls.
    await db.doc('companies/co1/licenses/lic1').update({ status: 'active' });
    expect((await alloc('owner', req('a'))).invoiceNumber).toBe('SAI/2026-27/0001');
  });

  it('validates input', async () => {
    await seed('co1');
    for (const bad of [{}, req(''), req('a', '2026-28'), req('a', '26-27'), req('a/b')]) {
      await expect(alloc('owner', bad)).rejects.toMatchObject({ code: 'invalid-argument' });
    }
  });
});
