#!/bin/sh
# Applies pending migrations, then starts the API. For hosts without a separate
# release step (e.g. Render's free plan, Docker Command `sh scripts/start-with-migrations.sh`).
# `exec` keeps node as the main process so it receives SIGTERM (graceful shutdown).
set -e
npx prisma migrate deploy
exec node dist/server.js
