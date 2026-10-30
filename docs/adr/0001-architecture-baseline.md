# ADR 0001 — Architecture baseline

> **Update 2026-10-30:** Firebase Auth, Firestore and Cloud Functions were
> replaced by the Node.js + PostgreSQL API — see
> [ADR 0004](0004-node-postgres-backend.md). The Firebase-specific parts of
> ADRs 0001–0003 below are kept as history; the layering, tenancy model and
> sync protocol still apply.


- Status: Accepted
- Date: 2026-10-29

## Context

Offline-first JCB work/billing app for multiple tenant companies, plus a developer
admin portal for licensing. See sections 5 and 16 of the sprint document.

## Decision

### Repository layout (monorepo)

```
mobile/    Flutter app (Android only — product decision #15)
admin/     React + Vite + TypeScript developer admin portal
firebase/  firebase.json, Firestore rules/indexes, Cloud Functions (Sprint 8)
docs/      ADRs, product decisions, backlog, conventions
```

### Mobile layering (feature-first, clean architecture)

```
lib/
  app/            App widget, router, bootstrapping
  core/           config, theme/design tokens, shared widgets, utils
  data/           Drift database, DAOs, sync metadata
  features/<f>/   presentation/ (screens, widgets), application/ (providers),
                  domain/ (models, pure logic), data/ (repositories)
```

- UI never talks to Drift or Firebase directly — only through repositories
  exposed as Riverpod providers.
- Domain logic (hour/amount calculations, validation) is pure Dart and unit-tested.
- State: Riverpod 3 (`Notifier`/`AsyncNotifier`, no legacy `StateProvider`).
- Navigation: GoRouter with a `redirect` guard driven by session state.
- Local DB: Drift with explicit `schemaVersion` and a `MigrationStrategy`.
- Design: Material 3, all values from `core/theme` tokens. No runtime font
  downloads (offline-first) — platform system fonts.

### Admin layering

- `src/app` (router, layout), `src/features/*`, `src/components/*`,
  `src/lib/*` (firebase, auth).
- Route protection via `RequireAuth`, backed by Firebase Auth plus the
  `developerAdmins/{uid}` allowlist (see ADR 0002).
- Privileged writes only via Cloud Functions (Sprint 8+).

### Environments

Firebase project `jcb-work-management` is the dev project (alias `dev` in
`firebase/.firebaserc`). Separate staging and production projects are to be
added before UAT.
Flutter selects environment through `--dart-define=APP_ENV=dev|staging|prod`;
the admin portal through Vite `.env.<mode>` files. No secrets in source.

## Consequences

- Console setup and rules deployment require the product owner's Google
  account — tracked in `docs/backlog.md` and `firebase/README.md`.
- Sprints 1–7 can be developed and tested fully offline against Drift and the
  Firebase Emulator Suite.

# ADR 0002 — Tenancy, membership lookup and onboarding gate (Sprint 2)

- Status: Accepted
- Date: 2026-10-29

- Memberships live at `companies/{companyId}/companyUsers/{uid}` (fields
  `uid`, `companyId`, `role`, `status`). A user finds their companies with a
  collection-group query on `uid`; rules only allow reading docs whose `uid`
  is the caller.
- Registration is one batch: company doc (`status: pending`) + owner
  membership. Rules use `getAfter()` to require both, and `!exists()` to stop
  anyone adding themselves to an existing company.
- Approval (`status: active`) is never client-writable; Sprint 9 moves it to
  a Cloud Function called by the admin portal.
- Developer admins are an allowlist collection `developerAdmins/{uid}`
  (console-managed). A custom claim can replace it later without UI changes.
- The mobile app caches memberships in Drift keyed by user ID and decides the
  route from a single `SessionState`. A cold cache with no server access is an
  error state ("connect once"), never "no company", so offline users are not
  sent to registration by mistake.

# ADR 0003 — Sync protocol (Sprint 7)

- Status: Accepted
- Date: 2026-10-29

- The local database is the source of truth for the UI; `syncStatus` on each
  row is the upload queue (`pending` → `synced`, or `conflict` / `error`).
- Each Firestore document carries `rev`; a write must set `rev = old + 1`
  (checked in a client transaction and in rules). The device stores the last
  `rev` it saw per record (`sync_records.serverRev`) and pushes against it.
- On mismatch: identical content = our own lost write (accept); masters =
  last `updatedAt` wins, loser logged as `sync_overwrite`; financial records
  = flagged for the user. No silent last-write-wins on money.
- Pull uses `(serverUpdatedAt, documentId)` cursors per collection; rows with
  local edits are skipped (their push resolves them).
- Device-local file paths are excluded from upload and preserved on
  download.
