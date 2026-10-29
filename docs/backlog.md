# Backlog & Sprint Board

Status: ✅ Done · 🔄 In progress · ⏳ Not started · ⛔ Blocked (needs owner action)

## Blockers requiring the product owner

| Item | Why blocked | Unblocks |
|------|-------------|----------|
| Enable Email/Password sign-in in Firebase Authentication | Console access | Real sign-in on devices |
| Create the Firestore database (`asia-south1` recommended) | Console access | Company registration |
| Deploy rules + indexes: `cd firebase && npx firebase login && npm run deploy:rules` | Needs owner's Google login | Company registration, membership lookup |
| Add `developerAdmins/{uid}` docs for each admin | Console access | Admin portal sign-in |
| Register a Web app; fill `admin/.env.local` | Console access | Admin portal sign-in |
| Deploy the admin portal: `cd firebase && npm run deploy:hosting` | Needs owner's Google login + `admin/.env.local` | Admin portal at https://jcb-work-management.web.app |
| Add GitHub secrets `FIREBASE_SERVICE_ACCOUNT` and `ADMIN_ENV_LOCAL` (see `firebase/README.md`) | Google Cloud + GitHub repo admin | Automatic portal deploy on push to `main` |
| Upgrade to Blaze plan and deploy Cloud Functions (`cd firebase && npm run deploy:functions`) | Billing account | Invoice finalization (official numbers) |
| Create staging and production Firebase projects | Billing/ownership | Sprint 12–13 |
| Confirm `docs/product-decisions.md` items 1–18 | Product decisions | All sprints (defaults used meanwhile) |

## User stories (epics → acceptance criteria summarized)

| ID | Story | Acceptance | Sprint |
|----|-------|-----------|--------|
| US-01 | As a user I can sign in with email/password | Invalid creds show error; protected routes redirect to login | 2 |
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
