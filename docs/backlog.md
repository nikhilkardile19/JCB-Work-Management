# Backlog & Sprint Board

Status: ✅ Done · 🔄 In progress · ⏳ Not started · ⛔ Blocked (needs owner action)

## Blockers requiring the product owner

Firebase Auth, Firestore and Cloud Functions were replaced by the Node.js +
PostgreSQL backend (ADR 0004). The former Firebase-console steps no longer
apply. What remains:

| Item | Why blocked | Unblocks |
|------|-------------|----------|
| Choose hosting for the API (Node 24) and a managed PostgreSQL 15+ | Billing/ownership | Staging and production (`docs/migration/deployment.md`) |
| Choose an SMTP provider; set `SMTP_*` and `MAIL_FROM` | Account/billing | Password-reset and activation-code emails (until then reset links are only logged and codes are only shown in the portal) |
| Confirm whether production Firestore/Auth hold real data (decision M1) | Only the owner can see the console | Run or skip the Firestore export/import at cutover |
| Accept that users set a new password after cutover (decision M2) | Product decision | Cutover communication |
| API domain + portal domain; add the API origin to the CSP in `firebase/firebase.json` | DNS ownership | Portal deploy (predeploy check) |
| Update GitHub secret `ADMIN_ENV_LOCAL` to `VITE_API_BASE_URL=https://<api>/api/v1` | GitHub repo admin | Automatic portal deploy |
| Create developer admins: `npm run admin:create -- --email … --role super` | Needs production DB access | Admin portal sign-in |
| Confirm `docs/product-decisions.md` items 1–18 (19–20 confirmed) and migration decisions M1–M8 | Product decisions | All sprints (defaults used meanwhile) |

## User stories (epics → acceptance criteria summarized)

| ID | Story | Acceptance | Sprint |
|----|-------|-----------|--------|
| US-01 | As a user I can sign in with email/password | Invalid creds show error; protected routes redirect to login | 2, M |
| US-02 | As an owner I can create my company profile | Required fields validated; profile cached locally | 2 |
| US-03 | As an admin I manage clients, sites, machines, operators, pumps offline | CRUD works in airplane mode; referenced records cannot be hard-deleted | 3 |
| US-04 | As an operator I log work from meter readings | hours = end − start; end < start rejected; photos stored app-private | 4 |
| US-05 | As an operator I make a manual entry with a reason | Reason mandatory; entry visibly marked; audit row written | 4 |
| US-06 | As a user I record fuel | total = liters × price; liters > 0 | 5 |
| US-07 | As accounts I invoice approved work logs | no double invoicing; rate override leaves site rate unchanged | 6 |
| US-08 | As accounts I record payments | partial payments update outstanding; overpayment blocked | 6 |
| US-09 | Records sync when online | no duplicates after retry; conflicts surfaced | 7 |
| US-10 | Device activation via license | server-side device limit; client cannot self-approve | 8 |
| US-11 | Developer admin manages companies/licenses/devices | only allowlisted admins; actions audited | 9 |
| US-12 | Device replacement request & approval | limit never exceeded; rejected device not activated | 10 |
| US-13 | Reports & dashboards | totals reconcile to source records | 11 |

## Sprint board

| Sprint | Title | Status |
|--------|-------|--------|
| 0 | Discovery and project setup | ✅ Done |
| 1 | UI foundation and navigation | ✅ Done |
| 2 | Authentication and company onboarding | ✅ Done (console setup ⛔ owner) |
| 3 | Masters and local database | ✅ Done |
| 4 | Work logs and meter readings | ✅ Done |
| 5 | Fuel management | ✅ Done |
| 6 | Invoicing, PDF and payments | ✅ Done (functions deploy ⛔ owner) |
| 7 | Offline sync engine | ✅ Done (rules deploy ⛔ owner) |
| 8 | License backend and device activation | ✅ Done (functions/rules deploy ⛔ owner) |
| 9 | Developer Admin Portal | ✅ Done (deploy ⛔ owner) |
| 10 | Device replacement and user administration | ✅ Done (deploy ⛔ owner) |
| 11 | Reports, polish and security hardening | ⏳ |
| 12 | QA, UAT and data recovery tests | ⏳ |
| 13 | Deployment and launch | ⏳ |
| M | Firebase → Node.js + PostgreSQL migration (`docs/migration/`) | 🔄 In progress |
