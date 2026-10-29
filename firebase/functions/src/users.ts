import { randomBytes } from 'node:crypto';
import type { Auth } from 'firebase-admin/auth';
import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import { str } from './licenses.js';
import { consume, LIMITS } from './rateLimit.js';

/**
 * Company user management by the company's owner/admins (sprint doc §3.2).
 * The owner can't be changed here; only the owner can grant, change or
 * disable admins; nobody can change themselves.
 */
const ROLES = ['admin', 'manager', 'operator', 'accounts'] as const;
type Role = (typeof ROLES)[number];

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

async function requireManager(db: Firestore, uid: string | undefined, companyId: string) {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  const [company, me] = await db.getAll(db.doc(`companies/${companyId}`), db.doc(`companies/${companyId}/companyUsers/${uid}`));
  if (!me.exists || me.get('status') !== 'active' || !['owner', 'admin'].includes(me.get('role'))) {
    throw new HttpsError('permission-denied', 'Only the company owner or an admin can manage users.');
  }
  if (!company.exists || company.get('status') !== 'active') {
    throw new HttpsError('failed-precondition', 'This company is not active.');
  }
  return me.get('role') as 'owner' | 'admin';
}

async function audit(db: Firestore, fields: Record<string, unknown>) {
  await db.collection('auditEvents').add({ ...fields, at: FieldValue.serverTimestamp() });
}

function role(v: unknown): Role {
  if (!ROLES.includes(v as Role)) throw new HttpsError('invalid-argument', `Role must be one of ${ROLES.join(', ')}.`);
  return v as Role;
}

/** Add someone to the company by email (account created if needed). */
export async function inviteCompanyUser(db: Firestore, auth: Auth, uid: string | undefined, data: unknown) {
  const d = (data ?? {}) as Record<string, unknown>;
  if (!str(d.companyId) || typeof d.email !== 'string' || d.email.length > 200 || !EMAIL.test(d.email.trim())) {
    throw new HttpsError('invalid-argument', 'companyId and a valid email are required.');
  }
  const companyId = d.companyId;
  const r = role(d.role);
  const callerRole = await requireManager(db, uid, companyId);
  if (r === 'admin' && callerRole !== 'owner') throw new HttpsError('permission-denied', 'Only the owner can add admins.');
  await consume(db, `invites_${companyId}`, LIMITS.invites);

  const email = d.email.trim().toLowerCase();
  let user;
  let newUser = false;
  try {
    user = await auth.getUserByEmail(email);
  } catch {
    user = await auth.createUser({ email, password: randomBytes(24).toString('base64url') });
    newUser = true;
  }
  const ref = db.doc(`companies/${companyId}/companyUsers/${user.uid}`);
  const existing = await ref.get();
  if (existing.exists && existing.get('status') === 'active') {
    throw new HttpsError('already-exists', `${email} is already a member.`);
  }
  if (existing.exists && existing.get('role') === 'owner') throw new HttpsError('failed-precondition', 'The owner cannot be re-invited.');
  // Re-inviting a disabled admin would undo the owner's decision.
  if (existing.exists && existing.get('role') === 'admin' && callerRole !== 'owner') {
    throw new HttpsError('permission-denied', 'Only the owner can re-enable an admin.');
  }
  await ref.set({
    uid: user.uid,
    companyId,
    email,
    role: r,
    status: 'active',
    invitedBy: uid,
    createdAt: existing.exists ? existing.get('createdAt') : FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await audit(db, { type: existing.exists ? 'user.reinvite' : 'user.invite', companyId, actorId: uid, userId: user.uid, email, role: r, newUser });
  return { userId: user.uid, newUser };
}

async function target(db: Firestore, uid: string, companyId: string, userId: unknown, callerRole: 'owner' | 'admin') {
  if (!str(userId)) throw new HttpsError('invalid-argument', 'userId is required.');
  if (userId === uid) throw new HttpsError('failed-precondition', 'You cannot change your own access.');
  const snap = await db.doc(`companies/${companyId}/companyUsers/${userId}`).get();
  if (!snap.exists) throw new HttpsError('not-found', 'User not found in this company.');
  if (snap.get('role') === 'owner') throw new HttpsError('failed-precondition', 'The owner cannot be changed here.');
  if (snap.get('role') === 'admin' && callerRole !== 'owner') throw new HttpsError('permission-denied', 'Only the owner can change admins.');
  return snap;
}

export async function setCompanyUserRole(db: Firestore, uid: string | undefined, data: unknown) {
  const d = (data ?? {}) as Record<string, unknown>;
  if (!str(d.companyId)) throw new HttpsError('invalid-argument', 'companyId is required.');
  const callerRole = await requireManager(db, uid, d.companyId);
  const r = role(d.role);
  if (r === 'admin' && callerRole !== 'owner') throw new HttpsError('permission-denied', 'Only the owner can make admins.');
  const snap = await target(db, uid!, d.companyId, d.userId, callerRole);
  await snap.ref.update({ role: r, updatedAt: FieldValue.serverTimestamp() });
  await audit(db, { type: 'user.role', companyId: d.companyId, actorId: uid, userId: snap.id, from: snap.get('role'), to: r });
  return { role: r };
}

/** Disable (or re-enable) a member. Their phones lose write access; data on the phones is kept. */
export async function setCompanyUserStatus(db: Firestore, uid: string | undefined, data: unknown) {
  const d = (data ?? {}) as Record<string, unknown>;
  if (!str(d.companyId) || !['active', 'disabled'].includes(d.status as string)) {
    throw new HttpsError('invalid-argument', 'companyId and status (active/disabled) are required.');
  }
  const callerRole = await requireManager(db, uid, d.companyId);
  const snap = await target(db, uid!, d.companyId, d.userId, callerRole);
  await snap.ref.update({ status: d.status, updatedAt: FieldValue.serverTimestamp() });
  await audit(db, { type: 'user.status', companyId: d.companyId, actorId: uid, userId: snap.id, from: snap.get('status'), to: d.status });
  return { status: d.status };
}
