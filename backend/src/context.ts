import type { Logger } from 'pino'
import type { Config } from './config/env.js'
import type { Db } from './database/prisma.js'
import type { Mailer } from './lib/mailer.js'
import type { Clock } from './lib/time.js'

/** Everything a request handler needs; injected so tests can replace parts. */
export interface AppContext {
  config: Config
  db: Db
  logger: Logger
  mailer: Mailer
  clock: Clock
}
