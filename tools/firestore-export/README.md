# Firestore export (migration Phase F)

Read-only export of the JCB Firestore database and Firebase Auth users to a
backup directory of NDJSON files. `npm run import:firestore` in `backend/`
loads such a backup into PostgreSQL and reconciles it. The mapping is in
`docs/migration/README.md` ("Firestore → PostgreSQL mapping"); decisions M1
(migrate only if production data exists) and M2 (passwords are not migrated)
apply.

## Safety

- **Read-only by construction.** Only `src/firebaseSource.ts` opens Firebase,
  and it only lists and reads. The exporter gets a narrow read interface, never
  the Firestore or Auth objects. `npm run check` fails if a write API appears
  there or Firebase is opened anywhere else in `src/`.
- **Use a read-only service account anyway**: grant it only
  `roles/datastore.viewer` (Cloud Datastore Viewer) and
  `roles/firebaseauth.viewer` (Firebase Authentication Viewer).
- **Never overwrites.** `--out` must be a new or empty directory; files are
  opened exclusively, and `manifest.json` is written last (a backup without it
  is incomplete).
- **Emulator or real, never mixed.** With `FIRESTORE_EMULATOR_HOST` and
  `FIREBASE_AUTH_EMULATOR_HOST` set (both), the SDK talks only to the
  emulators. Setting just one is refused. A `demo-*` project is refused
  without them.
- Backups hold customer data (emails, invoices). Store them encrypted, outside
  git; `.gitignore` here ignores `exports/` and `*.ndjson`.

## Running a real migration

Freeze writes first: pause the apps or announce a maintenance window. The
export reads collection by collection, not at a single point in time.

```sh
# 0. Install and check (Node 24)
cd tools/firestore-export
npm ci
npm run check                       # typecheck + read-only guard

# 1. Export (real project, read-only key; make sure no *_EMULATOR_HOST is set)
env -u FIRESTORE_EMULATOR_HOST -u FIREBASE_AUTH_EMULATOR_HOST \
  GOOGLE_APPLICATION_CREDENTIALS=/secure/jcb-export-reader.json \
  npm run export -- --project jcb-work-management --out /secure/backups/firestore-2026-11-01

# 2. Dry run: validates, imports inside a transaction, reconciles, rolls back
cd ../../backend
DATABASE_URL='postgresql://USER:PASSWORD@HOST:5432/jcb' npm run db:deploy
DATABASE_URL='postgresql://USER:PASSWORD@HOST:5432/jcb' \
  npm run import:firestore -- /secure/backups/firestore-2026-11-01 --dry-run \
  --report-dir /secure/backups/firestore-2026-11-01-reports/dry-run

# 3. Import into the empty production database (--fresh refuses a non-empty one)
DATABASE_URL='postgresql://USER:PASSWORD@HOST:5432/jcb' \
  npm run import:firestore -- /secure/backups/firestore-2026-11-01 --fresh \
  --report-dir /secure/backups/firestore-2026-11-01-reports/import

# 4. Read the report
less /secure/backups/firestore-2026-11-01-reports/import/migration-report.txt
jq '.reconciliation, .problemCounts' /secure/backups/firestore-2026-11-01-reports/import/migration-report.json
jq '.problems[] | select(.severity == "error")' /secure/backups/firestore-2026-11-01-reports/import/migration-report.json
```

`backend/.env` is loaded by `npm run import:firestore`, but a `DATABASE_URL`
given on the command line wins. Always pass it explicitly.

Rehearsals can rerun step 3 without `--fresh`: every write is an upsert keyed
by the Firestore IDs, so a rerun of the same backup changes nothing. Do not
rerun after cutover: rows created through the new API are not in the backup,
so reconciliation then fails on purpose.

After the import, users sign in only after "Forgot password" (decision M2).
SMTP must be configured for the reset emails.

### Export options

