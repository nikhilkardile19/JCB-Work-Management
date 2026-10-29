# Security review — Sprint 11

- Date: 2026-10-29
- Scope: Firestore Security Rules, Cloud Functions, Android app, developer
  admin portal, abuse controls, App Check.
- Result: **no known critical or high issues remain.** Every finding below is
  fixed and covered by an automated test, or is listed as an accepted risk.

## Findings

| ID | Severity | Area | Finding | Status | Test |
|----|----------|------|---------|--------|------|
| S11-01 | High | Rules | An **accounts** user could approve work logs: the rule let them change `status` on any log, so `submitted → approved` passed. | Fixed — accounts may only change `status`/`invoiceId` of logs that are already approved or invoiced. | `sync.rules.test.js` › accounts cannot approve work |
| S11-02 | High | Rules | An **operator** could rewrite or cancel their own *approved or invoiced* logs (the previous state was not checked), changing billed hours after approval. | Fixed — operators change only their own draft/rejected logs and never set `invoiceId`. | › operators cannot rewrite their own approved or invoiced logs; › cannot reserve logs |
| S11-03 | Medium | Rules | **Managers** could edit approved/invoiced logs and reserve logs for invoices; **owners/admins** could edit the readings of an invoiced log, so hours on the log and on the invoice could disagree. | Fixed — an invoiced log only changes through its invoice (finalize, or cancellation releasing it back to approved); managers never touch approved or billed logs. | › managers cannot change approved or invoiced logs; › invoiced logs change only through their invoice |
| S11-04 | Medium | Android / licensing | Android auto-backup and phone-to-phone transfer would copy the local database, including the **installation ID** that identifies the phone on the license, so a second phone could pass as an already-authorized one (device-limit bypass). | Fixed — `allowBackup="false"`, `fullBackupContent="false"`, and `data_extraction_rules.xml` excludes everything. Records are recovered by sync. | Manifest (reviewed); Android build |
| S11-05 | Medium | Functions | `allocateInvoiceNumber` checked the role but not the phone's license, so a revoked or expired phone could use up invoice numbers and leave gaps in the GST invoice series. | Fixed — the call must come from an active, same-user device on an active license (the same check the rules apply to the invoice write). The app sends its installation ID. | `invoiceNumbers.test.ts` › only an activated phone…; mobile `invoice_test.dart` |
| S11-06 | Medium | Abuse | No limits on activation-code guesses, replacement requests, or user invitations (each invitation can create a sign-in account). | Fixed — see "Rate limits". | `abuse.test.ts` |
| S11-07 | Low | Functions | An admin could re-enable (re-invite) an **admin** that the owner had disabled. | Fixed — only the owner can re-enable an admin. | `abuse.test.ts` › an admin cannot re-enable… |
| S11-08 | Low | Rules | An invoice discount could be negative (total above subtotal). | Fixed — discount ≥ 0 and total ≥ 0. | › drafts carry no number… |
| S11-09 | Low | Functions | Activation codes and invitation emails had no length limit. | Fixed — 40 and 200 characters. | `abuse.test.ts` |
| S11-10 | Low | Functions | Unexpected errors could reach callers with internal messages, and refused calls were not logged. | Fixed — every callable logs refusals (`warn`: function, uid, App Check app, code) and failures (`error` with stack); callers get a generic message. | Build; reviewed |
| S11-11 | Low | Portal | No security headers; a page error blanked the whole portal. | Fixed — CSP (`script-src 'self'`, `frame-ancestors 'none'`, …), HSTS, `X-Frame-Options`, `nosniff`, Referrer and Permissions policies in `firebase.json`; per-page error boundary that logs. | `ErrorBoundary.test.tsx`; built `index.html` has no inline scripts |
| S11-12 | Info | Android | Release manifest relied on plugins for `INTERNET`; cleartext traffic not explicitly off. | Fixed — declared; `usesCleartextTraffic="false"`. No `CAMERA` permission is requested (the system camera app is used). | Android build |

## Firestore rules review

Checked against the role matrix in sprint doc §3.2 and the mobile policies
(`WorkLogPolicy`, `FuelPolicy`, `InvoicePolicy`).

- **Default deny.** Clients can never write `licenses`, `authorizedDevices`,
  `invoiceNumbers`, `counters`, `deviceReplacementRequests`, `auditEvents`,
  `rateLimits` or `developerAdmins`; `companyUsers` only for the owner's own
  row while creating the company.
- **Tenant isolation.** Every company path needs an *active* membership;
  disabled members lose reads and writes immediately.
- **Every business write** needs an active device registered to the same
  user on a license that is active and within its dates, plus a revision
  that advances by exactly one (no silent overwrite). Nothing can be
  hard-deleted.
- **Work logs** (after this review):

  | Role | Create | Change |
  |------|--------|--------|
  | Owner/admin | any status | anything, except an invoiced log changes only via its invoice |
  | Manager | any status except invoiced, no invoice link | logs that are draft, submitted or rejected (review/approve) |
  | Operator | own: draft, submitted or cancelled | own logs that are draft or rejected |
  | Accounts | — | invoice link and approved ⇄ invoiced on approved/invoiced logs |

- **Invoices:** billing roles only; drafts carry no number; finalizing needs
  the server-issued number; finalized invoices change only by cancellation
  with a reason. **Payments:** positive on create, afterwards only reversal
  with a reason. **History** (`auditLogs`) is append-only.
