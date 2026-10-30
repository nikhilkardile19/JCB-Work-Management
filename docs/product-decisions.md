# Product Decisions (Sprint 0)

Source: Section 14 of `JCB_Work_Management_Complete_Sprint_Document.md`.

Status legend: **PROPOSED** = engineering default used to unblock development,
must be confirmed by the product owner. **CONFIRMED** = signed off.

Every PROPOSED value is isolated behind a config constant or a single module so
it can be changed without rework.

| # | Decision | Proposed default | Status | Where it lives |
|---|----------|------------------|--------|----------------|
| 1 | Login method | Email + password via the project's own API (Argon2id, rotating refresh tokens — ADR 0004; Firebase Auth retired 2026-10-30). Phone OTP can be added later without data-model change. | PROPOSED | `backend/src/modules/auth/` |
| 2 | Owners per company | Multiple admins allowed (`role = owner` or `admin` in `companyUsers`). | PROPOSED | data model |
| 3 | Max devices / shared accounts | `maxDevices` per license, default 2. One account per person; shared logins discouraged. | PROPOSED | license doc |
| 4 | License model | Custom validity (`validFrom`/`validUntil`); annual is the default template in the admin portal. | PROPOSED | license doc |
| 5 | Offline grace | 7 days. After expiry: read/export allowed, new protected actions blocked until online validation. | PROPOSED | `AppConfig.offlineGraceDays` |
| 6 | Work-log approval | Owner/Admin/Manager auto-approve on submit; Operator entries go to `submitted` and need approval. Company setting can force approval for all. | PROPOSED | company settings |
| 7 | Offline invoice finalization | **Not allowed.** Offline invoices stay `draft`; official number assigned by the API on finalize (doc §5.7 recommended approach). | PROPOSED | invoice module |
| 8 | Invoice numbering | `{prefix}/{FY}/{seq}` allocated server-side in a PostgreSQL transaction per company + FY; unique per company in the database. | PROPOSED | `backend/src/modules/invoice-numbers/` |
| 9 | GST/tax | Not implemented in v1 until rules are confirmed (doc §4.11). Invoice total = subtotal − discount. Optional GSTIN fields stored for display only. | PROPOSED | invoice module |
| 10 | Operator logins | Optional. Operators are master records; an operator may additionally be invited as an `operator`-role user. | PROPOSED | data model |
| 11 | Editing approved work logs | Only Owner/Admin, via correction flow with mandatory reason + audit log. Invoiced logs are locked. | PROPOSED | work-log module |
| 12 | Meter rollover / replacement | Supervised "meter correction" event on the machine with reason, old/new reading; audit logged. | PROPOSED | machine module |
| 13 | Export / recovery | PDF export of invoices and reports; share-sheet export of photos. No cloud file backup in v1. | PROPOSED | — |
| 14 | Cloud photo/PDF backup | Out of scope for v1; a future object-storage option (S3-compatible) behind the API. | PROPOSED | — |
| 15 | Platforms | **Android only** (Android 8.0+, API 26+). iOS is out of scope; the generated `mobile/ios/` folder is unused and not built or tested. | CONFIRMED (2026-10-29) | `mobile/android/app/build.gradle.kts` |
| 16 | Data retention / closure | Suspended/expired company data retained 12 months, then deleted on written request. | PROPOSED | policy doc |
| 17 | Support process | Customer raises replacement request in-app; developer admin verifies by phone and approves in portal. | PROPOSED | — |
| 18 | Multiple invoices per range | Allowed; split by site or machine is allowed. Constraint: a work log can be in only one non-cancelled invoice. | PROPOSED | invoice module |

## Money, time, IDs (engineering decisions — not product-owner items)

- Money stored as integer **paise** (`int`). Never `double` for currency.
- Meter readings stored as integer **hundredths of an hour** (e.g. 1234.56 h → `123456`) to avoid float drift in hour arithmetic.
- Timestamps stored as UTC epoch milliseconds; displayed in device local time zone.
- Record IDs are client-generated UUID v4 (stable across sync retries → idempotent writes).
