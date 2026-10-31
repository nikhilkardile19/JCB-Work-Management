# Deployment, operations, cutover and rollback

Provider-neutral. Needs: a Node.js 24 host (container or VM) behind HTTPS, a
managed PostgreSQL 15+ (17 recommended) on a **private network**, a static
host for the admin portal (Firebase Hosting is kept for that only), and an
SMTP account for password-reset and activation-code email.

```
 Android app ──HTTPS──▶ API (Node, ≥2 instances) ──TLS, private──▶ PostgreSQL
 Admin portal (static) ──HTTPS──▶ API              SMTP ◀── API (reset, code emails)
```

The API and the database must not share one machine in production, and the
database must not accept connections from the internet.

## 1. Environments

| | Development | Staging | Production |
|---|---|---|---|
| Database | local `jcb_dev`, `jcb_test` | managed, own instance | managed, own instance, PITR on |
| `NODE_ENV` | `development` | `production` | `production` |
| `JWT_ACCESS_SECRET` | any 32+ chars | unique secret | unique secret (rotate yearly) |
| `CORS_ORIGINS` | `http://localhost:5173` | staging portal origin | production portal origin |
| `PASSWORD_RESET_URL` | `http://localhost:5173/reset-password` | `https://<staging-portal>/reset-password` | `https://<portal>/reset-password` |
| `API_DOCS_ENABLED` | on (default) | `true` (for testers) | off (default) |
| SMTP | unset (reset links logged; activation codes only shown in the portal) | real, test inbox | real |
| Seed data | `npm run db:seed` | optional | **never** (the seed refuses) |
| Portal build | `admin/.env.local` | `admin/.env.staging` (`npm run build -- --mode staging`) | `admin/.env.local` or CI secret `ADMIN_ENV_LOCAL` |
| App build | `APP_ENV=dev` (default API `http://10.0.2.2:3000/api/v1`) | `APP_ENV=staging` + `API_BASE_URL` | `APP_ENV=prod` + `API_BASE_URL` |

All settings are listed with comments in `backend/.env.example`. Secrets live
in the host's secret store, never in git.

## 2. PostgreSQL

1. Create the instance (private networking, TLS required, automated daily
   backups + point-in-time recovery, ≥ 7 days retention; 30 for production).
2. Create the database and a least-privilege application role:
   ```sql
   CREATE DATABASE jcb;
   CREATE ROLE jcb_app LOGIN PASSWORD '<generated>';
   GRANT CONNECT ON DATABASE jcb TO jcb_app;
   \c jcb
   GRANT USAGE, CREATE ON SCHEMA public TO jcb_app;   -- CREATE only needed by migrations
   ```
   For stricter setups use a separate `jcb_migrator` role for migrations and
   grant `jcb_app` only `SELECT, INSERT, UPDATE, DELETE` on the tables.
3. `DATABASE_URL=postgresql://jcb_app:<pw>@<private-host>:5432/jcb?sslmode=require`
4. Apply migrations (release step, before new API instances start):
   `npx prisma migrate deploy` (in `backend/`, or in the image:
   `docker run --env-file … jcb-api npx prisma migrate deploy`).
   Migrations are additive and versioned in `backend/prisma/migrations/`.

## 3. API (Node.js)

- Build: `docker build -t jcb-api backend/` (multi-stage, runs as `node`,
  has a `HEALTHCHECK`), or on a VM: `npm ci && npm run build && npm start`
  under a process manager (systemd, PM2).
- Run ≥ 2 instances behind a load balancer that terminates HTTPS
  (TLS 1.2+). Set `TRUST_PROXY` to the number of proxies in front so client
  IPs (used by login rate limits) are correct.
- Health checks: liveness `GET /health`; readiness `GET /health/ready`
  (checks PostgreSQL; 503 when unreachable). Point the load balancer at
  `/health/ready`.
- Graceful shutdown on `SIGTERM` (stops accepting, finishes requests,
  closes the pool; 10 s cap).
- Pool size: `DATABASE_POOL_MAX` per instance × instances must stay below
  the database's connection limit (leave room for migrations and admins).
- All rate limits that matter (sign-in failures, activation codes,
  replacement requests, invitations) are stored in PostgreSQL and shared by
  every instance. Expired counters can be purged daily (optional):
  `DELETE FROM rate_limits WHERE expires_at < now();`

### Developer admins

```bash
npm run admin:create -- --email you@company.in --role super
npm run admin:create -- --email support@company.in --role support --permissions devices.revoke
```

The command prints a 24-hour link to set the password.

## 4. Admin portal (static)

1. `admin/.env.local` (or CI secret `ADMIN_ENV_LOCAL`):
   `VITE_API_BASE_URL=https://<api-host>/api/v1`
2. In `firebase/firebase.json`, add the API origin to the CSP `connect-src`.
   The predeploy step refuses to publish while `VITE_API_BASE_URL` is unset
   or its origin is missing from `connect-src`.
