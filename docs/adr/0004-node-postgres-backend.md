# ADR 0004 — Node.js + PostgreSQL backend replaces Firebase

- Status: Accepted
- Date: 2026-10-30
- Supersedes: the Firebase parts of ADR 0001, the Firestore parts of ADR 0002
  and ADR 0003 (the sync *protocol* is kept; its server changes).

## Context

The product owner asked to move off Firebase application services (Auth,
Firestore, Cloud Functions) to a self-hosted Node.js REST API on PostgreSQL.
The audit (`docs/migration/README.md`) found every Firebase dependency behind
interfaces in both clients, so the change is confined to those
implementations plus a new backend.

## Decision

### Backend (`backend/`)

- Node 24, TypeScript, Express 5, Prisma 7 (driver adapter `pg`), Zod 4,
  OpenAPI 3.1 generated from the same Zod schemas that validate requests
  (`lib/http.ts` — one declaration validates, documents and serves a route).
- Modules mirror the former Functions: `auth`, `companies`, `members`,
  `licenses`, `replacements`, `invoice-numbers`, `sync`, `admin`, `audit`,
  `rate-limits`. Business rules were ported line by line, with their tests.
- Errors use the Functions' codes (`invalid_argument`, `permission_denied`,
  `failed_precondition`, …) in one JSON envelope, so client error mapping
  stays the same.

### Data

- PostgreSQL tables per former collection; company-owned tables keyed
  `(company_id, id)` with composite foreign keys (tenant isolation enforced
  by the database). Firestore IDs and Firebase UIDs are kept.
- Money `BIGINT` paise; readings/litres `INTEGER` hundredths; `CHECK`
  constraints repeat the money and meter rules.
- No hard deletes of synced records (`deleted_at`).

### Authentication

- Argon2id (OWASP parameters) password hashes; 15-minute HS256 access
  tokens carrying only the user ID and a token version; opaque refresh
  tokens stored as SHA-256 hashes, rotated on every use, with reuse
  detection (a replayed token ends the session) and a 60-second grace
  window for responses lost on mobile networks.
- Mobile sessions slide (60 days) so offline-first users stay signed in;
  portal sessions end 12 hours after sign-in.
- Roles, membership, company status, device and license state are read from
  PostgreSQL on every request — never from tokens or clients.
- Password reset by single-use emailed link (60 minutes) to the portal's
  public `/reset-password` page; a reset signs out every session.

### Sync (ADR 0003 on PostgreSQL)

- Same protocol: push one record guarded by `baseRev`, 409 with the server
  copy on mismatch; pull by cursor. The app's sync engine, queue and conflict
  policies are unchanged.
- Cursor = per-company change sequence taken under a row lock inside the
  write transaction, so sequence order equals commit order and a reader can
  never skip a late-committing change (a timestamp cursor could).
- Access failures that affect every record (not a member, company inactive,
  phone not licensed) are reported with a `reason`, and the app keeps its
  records pending instead of marking each one as an error.

### Hosting

- Any Node 24 host + managed PostgreSQL 15+. Firebase Hosting is kept only
  as a static host for the portal (allowed by the brief); nothing else in
  Firebase is used. See `docs/migration/deployment.md`.

## Consequences

- Firebase Auth passwords cannot be carried over: users set a new password
  with "Forgot password" after cutover (decision M2).
- The team now operates a server and a database: backups, monitoring and
  patching are ours (runbook in the deployment guide).
- Checks Firestore rules could not express are now enforced: no overpayment,
  invoice subtotal = Σ lines, a work log on at most one finalized invoice,
  and references within the same company.
- App Check is gone; Play Integrity on the API is a possible follow-up.
