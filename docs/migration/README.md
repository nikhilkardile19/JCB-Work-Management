# Firebase → Node.js + PostgreSQL migration

Status: implemented on branch `feature/node-postgres-migration` (not yet deployed; owner actions in `docs/backlog.md`).
API contract: [`api-contract.md`](api-contract.md). Decision record:
[`../adr/0004-node-postgres-backend.md`](../adr/0004-node-postgres-backend.md).

## Audit summary (Phase A)

| Area | Finding |
|---|---|
| Mobile (`mobile/`, Flutter, Android only) | Offline-first. Drift (SQLite) is the source of truth for the UI; a sync engine pushes `pending` rows and pulls changes. **Every** Firebase dependency sits behind one of seven interfaces, each already faked in tests: `AuthRepository`, `CompanyRemoteSource`, `RemoteStore`, `LicenseService`, `ReplacementService`, `CompanyUsersService`, `InvoiceNumberService`. Screens, providers and domain logic never touch Firebase. |
| Admin portal (`admin/`, React + Vite) | All data access behind `AdminApi` and `AuthService` interfaces (fakes in tests). Firebase is in exactly two files: `lib/firebaseAdminApi.ts`, `lib/firebaseAuthService.ts`. |
| Backend (`firebase/functions/`) | 15 callable Cloud Functions (licensing, devices, replacements, company users, invoice numbers, developer-admin actions) + Firestore Security Rules that enforce the role matrix, tenant isolation, sync revisions, money math and license checks on every write. |
| Existing custom backend | None. Authentication is Firebase Auth (email + password) only. |
| Firebase Storage / Messaging / Analytics / Crashlytics / App Check | Not used (App Check was evaluated, never enabled). Photos and PDFs never leave the phone (product decision #14). |
| Android build | No `google-services` Gradle plugin; Firebase is configured from `lib/firebase_options.dart`. `android/app/google-services.json` is unused by the build. |
| Production data | Backlog shows Firestore creation, rules deploy and the Functions deploy were all still blocked on the owner; mobile deployment is paused. Production Firestore is expected to be empty or test-only — **to be confirmed by the owner** (see Risks). A migration tool is built either way. |
| Tests at start | Admin: 28 passing. Mobile: unit + widget suites (baseline recorded in the Phase H notes). Rules: 61 emulator tests; Functions: 5 emulator suites. |

## Inventory

| Existing feature | Current implementation | New implementation |
|---|---|---|
| Sign-in / sign-out / reset (mobile) | `FirebaseAuthRepository` (Firebase Auth) | `HttpAuthRepository` → `/auth/*`; refresh token in Android Keystore-backed secure storage; access token in memory |
| Sign-in / reset (portal) | `createFirebaseAuthService` + `developerAdmins/{uid}` | `HttpAuthService` → `/auth/*` + `/admin/me`; portal `/reset-password` page |
| Accounts | Firebase Auth users | `users` (Argon2id hashes), `refresh_tokens`, `password_reset_tokens` |
| Developer-admin allowlist | `developerAdmins/{uid}` (console-managed) | `developer_admins` table; `npm run admin:create` CLI |
| Company registration / profile | Firestore batch + rules | `POST /companies`, `PATCH /companies/:id` |
| Membership lookup | `collectionGroup('companyUsers')` | `GET /me/memberships` (`company_members` table) |
| Company users | Firestore listener + 3 Functions | `GET/POST/PATCH /companies/:id/members` (app polls instead of listening) |
| Masters (clients, sites, machines, operators, petrol pumps) | Drift + sync to `companies/{c}/{collection}` | Drift + sync to `/companies/:c/sync/:collection` → `clients`, `sites`, `machines`, `operators`, `petrol_pumps` tables |
| Work logs | same | `work_logs` |
| Fuel entries | same | `fuel_entries` |
| Invoices + lines | same (lines embedded in invoice doc) | `invoices` + normalized `invoice_lines` |
| Payments | same | `payments` |
| Company history | same (`auditLogs`, append-only) | `audit_logs` |
| Invoice numbering | `allocateInvoiceNumber` (Firestore transaction) | `POST /companies/:c/invoice-numbers` (`invoice_number_counters`, `issued_invoice_numbers`, unique per company) |
| License activation / validation | `activateDevice`, `validateLicense` | `POST /companies/:c/license/activate|validate` (`licenses`, `devices`) |
| Device replacement | `requestDeviceReplacement`, request doc read, `reviewReplacement` | `/companies/:c/device-replacements`, `/admin/.../review` (`device_replacement_requests`) |
| Developer admin portal reads | Firestore collection-group queries | `GET /admin/*` (SQL, cursor pagination) |
| Developer admin actions | 8 callable Functions | `POST/PATCH /admin/*` |
| Server-written history | `auditEvents` | `audit_events` |
| Abuse limits | `rateLimits` docs | `rate_limits` table + login throttling |
| Authorization | Firestore Security Rules | Express middleware + per-collection validators (ported rule by rule, ported tests) |
| Local/offline storage | Drift, sync queue (`syncStatus`, `sync_records`) | **Unchanged.** Only the `RemoteStore` implementation changes. |
| Portal hosting | Firebase Hosting | Firebase Hosting retained for the static portal only (allowed by the brief); any static host works |

## Firestore → PostgreSQL mapping

Tenant-owned business tables use the composite primary key
`(company_id, id)` and composite foreign keys, so a record can only reference
records of its own company — tenant isolation is enforced by the database,
not just by the API.

| Firestore path | Table | Notes |
|---|---|---|
| Firebase Auth user | `users` | `id` = Firebase UID (kept). No password hash can be imported; migrated users set a password with "Forgot password". |
| `developerAdmins/{uid}` | `developer_admins` | role, permissions[] |
| `companies/{c}` | `companies` | `nameLower` dropped (case-insensitive SQL search) |
| `companies/{c}/companyUsers/{uid}` | `company_members` | PK `(company_id, user_id)` |
| `companies/{c}/licenses/{l}` | `licenses` | Timestamps → `timestamptz` |
| `companies/{c}/authorizedDevices/{d}` | `devices` | PK `(company_id, id)` — a phone can be on several companies |
| `companies/{c}/deviceReplacementRequests/{r}` | `device_replacement_requests` | one pending request per phone (partial unique index) |
| `companies/{c}/invoiceNumbers/{invoiceId}` | `issued_invoice_numbers` | unique `(company_id, invoice_number)` |
| `companies/{c}/counters/invoices-{FY}` | `invoice_number_counters` | |
| `companies/{c}/{clients,sites,machines,operators,petrolPumps}` | `clients`, `sites`, `machines`, `operators`, `petrol_pumps` | `petrol_pumps` = "fuel suppliers" in the brief; the app's name is kept |
| `companies/{c}/workLogs` | `work_logs` | `invoice_id` is a soft reference (the app reserves a log before its draft invoice is uploaded) |
| `companies/{c}/fuelEntries` | `fuel_entries` | |
| `companies/{c}/invoices` (+ `lines[]`) | `invoices`, `invoice_lines` | |
| `companies/{c}/payments` | `payments` | |
| `companies/{c}/auditLogs` | `audit_logs` | |
| `auditEvents` | `audit_events` | |
| `rateLimits` | `rate_limits` | |
| sync metadata `rev`, `serverUpdatedAt`, `pushedBy`, `deviceId` | columns on every synced table + `sync_seq` | |

Money and quantities stay integers (paise, hundredths) — `BIGINT` for money,
`INTEGER` for readings/litres. No floating-point money anywhere.

## Decisions taken with a default (owner to confirm)

| # | Decision | Default used | Why |
|---|---|---|---|
| M1 | Historical Firestore data | Build and test the export/import tool; run it at cutover only if the owner confirms production data exists | Production Firestore is believed to be empty |
| M2 | Firebase Auth passwords | Not migrated; users set a new password via "Forgot password" (same flow invited users already use) | Firebase scrypt hashes need project-specific parameters; few or no real users |
| M3 | Portal token storage | Access token in memory, refresh token in `sessionStorage` (per tab), rotated on every refresh, reuse detection server-side, strict CSP | An httpOnly cookie needs the API and portal on the same site; Firebase Hosting's default domain is cross-site and Safari blocks such cookies |
| M4 | Language | TypeScript (Node 24, Express 5, Prisma 7, Zod 4) | Matches the existing Cloud Functions and portal code |
| M5 | Business-data API shape | Sync endpoints (push/pull per collection) instead of separate CRUD endpoints | The app is offline-first and only writes through its sync queue; CRUD endpoints would duplicate the same rules with no caller |
| M6 | Server-side PDF | Not added | Invoice PDFs are generated on the phone, offline (existing feature) |
| M7 | App Check | Dropped with Firebase; Play Integrity can be added to the API later | Was never enabled |
| M8 | New server-side checks | Added: no overpayment, subtotal = Σ lines, one finalized invoice per work log, tenant-scoped foreign keys | Closes "accepted risks" the rules could not express; no calculation changes |

## Risks and missing information

| Risk | Mitigation / owner action |
|---|---|
| Unknown amount of production data and users in Firestore/Auth | Owner confirms (M1). Tool exports to JSON backups first and never writes to Firestore. |
| Users must reset passwords after cutover | Communicate before cutover; reset email needs SMTP configured. |
| Email provider not chosen | `SMTP_*` settings; without them, reset links are only logged (dev). |
| Hosting for Node.js and PostgreSQL not chosen | Deployment guide is provider-neutral (any Node 24 host + managed PostgreSQL 15+). |
| Installed apps with Firebase builds | Mobile deployment is paused; no installed base expected. A forced update screen is out of scope. |
| Portal CSP must list the API origin | Predeploy check refuses to publish until `connect-src` contains `VITE_API_BASE_URL`'s origin. |

## Remaining Firebase references (Phase I classification)

| Where | Class | Why it stays |
|---|---|---|
| `firebase/firebase.json`, `.firebaserc`, `package.json` (firebase-tools), `scripts/check-portal-config.mjs`, README | Required hosting infrastructure | Firebase Hosting serves the static portal only |
| `.github/workflows/ci.yml` › `deploy-hosting` | Required hosting infrastructure | Publishes the portal |
| `tools/firestore-export/` (firebase-admin) | Migration tooling | Read-only export at cutover; not part of any runtime |
| `backend/src/scripts/firestore-import/`, `importFirestore.ts`, `tests/fixtures/firestore-export/` | Migration tooling | Reads export files; no Firebase dependency |
| Comments "ported from `functions/…`" / "`firestore.rules`" in `backend/`; `mobile/…/sync_engine.dart` cursor-key note | Historical documentation | Provenance; the files are in git history (`c859259`) |
| `docs/security-review.md` (Sprint 11 part), ADR 0001–0003, `docs/backlog.md`, sprint document | Historical documentation | Record of the earlier design; banners point to ADR 0004 |
| `mobile/ios/Podfile.lock` | Unused generated file | iOS is out of scope (decision #15) and never built; regenerated if iOS is ever enabled |
| `.gitignore` (`firebase-debug.log`, `firebase/.firebase/`) | Hosting tooling | Firebase CLI artefacts |

Removed: `firebase/functions/` (15 Cloud Functions + tests), `firestore.rules`,
`firestore.indexes.json`, rules tests, the Firebase SDKs and configuration in
`mobile/` (`firebase_core`, `firebase_auth`, `cloud_firestore`,
`cloud_functions`, `firebase_options.dart`, `google-services.json`) and
`admin/` (`firebase` package, Firebase services, `VITE_FIREBASE_*`).
No unintended Firebase dependency remains.

## Checklist

- [x] **A** Audit, inventory, API contract, mapping, risks
- [x] **B** PostgreSQL schema (Prisma) and migrations, seed
- [x] **C** Backend foundation: config, logging, errors, validation, auth (login, refresh rotation, logout, reset), rate limits
- [x] **D** Masters/operations: sync push/pull with ported rule checks
- [x] **E** Invoice numbers, licenses, devices, replacements, company users, developer admin
- [x] **F** Firestore export/import tool with reconciliation report
- [x] **G** Admin portal on the REST API
- [x] **H** Flutter app on the REST API
- [x] **I** Firebase runtime dependencies removed; remaining references classified
- [x] **J** Full test run, security review, deployment/backup/rollback guide
