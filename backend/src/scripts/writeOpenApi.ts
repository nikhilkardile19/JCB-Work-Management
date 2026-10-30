/** Writes the OpenAPI document to docs/migration/openapi.json (npm run openapi). */
import { writeFileSync } from 'node:fs'
import { OpenApiGeneratorV31 } from '@asteasolutions/zod-to-openapi'
import { pino } from 'pino'
import { loadConfig } from '../config/env.js'
import type { AppContext } from '../context.js'
import type { Db } from '../database/prisma.js'
import { Api } from '../lib/http.js'
import { MemoryMailer } from '../lib/mailer.js'
import { systemClock } from '../lib/time.js'
import { registerRoutes } from '../routes.js'

const config = loadConfig({
  NODE_ENV: 'test',
  DATABASE_URL: 'postgresql://unused',
  JWT_ACCESS_SECRET: 'x'.repeat(32),
  PASSWORD_RESET_URL: 'https://example.invalid/reset-password',
})
const ctx: AppContext = { config, db: {} as Db, logger: pino({ level: 'silent' }), mailer: new MemoryMailer(), clock: systemClock }
const api = new Api(ctx)
registerRoutes(api)
const doc = new OpenApiGeneratorV31(api.registry.definitions).generateDocument({
  openapi: '3.1.0',
  info: { title: 'JCB Work Management API', version: '1.0.0' },
  servers: [{ url: '/api/v1' }],
})
const out = new URL('../../../docs/migration/openapi.json', import.meta.url)
writeFileSync(out, `${JSON.stringify(doc, null, 2)}\n`)
console.log(`Wrote ${Object.keys(doc.paths ?? {}).length} paths to ${out.pathname}`)
