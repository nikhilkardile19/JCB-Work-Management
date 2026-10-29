import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { effectiveStatus } from './licenses.js';

/** Roles allowed to finalize invoices (mobile: Permission.manageInvoices). */
const INVOICE_ROLES = new Set(['owner', 'admin', 'accounts']);

interface AllocateRequest {
  companyId: string;
  invoiceId: string;
  financialYear: string;
  /** The calling phone; it must be activated on an active license. */
  deviceId: string;
}

function parse(data: unknown): AllocateRequest {
  const d = (data ?? {}) as Record<string, unknown>;
  const ok = (v: unknown): v is string =>
    typeof v === 'string' && v.length > 0 && v.length <= 128 && !v.includes('/');
  if (!ok(d.companyId) || !ok(d.invoiceId) || typeof d.financialYear !== 'string' || !ok(d.deviceId)) {
    throw new HttpsError('invalid-argument', 'companyId, invoiceId, financialYear and deviceId are required.');
  }
  const fy = /^(\d{4})-(\d{2})$/.exec(d.financialYear);
  if (!fy || (Number(fy[1]) + 1) % 100 !== Number(fy[2])) {
    throw new HttpsError('invalid-argument', 'financialYear must look like 2026-27.');
  }
  return { companyId: d.companyId, invoiceId: d.invoiceId, financialYear: d.financialYear, deviceId: d.deviceId };
}

/**
 * Issues the next official invoice number for a company and financial year,
 * e.g. `JCB/2026-27/0007`. Runs in a transaction so concurrent devices never
 * get the same number, and is idempotent per invoice: retrying after a
 * network failure returns the number already issued.
 */
export async function allocateInvoiceNumber(
  db: Firestore,
  uid: string | undefined,
  data: unknown,
): Promise<{ invoiceNumber: string }> {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  const { companyId, invoiceId, financialYear, deviceId } = parse(data);

  const companyRef = db.collection('companies').doc(companyId);
  const memberRef = companyRef.collection('companyUsers').doc(uid);
  const issuedRef = companyRef.collection('invoiceNumbers').doc(invoiceId);
  const counterRef = companyRef.collection('counters').doc(`invoices-${financialYear}`);
  const deviceRef = companyRef.collection('authorizedDevices').doc(deviceId);

  return db.runTransaction(async (tx) => {
    const [company, member, issued, counter, device] = await tx.getAll(companyRef, memberRef, issuedRef, counterRef, deviceRef);
    if (!member.exists || member.get('status') !== 'active' || !INVOICE_ROLES.has(member.get('role'))) {
      throw new HttpsError('permission-denied', 'Not allowed to finalize invoices for this company.');
    }
    if (!company.exists) throw new HttpsError('not-found', 'Company not found.');
    if (company.get('status') !== 'active') {
      throw new HttpsError('failed-precondition', 'This company is not active yet.');
    }
    // Same check as the rules apply to the invoice write itself, so an
    // unlicensed phone can't use up numbers and leave gaps in the series.
    const license = device.exists ? await tx.get(companyRef.collection('licenses').doc(device.get('licenseId'))) : null;
    if (!device.exists || device.get('status') !== 'active' || device.get('userId') !== uid || !license?.exists
        || effectiveStatus(license.get('status'), license.get('validFrom'), license.get('validUntil'), new Date()) !== 'active') {
      throw new HttpsError('failed-precondition', 'This phone is not activated on an active license.', { reason: 'license' });
    }
    if (issued.exists) return { invoiceNumber: issued.get('invoiceNumber') as string };

    const next = ((counter.exists ? (counter.get('last') as number) : 0) || 0) + 1;
    const prefix = (company.get('invoicePrefix') as string | undefined) || 'INV';
    const invoiceNumber = `${prefix}/${financialYear}/${String(next).padStart(4, '0')}`;
    tx.set(counterRef, { last: next, updatedAt: FieldValue.serverTimestamp() });
    tx.set(issuedRef, {
      invoiceNumber,
      financialYear,
      issuedBy: uid,
      issuedAt: FieldValue.serverTimestamp(),
    });
    return { invoiceNumber };
  });
}
