import { loadConfig } from '../config/env.js'
import type { AppContext } from '../context.js'
import { createPrisma } from '../database/prisma.js'
import { createLogger } from '../lib/logger.js'
import { createMailer } from '../lib/mailer.js'
import { systemClock } from '../lib/time.js'

/** The app context for one-off command-line scripts. */
export function cliContext(): AppContext {
  const config = loadConfig()
  const logger = createLogger(config)
  return { config, logger, db: createPrisma(config.DATABASE_URL, 2), mailer: createMailer(config, logger), clock: systemClock }
}

export function arg(name: string, fallback?: string): string {
  const i = process.argv.indexOf(`--${name}`)
  const v = i >= 0 ? process.argv[i + 1] : fallback
  if (v === undefined) {
    console.error(`Missing --${name}`)
    process.exit(1)
  }
  return v
}