3. `cd firebase && npm ci && npm run deploy:hosting` (CI does this on push to
   `main`). Any static host works instead: serve `admin/dist` with an SPA
   fallback to `index.html` and the same security headers as `firebase.json`.
4. Add the portal origin to the API's `CORS_ORIGINS`, and set
   `PASSWORD_RESET_URL` to `https://<portal-host>/reset-password`.

## 5. Android app

```bash
cd mobile
# config/prod.json sets APP_ENV=prod and the production API_BASE_URL
# (currently https://jcb-api.onrender.com/api/v1).
flutter build appbundle --release --dart-define-from-file=config/prod.json
```

Release builds allow HTTPS only (`usesCleartextTraffic="false"`); cleartext
to `10.0.2.2`/`localhost` is allowed only in debug builds for local
development. The refresh token is kept in Android Keystore-backed secure
storage.

## 6. Logging and monitoring

- Structured JSON logs (pino) to stdout, one line per request with
  `X-Request-Id` (echoed to clients; pass your own to correlate). Tokens,
  passwords and activation codes are redacted.
- Refusals (`unauthenticated`, `permission_denied`, `resource_exhausted`) are
  logged as warnings with the reason; unexpected errors as `error` with stack.
  Clients only ever see a generic message.
- Alert on: readiness failures, 5xx rate > 1 %, p95 latency > 1 s,
  `Refresh token reuse detected` warnings, bursts of `rate_limited`,
  database CPU/connections/storage, and backup failures.
- `audit_events` holds every license, device, company, user and admin
  action (who, when, reason, before/after); the portal's Audit page reads it.

## 7. Backups and restore

- Managed PostgreSQL: daily snapshots + point-in-time recovery (WAL).
- Additionally, a nightly logical dump kept off-provider:
  `pg_dump --format=custom --no-owner "$DATABASE_URL" > jcb-$(date +%F).dump`
- **Restore drill (monthly, into staging):**
  ```bash
  createdb jcb_restore
  pg_restore --no-owner --dbname=jcb_restore jcb-YYYY-MM-DD.dump
  DATABASE_URL=…/jcb_restore npx prisma migrate status   # schema up to date
  ```
  then point a staging API at it and run the staging checks below.
- Phones keep their own data (offline-first); after a restore to an earlier
  point, records synced after that point are still `synced` on phones but
  missing on the server. Restores should therefore be followed by asking
  users to keep their phones; a "re-upload everything" switch is a possible
  follow-up (not built).

## 8. Staging verification (before every production release)

1. `npm test` green in CI (backend), admin lint/test/build, mobile analyze/test.
2. `npx prisma migrate deploy` on staging; `migrate status` clean.
3. `GET /health/ready` = 200 on every instance.
4. Portal: sign in as a support admin; dashboard counts load; approve a test
   company; issue a license (code shown once); suspend/reactivate; rotate
   code; audit trail shows each action with its reason.
5. Phone (staging build): sign in, select company, activate with the code,
   create masters, a work log (photo and manual), fuel entry; go offline,
   create more; reconnect — everything syncs; a second phone pulls it.
6. Finalize an invoice (number issued), record a part payment, try an
   overpayment (refused), cancel an invoice with a reason.
7. Device limit: activate one phone too many → replacement request →
   approve in the portal → new phone works, old one becomes read-only.
8. Forgot password → email arrives → reset page → sign in; old sessions end.

## 9. Production cutover

Firestore is believed to be empty or test-only (see README, decision M1);
if the owner confirms real data exists, do steps marked **(data)**.

1. Freeze: announce a window; pause mobile releases (already paused).
2. **(data)** Export Firestore + Auth read-only with
   `tools/firestore-export` (see its README); keep the export as the backup.
3. Create production PostgreSQL, apply migrations.
4. **(data)** `npm run import:firestore -- --dry-run …`, review the report,
   then import for real; reconciliation (counts and money totals) must pass.
5. Deploy the API; check `/health/ready`; create developer admins.
6. Deploy the portal with `VITE_API_BASE_URL`; verify sign-in.
7. Publish the Android build pointing at the production API.
8. **(data)** Tell users to use "Forgot password" once (Firebase passwords
   cannot be migrated).
9. Watch logs and dashboards for 48 hours.
10. Firebase: leave Auth/Firestore untouched (read-only reference) for the
    retention period; then disable the Firebase Web/Android apps. Keep the
    export files per the retention policy. Firebase Hosting stays for the
    portal.

## 10. Rollback

| Failure | Action |
|---|---|
| Bad API release | Redeploy the previous image; migrations are additive, so the old code runs on the new schema. |
| Bad migration | Restore to the point before the release (PITR) on a new instance, switch `DATABASE_URL`, redeploy the previous image. Phones re-upload anything still `pending`. |
| Bad portal release | `firebase hosting:rollback` or redeploy the previous build. |
| Bad app release | Halt the staged rollout in Play Console; publish the previous build with a higher version code. |
| Abandon the migration entirely (before users move) | Firebase was never modified by the export; the previous Firebase-based builds on `main` keep working against it. After users have moved, roll forward instead — new data exists only in PostgreSQL. |
