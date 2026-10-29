import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall as onCallRaw, type CallableOptions, type CallableRequest } from 'firebase-functions/v2/https';
import { allocateInvoiceNumber as allocate } from './invoiceNumbers.js';
import * as admin from './admin.js';
import * as replacements from './replacements.js';
import * as users from './users.js';
import { activateDevice as activate, createLicense as create, validateLicense as validate } from './licenses.js';

initializeApp();

/**
 * App Check (docs/security-review.md): off until the Android app and the
 * portal are registered and the console shows verified traffic; then set
 * ENFORCE_APP_CHECK=true in functions/.env and redeploy.
 */
const ENFORCE_APP_CHECK = process.env.ENFORCE_APP_CHECK === 'true';

const opts = { region: 'asia-south1', enforceAppCheck: ENFORCE_APP_CHECK } as const;

/** Codes that indicate misuse or misconfiguration worth watching in the logs. */
const REFUSALS = new Set(['unauthenticated', 'permission-denied', 'resource-exhausted']);

/**
 * onCall with structured logging: refusals are logged as warnings (who, which
 * function, why) and unexpected errors with their stack. Callers only ever
 * see a generic message for unexpected errors, never internals.
 */
function onCall<T>(opts: CallableOptions, handler: (request: CallableRequest) => Promise<T>) {
  return onCallRaw(opts, async (request: CallableRequest) => {
    try {
      return await handler(request);
    } catch (e) {
      const fn = process.env.FUNCTION_TARGET ?? 'callable';
      const who = { fn, uid: request.auth?.uid ?? null, app: request.app?.appId ?? null };
      if (e instanceof HttpsError) {
        if (REFUSALS.has(e.code)) logger.warn('Call refused', { ...who, code: e.code, message: e.message });
        throw e;
      }
      logger.error('Call failed', { ...who, error: e instanceof Error ? e.stack ?? e.message : String(e) });
      throw new HttpsError('internal', 'Something went wrong. Please try again.');
    }
  });
}

/** Callable: { companyId, invoiceId, financialYear } → { invoiceNumber }. */
export const allocateInvoiceNumber = onCall(opts, (request) =>
  allocate(getFirestore(), request.auth?.uid, request.data),
);

/** Developer admins: { companyId, validFrom, validUntil, maxDevices } → { licenseId, activationCode }. */
export const createLicense = onCall(opts, (request) => create(getFirestore(), request.auth?.uid, request.data));

/** Members: { companyId, activationCode, deviceId, deviceModel?, platform? } → license state. */
export const activateDevice = onCall(opts, (request) => activate(getFirestore(), request.auth?.uid, request.data));

/** Members: { companyId, deviceId } → license state (never throws for inactive states). */
export const validateLicense = onCall(opts, (request) => validate(getFirestore(), request.auth?.uid, request.data));

// --- Developer admin (see admin.ts for roles and permissions) ---------------

export const setCompanyStatus = onCall(opts, (r) => admin.setCompanyStatus(getFirestore(), r.auth?.uid, r.data));
export const adminCreateCompany = onCall(opts, (r) => admin.adminCreateCompany(getFirestore(), getAuth(), r.auth?.uid, r.data));
export const adminUpdateCompany = onCall(opts, (r) => admin.adminUpdateCompany(getFirestore(), r.auth?.uid, r.data));
export const setLicenseStatus = onCall(opts, (r) => admin.setLicenseStatus(getFirestore(), r.auth?.uid, r.data));
export const updateLicense = onCall(opts, (r) => admin.updateLicense(getFirestore(), r.auth?.uid, r.data));
export const rotateActivationCode = onCall(opts, (r) => admin.rotateActivationCode(getFirestore(), r.auth?.uid, r.data));
export const revokeDevice = onCall(opts, (r) => admin.revokeDevice(getFirestore(), r.auth?.uid, r.data));

// --- Device replacement -------------------------------------------------------

export const requestDeviceReplacement = onCall(opts, (r) => replacements.requestDeviceReplacement(getFirestore(), r.auth?.uid, r.data));
export const reviewReplacement = onCall(opts, (r) => replacements.reviewReplacement(getFirestore(), r.auth?.uid, r.data));

// --- Company users (owner/admin) -------------------------------------------------

export const inviteCompanyUser = onCall(opts, (r) => users.inviteCompanyUser(getFirestore(), getAuth(), r.auth?.uid, r.data));
export const setCompanyUserRole = onCall(opts, (r) => users.setCompanyUserRole(getFirestore(), r.auth?.uid, r.data));
export const setCompanyUserStatus = onCall(opts, (r) => users.setCompanyUserStatus(getFirestore(), r.auth?.uid, r.data));
