#!/bin/sh
# Emulator end-to-end check: seed Firestore + Auth emulators from the backend
# fixture, export with this tool, import into a scratch PostgreSQL database
# (E2E_DATABASE, default jcb_import_check; dropped afterwards) and require
# reconciliation to pass. Needs Java 21+ and firebase-tools; set FIREBASE_BIN
# to use an installed CLI (e.g. ../../firebase/node_modules/.bin/firebase).
# The demo- project ID keeps the CLI and SDKs offline: no real project is used.
set -eu
cd "$(dirname "$0")/.."
FIREBASE="${FIREBASE_BIN:-npx --yes firebase-tools@15.34.2}"
exec $FIREBASE emulators:exec --only firestore,auth --project demo-jcb-export "node test/e2e.ts"
