import { createApp } from './app.js'
import { loadConfig } from './config/env.js'
import { createPrisma } from './database/prisma.js'
import { createLogger } from './lib/logger.js'
import { createMailer } from './lib/mailer.js'
import { systemClock } from './lib/time.js'

const config = loadConfig()
const logger = createLogger(config)
const db = createPrisma(config.DATABASE_URL, config.DATABASE_POOL_MAX)
const mailer = createMailer(config, logger)

if (config.NODE_ENV === 'production' && !config.SMTP_HOST) {
  logger.warn('SMTP_HOST is not set: password reset emails will only be written to the log')
}

const { app } = createApp({ config, db, logger, mailer, clock: systemClock })
const server = app.listen(config.PORT, () => {
  logger.info({ port: config.PORT, env: config.NODE_ENV }, 'JCB API listening')
})

let stopping = false
async function shutdown(signal: string) {
  if (stopping) return
  stopping = true
  logger.info({ signal }, 'Shutting down')
  server.close(async () => {
    await db.$disconnect()
    process.exit(0)
  })
  // Don't hang forever on keep-alive connections.
  setTimeout(() => process.exit(1), 10_000).unref()
}
process.on('SIGTERM', () => void shutdown('SIGTERM'))
process.on('SIGINT', () => void shutdown('SIGINT'))
