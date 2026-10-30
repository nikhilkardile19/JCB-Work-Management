import { pino } from 'pino'
import supertest from 'supertest'
import { afterAll, beforeEach } from 'vitest'
import { createApp } from '../../src/app.js'
import { loadConfig } from '../../src/config/env.js'
import type { AppContext } from '../../src/context.js'
import { createPrisma, type Db } from '../../src/database/prisma.js'
import { MemoryMailer } from '../../src/lib/mailer.js'
import { TEST_DATABASE_URL } from './globalSetup.js'

export const config = loadConfig({
  NODE_ENV: 'test',
  DATABASE_URL: TEST_DATABASE_URL,
  JWT_ACCESS_SECRET: 'test-secret-test-secret-test-secret-0123456789',
  PASSWORD_RESET_URL: 'https://admin.example.test/reset-password',
  CORS_ORIGINS: 'https://admin.example.test',
  API_DOCS_ENABLED: 'true',
})

let shared: Db | null = null
const db = () => (shared ??= createPrisma(TEST_DATABASE_URL, 5))

/** Mutable test clock (defaults to real time). */
export class TestClock {
  private offsetMs = 0
  now = () => new Date(Date.now() + this.offsetMs)
  advance(ms: number) {
    this.offsetMs += ms
  }
}

export interface TestEnv {
  ctx: AppContext
  db: Db
  mailer: MemoryMailer
  clock: TestClock
  request: ReturnType<typeof supertest>
}

/** A fresh app per test file; the database is emptied before every test. */
export function useTestApp(): TestEnv {
  const clock = new TestClock()
  const mailer = new MemoryMailer()
  const ctx: AppContext = { config, db: db(), logger: pino({ level: 'silent' }), mailer, clock: clock.now }
  const { app } = createApp(ctx)
  const env: TestEnv = { ctx, db: ctx.db, mailer, clock, request: supertest(app) }

  beforeEach(async () => {
    await truncateAll(ctx.db)
    mailer.sent.length = 0
  })
  afterAll(async () => {
    await shared?.$disconnect()
    shared = null
  })
  return env
}

export async function truncateAll(db: Db) {
  const tables = await db.$queryRaw<{ tablename: string }[]>`
    SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename <> '_prisma_migrations'`
  if (tables.length) {
    await db.$executeRawUnsafe(`TRUNCATE TABLE ${tables.map((t) => `"${t.tablename}"`).join(', ')} CASCADE`)
  }
}