- Tests: 61 rules tests (`firebase/tests`), all passing.

## Cloud Functions authorization

| Function | Caller | Server checks | Rate limit | Audited |
|----------|--------|---------------|-----------|---------|
| `allocateInvoiceNumber` | owner, admin, accounts | active member, active company, **active device + license** | — | number stored per invoice |
| `activateDevice` | member | active member/company, code hash, license dates/status, device limit (transaction) | 10 wrong codes / user / hour | yes |
| `validateLicense` | member | own device only | — | (updates last seen) |
| `requestDeviceReplacement` | member | code hash, license active, device not revoked, one pending per phone | wrong codes (shared); 5 / user / day | yes |
| `reviewReplacement` | developer admin with `devices.revoke` | reason; limit re-checked in transaction | — | yes |
| `inviteCompanyUser` | owner/admin | only owner adds or re-enables admins | 30 / company / day | yes |
| `setCompanyUserRole`, `setCompanyUserStatus` | owner/admin | never self or owner; only owner changes admins | — | yes |
| `createLicense`, `updateLicense`, `setLicenseStatus`, `rotateActivationCode` | developer admin with `licenses.manage` | reasons; validated ranges | — | yes |
| `setCompanyStatus`, `adminCreateCompany`, `adminUpdateCompany` | developer admin with `companies.manage` | reasons; profile validation | — | yes |
| `revokeDevice` | developer admin with `devices.revoke` | reason | — | yes |

All inputs are type- and length-checked; IDs may not contain `/`.

## Rate limits

Fixed-window counters in `rateLimits/{key}` (server-only), written in a
transaction. Refusals return `resource-exhausted` with
`{ reason: 'rate_limited', retryAfterMs }`.

| Limit | Key | Why |
|-------|-----|-----|
| 10 wrong activation codes per hour | user | Codes have 60 bits of entropy, so guessing is already impractical; the limit stops scripted attempts and bounds cost. Successful activations and re-validations don't count. |
| 5 new replacement requests per day | user | Stops flooding the developer's review queue. Repeating a pending request is free. |
| 30 users added per day | company | Each invitation can create a sign-in account. |

A TTL policy on `rateLimits.expiresAt` cleans old counters (owner step in
`firebase/README.md`).

## App Check evaluation

**What it adds:** proof that a request comes from the genuine JCB Works app
or portal, not a script using a stolen or self-registered account. It
complements, not replaces, the rules and function checks above.

| Client | Provider | Notes |
|--------|----------|-------|
| Android app | Play Integrity | Needs the app in a Google Play Console project linked to Firebase, and the release SHA-256 registered. Debug builds use the debug provider with registered debug tokens. Standard quota (10,000 checks/day) is far above our needs. |
| Admin portal | reCAPTCHA Enterprise | Site key for the hosting domain; the CSP must then allow `https://www.google.com` and `https://www.gstatic.com` for scripts and frames. |

**Risks:** enforcing before every installed app sends tokens locks those
users out; emulators and test phones need debug tokens; Play Integrity can't
attest sideloaded test builds.

**Recommendation — adopt in Sprint 13, in three steps:**

1. With the Play Console listing (Sprint 13), add `firebase_app_check`
   (Play Integrity) to the release app and reCAPTCHA Enterprise to the
   portal.
2. Watch App Check metrics in the console for at least a week, until
   nearly all requests are verified.
3. Enforce for Cloud Functions (`ENFORCE_APP_CHECK=true` in
   `firebase/functions/.env`, redeploy), then for Firestore in the console.

**Ready now:** the server switch (`ENFORCE_APP_CHECK`, default `false`), and
refusal logs include the App Check app ID for monitoring.

## Mobile app

- Local data in app-private storage; no Android backup or transfer (S11-04).
  Photos and PDFs never leave the phone in v1 (§4.14).
- Location is foreground-only and optional; the app explains why before
  Android's permission dialog, and "Not now" still lets the user save.
- Privacy and permissions screen (More → Privacy and permissions) lists what
  is stored where.
- Errors are recorded on the phone (More → Sync & data → Recent errors) for
  support, without leaving the device.
- For Sprint 13 release: R8 shrinking/obfuscation, release signing, Play
  Integrity (above), API key restricted to the package and signing SHA-1
  (`firebase/README.md` step 9).

## Accepted risks

| Risk | Why accepted | Revisit |
|------|--------------|---------|
| Any signed-in user can create a **pending** company. | Pending companies see and write no business data until a developer admin approves them. | If spam appears; App Check reduces it. |
| `auditLogs` content is written by the app. | It is a convenience history; trusted metadata (`pushedBy`, `serverUpdatedAt`, `rev`) is checked by rules, and license/device history is server-written in `auditEvents`. | — |
| Overpayment is blocked by the app, not the rules. | Rules can't sum payments. Payments are audited and reversible. | Server-side check if payments move to a function. |
| The installation ID could be copied from a rooted phone. | Needs root access to the app's private storage. | Play Integrity (App Check) raises the bar. |
| Members can see their company's member list (emails, roles). | Needed for the team screen. | — |
| Notes fields have no size limit below Firestore's 1 MiB. | Abuse stays inside the user's own company. | — |
