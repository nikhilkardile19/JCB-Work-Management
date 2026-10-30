# Firebase Hosting (admin portal only)

Firebase is used **only** to serve the static developer admin portal
(`admin/`). Authentication, data and server logic moved to the Node.js +
PostgreSQL API in `backend/` (ADR 0004); Firestore rules and Cloud Functions
were removed in that migration and remain in git history.

Project: **jcb-work-management** (alias `dev` in `.firebaserc`).

## Deploy the portal

1. `admin/.env.local` must contain `VITE_API_BASE_URL=https://<api-host>/api/v1`.
2. Add that API origin to `connect-src` of the `Content-Security-Policy` in
   `firebase.json` (e.g. `connect-src 'self' https://api.example.in`).
3. `npm ci && npm run deploy:hosting` (needs `npx firebase login` once).

`npm run check:portal` runs the same check as the deploy: it refuses to
publish while the API URL is missing, not HTTPS, or not allowed by the CSP.
Every push to `main` also deploys automatically (CI job `deploy-hosting`,
GitHub secrets `FIREBASE_SERVICE_ACCOUNT` — Firebase Hosting Admin role only —
and `ADMIN_ENV_LOCAL`, the contents of `admin/.env.local`).

Undo a bad release: `npm run hosting:rollback`.

Any other static host works too: serve `admin/dist` with an SPA fallback to
`index.html` and the same security headers as `firebase.json`.
