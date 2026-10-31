# REST API contract — `/api/v1`

Source of truth while the backend is being built. Once the backend exists, the
generated OpenAPI document (`GET /api/docs/openapi.json`) supersedes this file.

Every operation here replaces a Firestore read/write or a Cloud Function call
that exists today; nothing is invented. The mapping is in
[`README.md`](README.md#inventory).

## Conventions

- JSON in and out. All timestamps are **UTC epoch milliseconds** (numbers).
  Calendar dates are `yyyy-MM-dd` strings. Money is integer **paise**,
  meter readings/hours integer **hundredths of an hour**, litres integer
  **hundredths of a litre** — exactly as the mobile app stores them.
- IDs are strings. Existing Firestore IDs and Firebase UIDs are kept as-is;
  new server-generated IDs are UUID v4.
- Auth: `Authorization: Bearer <accessToken>` on everything except
  `/auth/signup`, `/auth/check-email`, `/auth/login-with-code`, `/auth/login`,
  `/auth/refresh`, `/auth/forgot-password`, `/auth/reset-password` and
  `/health*`.
- The mobile app sends `X-Device-Id: <installation id>` on every request.
  Endpoints that act "as this phone" (sync push, invoice numbers) require it.
- The server never trusts a client-sent role, company status, license state
  or device approval: all of these are read from PostgreSQL per request.

### Errors

Non-2xx responses (except the sync conflict below) have this body:

```json
{ "error": { "code": "failed_precondition", "message": "User-facing text.", "reason": "device_limit" } }
```

| HTTP | `code` | Meaning (same codes the Cloud Functions used) |
|------|--------|------|
| 400 | `invalid_argument` | Request failed validation. Optional `fields: {name: message}`. |
| 401 | `unauthenticated` | Missing/expired/invalid token or wrong credentials. |
| 403 | `permission_denied` | Signed in but not allowed. |
| 404 | `not_found` | |
| 409 | `already_exists` | |
| 409 | `failed_precondition` | State does not allow it (license expired, company pending, …). |
| 409 | `conflict` | Sync revision mismatch (body differs, see Sync). |
| 429 | `resource_exhausted` | Rate limited. `reason: "rate_limited"`, `retryAfterMs`. |
| 500 | `internal` | Generic message only; details are logged server-side. |

`reason` is a stable machine code when the client must branch on it
(license denials, sync access refusals, auth failures).

### Pagination (admin lists)

`?cursor=<opaque string>&limit=<1..100, default 25>` →
`{ "items": [...], "next": "<opaque>" | null }`.

## Health

- `GET /health` → `200 {"status":"ok"}` (liveness, no DB).
- `GET /health/ready` → `200 {"status":"ok","database":"ok"}` or `503`.

## Auth — replaces Firebase Authentication

| Method & path | Body | Response |
|---|---|---|
| `POST /auth/signup` | `{email, password?, company: CompanyProfile}` (password optional, ≥ 8 chars when given) | `201 {userId, companyId}` — the company is `pending` with the new user as owner. Does **not** sign in. |
| `POST /auth/check-email` | `{email}` | `204` when the account exists and may sign in; `404 reason: "no_account"`; `403 reason: "user_disabled"` (mobile sign-in step 1) |
| `POST /auth/login-with-code` | `{email, activationCode, deviceId, deviceModel?, platform?}` | `200 Session & {companyId, license: LicenseState \| null, activation: {reason: "device_limit", message} \| null}` — mobile sign-in step 2, no password; also activates the phone |
| `POST /auth/login` | `{email, password, client: "mobile"\|"portal"}` | `200 Session` (portal; older app builds) |
| `POST /auth/refresh` | `{refreshToken}` | `200 Session` (old refresh token is revoked — rotation) |
| `POST /auth/logout` | `{refreshToken}` | `204` (revokes that session) |
| `GET /auth/me` | — | `200 {id, email, developerAdmin: {role, permissions} \| null}` |
| `POST /auth/forgot-password` | `{email}` | `204` always (no account enumeration) |
| `POST /auth/reset-password` | `{token, password}` (password ≥ 8 chars) | `204`; revokes every session of that user |

```ts
type Session = {
  accessToken: string            // JWT, ~15 min
  accessTokenExpiresAt: number   // ms
  refreshToken: string           // opaque, stored hashed server-side
  refreshTokenExpiresAt: number | null  // ms; null for mobile (never expires), portal ≈ 12 h
  user: { id: string; email: string }
}
```

Mobile sessions never expire: they end on sign-out, a password reset, a
disabled account or refresh-token reuse detection. Uninstalling the app
removes the token from the phone (it lives in Keystore-backed storage
excluded from backups).

Sign-up: an email that already has an account (with or without a password)
gets `409 already_exists` `reason: "email_taken"`; 20 sign-ups per client IP
per hour. The mobile onboarding is: sign up (no password) → developer admin
approves (`POST /admin/companies/:companyId/approve`), which emails the
activation code to the owner → owner enters their email (`/auth/check-email`)
→ enters the code (`/auth/login-with-code`) → dashboard.

Sign-in with a code: the code must belong to a license of a company the user
is an active member of. The phone is activated with the same rules as
`/companies/:companyId/license/activate` (a code works once; afterwards only
the same user on the same phone can sign in with it again, e.g. after signing
out), and a mobile session starts. A wrong email/code pair is `401
unauthenticated` `reason: "invalid_code"` and counts towards the per-email and
per-IP sign-in failure limits. Other activation refusals are `409
failed_precondition` with their `reason` and start no session, except
`device_limit`: that one signs in with `license: null` and `activation` set, so
the app can file a device replacement request. `/auth/check-email` is limited to
30 checks per client IP per 15 minutes.

Login/refresh failures: `401 unauthenticated` with `reason` one of
`invalid_credentials`, `invalid_code`, `invalid_refresh_token`; `403 permission_denied`
`reason: "user_disabled"`; `429` when rate limited.

Refresh-token reuse: presenting an already-rotated token revokes the whole
session (theft detection), except within a short grace window when its
replacement has never been used (a lost response on a flaky network).

The reset email links to `${PASSWORD_RESET_URL}?token=…` (the admin portal's
public `/reset-password` page serves both mobile users and admins).

## Mobile — company and membership (replaces `companies`, `companyUsers` reads/writes)

| Method & path | Who | Body → Response |
|---|---|---|
| `GET /me/memberships` | signed in | `200 {items: Membership[]}` — **active** memberships only, any company status |
| `POST /companies` | signed in | `CompanyProfile & {id}` → `201 Company` (status `pending`, caller is owner). Retrying with the same `id` by the same owner returns `200` with the existing company; another user's id → `409 already_exists`. |
| `PATCH /companies/:companyId` | owner/admin | `CompanyProfile` → `200 Company` (never status/owner/id) |

```ts
type CompanyProfile = { name; contactPerson; phone; address; invoicePrefix; email: string|null; gstin: string|null }
type Company = CompanyProfile & { id; currency: "INR"; status: "pending"|"active"|"suspended"; ownerUid; createdAt: number|null }
type Membership = { role: "owner"|"admin"|"manager"|"operator"|"accounts"; status: "active"; company: Company }
```

Validation = `CompanyValidators` (mobile) = old `validCompanyProfile` rule:
name 2–120, contactPerson 1–120, phone 10–20, address 5–500,
invoicePrefix `^[A-Z0-9-]{1,10}$`, email ≤ 200 and valid if present,
GSTIN `^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$` if present.

## Mobile — company users (replaces `companyUsers` reads + `inviteCompanyUser`, `setCompanyUserRole`, `setCompanyUserStatus`)

| Method & path | Who | Body → Response |
|---|---|---|
| `GET /companies/:companyId/members` | any active member | `200 {items: [{uid, email, role, status: "active"\|"disabled"}]}` sorted by email |
| `POST /companies/:companyId/members` | owner/admin, company active | `{email, role}` → `200 {userId, newUser}`. Creates the account (no password; user runs "Forgot password") if needed. 30 invites/company/day. |
| `PATCH /companies/:companyId/members/:userId` | owner/admin, company active | exactly one of `{role}` or `{status: "active"\|"disabled"}` → `200 {role}` / `200 {status}` |

Rules (unchanged): roles assignable `admin, manager, operator, accounts`;
only the owner adds/changes/re-enables admins; nobody changes themselves or
the owner. Errors: `already_exists` (already an active member),
`permission_denied`, `failed_precondition`, `resource_exhausted`.

## Mobile — license and devices (replaces `activateDevice`, `validateLicense`)

| Method & path | Who | Body → Response |
|---|---|---|
| `POST /companies/:companyId/license/activate` | active member, company active | `{activationCode, deviceId, deviceModel?, platform?}` → `200 LicenseState` |
| `POST /companies/:companyId/license/validate` | active member, company active | `{deviceId}` → `200 LicenseState` (never an error for suspended/expired/revoked — the state says so) |

```ts
type LicenseState = {
  licenseId: string | null
  licenseStatus: "active"|"pending"|"suspended"|"expired"|"revoked"|"not_started"|"none"
  deviceStatus: "active"|"revoked"|"unknown"
  validUntil: number | null
  maxDevices: number | null
  serverTime: number
}
```

Activation codes work **once**: the first successful activation (or
replacement request) uses the code up; a retry by the same user on the same
phone still succeeds. Another phone needs a new code from support
(`rotate-code`).

Denials: `409 failed_precondition` with `reason` ∈ `invalid_code`, `code_used`,
`not_started`, `expired`, `suspended`, `revoked`, `pending`, `device_limit`,
`device_revoked`, `company_inactive`; `403 permission_denied`
`reason: "not_member"`; `400 invalid_argument`; `429` after 10 wrong codes
per user per hour.

## Mobile — device replacement (replaces `requestDeviceReplacement` + request doc read)

| Method & path | Who | Body → Response |
|---|---|---|
| `POST /companies/:companyId/device-replacements` | active member, company active | `{activationCode, newDeviceId, newDeviceModel?, reason}` → `200 {requestId: string\|null, status: "pending"\|"already_active"}` |
| `GET /companies/:companyId/device-replacements/:requestId` | requester, or owner/admin | `200 {requestId, status: "pending"\|"approved"\|"rejected", reviewReason: string\|null}` |

Same denial codes as activation (`invalid_code`, `code_used`, license status, `device_revoked`). Filing a request uses up the code.

## Mobile — invoice numbers (replaces `allocateInvoiceNumber`)

`POST /companies/:companyId/invoice-numbers` with header `X-Device-Id`,
body `{invoiceId, financialYear: "2026-27"}` → `200 {invoiceNumber: "JCB/2026-27/0007"}`.

Owner/admin/accounts of an active company, from an active device of the same
user on an active license. Idempotent per `invoiceId`. Numbers are allocated
in a transaction; `(companyId, invoiceNumber)` is unique in the database.

## Mobile — offline sync (replaces direct Firestore reads/writes of business data)

Collections (path segment = existing Firestore collection name):
`clients`, `sites`, `machines`, `operators`, `petrolPumps`, `workLogs`,
`fuelEntries`, `invoices`, `payments`, `auditLogs`.

`data` is exactly the record as the app's Drift `toJson()` produces it, minus
`syncStatus` and device-only fields (`startPhotoPath`, `endPhotoPath`,
`receiptPhotoPath`, `pdfPath`). Invoices carry their lines inline as
`lines: InvoiceLine[]` (as in Firestore); the server stores them in
`invoice_lines`.

### Pull

`GET /companies/:companyId/sync/:collection?after=<cursor>&limit=<1..500, default 200>`

```json
{ "items": [ { "id": "…", "rev": 3, "cursor": "1042|<id>", "data": { …all business fields… } } ] }
```

Oldest change first. `cursor` has the same `"<number>|<id>"` shape as the
app's `SyncCursor.encode()`; the number is a per-company change sequence
assigned under a lock in the write transaction, so a reader can never skip a
change that commits later. Any active member may pull; `invoices` and
`payments` need owner/admin/manager/accounts (others get `403`, which the
app treats as "nothing to download", as before). Pull keeps working while the
license is suspended or the company is not active (read-only access).

### Push

`PUT /companies/:companyId/sync/:collection/:id` with header `X-Device-Id`,
body `{ "baseRev": <int> | null, "data": { … } }`.

| Result | HTTP | Body |
|---|---|---|
| Accepted | `200` | `{"rev": <new rev>}` |
| Revision mismatch | `409` | `{"error": {"code": "conflict", …}, "serverRev": <int>, "serverData": {…}}` (`serverRev: 0, serverData: {}` when the record doesn't exist but `baseRev` was given) |
| Record refused (role matrix, validation, money math, missing reference) | `403` / `400` | error envelope — app marks the record `error` |
| Whole pass refused | `403` | error envelope with `reason` ∈ `not_member`, `company_inactive`, `device_not_licensed` — app stops the pass and keeps records `pending` |

Server-side checks are a direct port of `firebase/firestore.rules`
(`syncMeta`, `deviceLicensed`, `workLogWrite`, `fuelWrite`, `invoiceWrite`,
`paymentWrite`, append-only `auditLogs`), plus constraints Firestore could
not express: composite foreign keys inside the tenant, invoice subtotal =
Σ line amounts, a work log on at most one finalized invoice, and no
overpayment. Records are never hard-deleted (`deletedAt` tombstones).

## Developer admin portal — replaces Firestore reads + admin Cloud Functions

All under `/admin`; caller must be in `developer_admins` (role `super`, or
`support` with the named permission). Every change is written to
`audit_events` with before/after values and the mandatory reason.

| Method & path | Permission | Body → Response |
|---|---|---|
| `GET /admin/me` | any admin | `AdminProfile` (`403` if not an admin) |
| `GET /admin/metrics` | any admin | `DashboardMetrics` |
| `GET /admin/companies?status&search&cursor` | any admin | `Page<Company>` (search = case-insensitive name contains; else newest first) |
| `GET /admin/companies/:companyId` | any admin | `Company` |
| `GET /admin/companies/:companyId/members` | any admin | `{items: Member[]}` |
| `POST /admin/companies` | `companies.manage` | `CompanyProfile & {ownerEmail}` → `{companyId, newUser}` (company created `active`) |
| `PATCH /admin/companies/:companyId` | `companies.manage` | `CompanyProfile` → `{ok: true}` |
| `POST /admin/companies/:companyId/status` | `companies.manage` | `{status, reason}` → `{status}` |
| `POST /admin/companies/:companyId/approve` | `companies.manage` + `licenses.manage` | `{validFrom, validUntil, maxDevices, reason}` → `201 {licenseId, activationCode, emailedTo}`. Pending companies only (`409` otherwise): activates the company and issues its license in one transaction, then emails the code to the owner. |
| `GET /admin/licenses?status&companyId&cursor` | any admin | `Page<License>` (by `validUntil` ascending) |
| `POST /admin/companies/:companyId/licenses` | `licenses.manage` | `{validFrom, validUntil, maxDevices}` → `{licenseId, activationCode, emailedTo}` (code shown once) |
| `GET /admin/companies/:companyId/licenses/:licenseId` | any admin | `License` |
| `PATCH /admin/companies/:companyId/licenses/:licenseId` | `licenses.manage` | `{validUntil?, maxDevices?, reason}` → `{ok: true}` |
| `POST /admin/companies/:companyId/licenses/:licenseId/status` | `licenses.manage` | `{status: "active"\|"suspended"\|"revoked", reason}` → `{status}` |
| `POST /admin/companies/:companyId/licenses/:licenseId/rotate-code` | `licenses.manage` | `{reason}` → `{activationCode, emailedTo}` — also how another phone is added, since codes work once |
| `GET /admin/devices?status&companyId&licenseId&cursor` | any admin | `Page<Device>` (last seen first) |
| `GET /admin/companies/:companyId/devices/:deviceId` | any admin | `Device` |
| `POST /admin/companies/:companyId/devices/:deviceId/revoke` | `devices.revoke` | `{reason}` → `{ok: true}` |
| `GET /admin/replacement-requests?status&cursor` | any admin | `Page<ReplacementRequest>` (newest first) |
| `POST /admin/companies/:companyId/replacement-requests/:requestId/review` | `devices.revoke` | `{decision: "approve"\|"reject", reason, revokeDeviceId?}` → `{status, revokedDeviceId}` |
| `GET /admin/audit-events?companyId&licenseId&deviceId&type&cursor` | any admin | `Page<AuditEvent>` (newest first) |

Response types are exactly those in `admin/src/lib/adminApi.ts`
(`Company`, `Member`, `License`, `Device`, `ReplacementRequest`,
`AuditEvent`, `DashboardMetrics`, `AdminProfile`), with `Cursor` = string.
Every newly issued code is emailed to the company owner and `emailedTo` is
that address; it is `null` when the code was not sent (no SMTP configured —
codes are never written to the log mailer — or the mail server refused), and
the admin passes the code on. `License` carries `activationCodeUsedAt` and
`activationCodeDeviceId` (null while the current code is unused).
Reasons are 3–500 characters. Business rules are those of
`firebase/functions/src/admin.ts` and `replacements.ts` (revoked licenses
are frozen; reactivation needs a future end date; renewal of an expired
license re-activates it; the device limit can't be lowered below active
devices; replacement approval re-checks the limit in one transaction).