| Option | Meaning |
|---|---|
| `--project <id>` | Required. The Firebase project ID. |
| `--out <dir>` | Required. New or empty directory. |
| `--page-size <n>` | Documents per read (default 500). |
| `--deep` | Look for subcollections under every document, not only under `companies/*` and `developerAdmins/*`. One extra request per document. |
| `--skip-auth` | Do not export Firebase Auth users. |
| `--quiet` | No progress lines. |

### Import options (`backend/`, `npm run import:firestore -- <dir> …`)

| Option | Meaning |
|---|---|
| `--dry-run` | Everything inside one transaction, reconciled, then rolled back. |
| `--fresh` | Refuse unless the target has no users, companies, developer admins or audit events. |
| `--strict` | Also exit 1 when any source record was rejected. |
| `--report-dir <dir>` | Where `migration-report.json` and `.txt` go (default: the export directory). |
| `--timeout-minutes <n>` | Per-company transaction timeout (default 10). |

Exit codes: `0` reconciled, `1` reconciliation failed (or `--strict` with
rejected records), `2` could not run (bad arguments, no `manifest.json`,
`--fresh` on a non-empty database, database unreachable).

## Backup format (version 1)

```
manifest.json                 format, formatVersion, projectId, emulator hosts, startedAt,
                              exportedAt, tool versions, counts per kind, files (name, count, sha256)
companies.ndjson              kind "companies"
companies.workLogs.ndjson     kind "companies/*/workLogs" (one file per collection path kind)
auditEvents.ndjson, rateLimits.ndjson, developerAdmins.ndjson, …
auth-users.ndjson             kind "__auth__" (Firebase Auth users)
```

One document per line:

```json
{"path":"companies/co/workLogs/w1","id":"w1","data":{…}}
{"path":"__auth__/UID","id":"UID","data":{"uid":"UID","email":"…","emailVerified":false,"disabled":false,"createdAt":{"__type":"timestamp","ms":…},"lastSignInAt":null,"providerIds":["password"]}}
```

No password hashes are exported. Values JSON cannot hold are tagged:

| Firestore value | Encoding |
|---|---|
| Timestamp | `{"__type":"timestamp","ms":<epoch ms>,"ns":<extra ns 1–999999>}` (`ns` omitted when 0) |
| GeoPoint | `{"__type":"geopoint","lat":…,"lng":…}` |
| Reference | `{"__type":"reference","path":"…"}` |
| Bytes | `{"__type":"bytes","base64":"…"}` |
| Vector | `{"__type":"vector","values":[…]}` |
| Integer beyond ±2^53 | `{"__type":"int64","value":"…"}` |
| NaN, ±Infinity | `{"__type":"double","value":"NaN"}` |
| A map with its own `__type` key | `{"__type":"map","value":{…}}` |

The importer checks each file's line count and SHA-256 against
`manifest.json`, so a truncated or edited backup fails reconciliation.

## Testing against the emulator

Needs Java 21+ and PostgreSQL (`createdb`/`dropdb`/`psql` on the path).

```sh
cd tools/firestore-export
FIREBASE_BIN=../../firebase/node_modules/.bin/firebase npm run test:emulator
# without FIREBASE_BIN it uses: npx --yes firebase-tools@15.34.2
```

This starts the Firestore (port 8085) and Auth (9099) emulators for the
offline project `demo-jcb-export`, then runs `test/e2e.ts`, which:

1. seeds the emulators from `backend/tests/fixtures/firestore-export`;
2. exports them (page size 2, to exercise paging) and checks that no emulator
   document's update time changed;
3. checks the export equals the fixture (lossless round trip);
4. creates the scratch database `jcb_import_check` (`E2E_DATABASE` to
   change), runs the dry run, `--fresh` import and an upsert rerun, all of
   which must exit 0, and checks the report;
5. drops the scratch database.

To poke at the emulator by hand:

```sh
npx --yes firebase-tools@15.34.2 emulators:start --only firestore,auth --project demo-jcb-export
FIRESTORE_EMULATOR_HOST=127.0.0.1:8085 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
  npm run export -- --project demo-jcb-export --out /tmp/jcb-export-test
```
