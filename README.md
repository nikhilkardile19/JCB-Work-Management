# JCB Work Management & Billing

Offline-first Flutter app + React developer admin portal on a Node.js REST API
and PostgreSQL.

| Folder | What |
|--------|------|
| `mobile/` | Flutter app (Android only) — Drift offline store, syncs with the API |
| `admin/` | React + Vite + TS developer admin portal |
| `backend/` | Node.js + Express + Prisma REST API (`/api/v1`) on PostgreSQL |
| `firebase/` | Firebase Hosting config for the static admin portal only |
| `tools/firestore-export/` | One-off, read-only export of the former Firestore data |
| `docs/` | ADRs, migration plan, API contract, deployment, product decisions, backlog |

Start with `docs/backlog.md` (sprint board + blockers), `docs/conventions.md`
(commands) and `docs/migration/` (Firebase → Node/PostgreSQL migration,
API contract, deployment and rollback).
