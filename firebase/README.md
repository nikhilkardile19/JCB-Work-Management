# Firebase backend

Project: **jcb-work-management** (single project used as `dev` until staging/prod exist).

## Commands (run in this folder)

| Task | Command |
|------|---------|
| Install | `npm install` |
| Security Rules tests (emulator, no real data) | `npm run test:rules` |
| Local emulators | `npm run emulators` |
| Deploy rules + indexes | `npx firebase login` once, then `npm run deploy:rules` |
| Cloud Functions tests (emulator) | `npm install --prefix functions && npm run test:functions` |
| Deploy Cloud Functions | `npm run deploy:functions` (needs the Blaze plan) |

The Firestore emulator uses port **8085** (8080 is taken on the dev machine).

## One-time console setup (project owner)

1. **Authentication → Sign-in method → Email/Password → Enable.**
2. **Firestore Database → Create database** (production mode, region `asia-south1` recommended for India).
3. Deploy rules and indexes: `npm run deploy:rules`. The `companyUsers.uid`
   collection-group index is required for membership lookup.
4. **Developer admin allowlist:** for each admin, create the user in
   Authentication, then add a Firestore document `developerAdmins/{thatUid}`
   with fields `email` and `role`:
   - `role: "super"` — full access (companies, licenses, devices).
   - `role: "support"` (or no role) — read-only, plus any grants listed in
     `permissions` (array of `companies.manage`, `licenses.manage`,
     `devices.revoke`).
   Clients can never write this collection; every admin action is checked
   again on the server and recorded in `auditEvents`.
5. **Approving a company:** in the admin portal, Companies → Awaiting
   approval → open the company → Approve (a reason is required and logged).
6. **Admin portal web app:** Project settings → Add app → Web. Copy the SDK
   config into `admin/.env.local` (template: `admin/.env.example`).
7. **Invoice numbering:** upgrade the project to the **Blaze (pay-as-you-go)**
   plan (required for Cloud Functions; set a budget alert), then
   `npm run deploy:functions`. This deploys `allocateInvoiceNumber` in
   `asia-south1`. Until it is deployed, invoices can be drafted but not
   finalized.
8. **Issue a license for a company:** in the admin portal, open the company →
   Licenses → New license; the activation code is shown once. (A command-line
   alternative needs a service-account key for the project:)
   ```
   cd firebase && npm --prefix functions run build
   GOOGLE_APPLICATION_CREDENTIALS=key.json node functions/lib/cli/createLicense.js \
     --company <companyId> --admin <yourDeveloperAdminUid> --months 12 --devices 2
   ```
   Give the printed activation code to the company owner; it is shown once
   and only its hash is stored. Each phone enters it once (online).
9. Recommended: in Google Cloud console → APIs & Services → Credentials,
   restrict the Android API key to package `com.app.jcb_work_management`
   with your signing certificate SHA-1.
10. **Rate-limit cleanup (optional):** Firestore → TTL policies → add a policy
    on collection group `rateLimits`, field `expiresAt`, so old abuse
    counters are deleted automatically. Counters work without it.
11. **App Check (Sprint 13, before launch):** follow
    `docs/security-review.md` → "App Check evaluation". Enforcement is
    switched on with `ENFORCE_APP_CHECK=true` in `functions/.env`, then
    `npm run deploy:functions` — only after the console shows that nearly
    all requests are verified.
