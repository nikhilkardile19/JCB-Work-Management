# JCB Work Management API

Node.js 24 · Express 5 · TypeScript · Prisma 7 · PostgreSQL 15+ · Zod 4.
Replaces Firebase Auth, Firestore and the Cloud Functions
([ADR 0004](../docs/adr/0004-node-postgres-backend.md)). The API contract is
[`docs/migration/api-contract.md`](../docs/migration/api-contract.md); the
generated OpenAPI document is served at `/api/docs` (Swagger UI) and
`/api/docs/openapi.json`, and committed as `docs/migration/openapi.json`.

## Quick start (development)

```bash
cp .env.example .env              # fill DATABASE_URL, TEST_DATABASE_URL, JWT_ACCESS_SECRET
createdb jcb_dev && createdb jcb_test
npm ci
npm run db:migrate                # apply migrations to jcb_dev (+ generate the client)
npm run db:seed                   # demo company, users and an activation code (dev only)
npm run dev                       # http://localhost:3000, docs at /api/docs
```

Seeded accounts (password `jcb-dev-password`, override with `SEED_PASSWORD`):
`admin@jcb.local` (super developer admin), `owner@jcb.local`,
`operator@jcb.local`, `accounts@jcb.local`; activation code
`JCBW-DEVA-CODE-2026` for "Demo Earthmovers".

## Commands

| Task | Command |
|------|---------|
| Dev server (watch) | `npm run dev` |
| Type-check | `npm run typecheck` |
| Tests (needs `TEST_DATABASE_URL`, a disposable DB) | `npm test` |
| Build / run production | `npm run build` then `npm start` |
| New migration after editing `prisma/schema.prisma` | `npm run db:migrate -- --name <change>` |
| Apply migrations (staging/prod) | `npm run db:deploy` |
| Grant developer-admin access | `npm run admin:create -- --email you@x.in --role super` |
| Regenerate `docs/migration/openapi.json` | `npm run openapi` |
| Import a Firestore export | `npm run import:firestore -- …` (see `tools/firestore-export/README.md`) |

## Layout

```
src/
  server.ts            process entry (graceful shutdown)
  app.ts               middleware, health, docs, routes
  routes.ts            every module's routes under /api/v1
  config/env.ts        validated environment
  lib/http.ts          route helper: Zod validation + OpenAPI + auth in one place
  lib/errors.ts        error envelope and codes
  middleware/errors.ts error → JSON, safe messages, refusal logging
  modules/
    auth/              login, refresh rotation, logout, reset, JWT
    companies/         registration, profile, membership access checks
    members/           company users (invite, role, disable)
    licenses/          activation codes, activate/validate, license rules
    replacements/      device replacement request/status/review
    invoice-numbers/   official invoice numbers
    sync/              offline sync: field specs, ported rules, push/pull
    admin/             developer admin portal endpoints
    audit/             server-written history (audit_events)
    rate-limits/       PostgreSQL fixed-window limits
  scripts/             createAdmin, writeOpenApi, importFirestore
prisma/
  schema.prisma        tables, keys, relations
  migrations/          SQL migrations (incl. CHECK constraints)
  seed.ts              development data
tests/                 vitest + supertest against a real PostgreSQL
```

## Testing

Tests run against a real PostgreSQL database (`TEST_DATABASE_URL`), which is
migrated once per run and emptied before every test. They include a port of
every former Firestore rules test and Cloud Functions test, plus concurrency
tests (device limits, invoice numbers, sync revisions).

## Provenance

Comments such as "ported from `functions/src/licenses.ts`" or
"`firebase/firestore.rules`" refer to the former Firebase backend, removed in
the migration. Those files are in git history: `git show c859259:firebase/firestore.rules`.
