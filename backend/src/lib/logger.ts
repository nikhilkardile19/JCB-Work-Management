import { pino } from 'pino'
import type { Config } from '../config/env.js'

export function createLogger(config: Pick<Config, 'LOG_LEVEL' | 'NODE_ENV'>) {
  return pino({
    level: config.NODE_ENV === 'test' ? 'silent' : config.LOG_LEVEL,
    redact: {
      paths: [
        'req.headers.authorization',
        'req.headers.cookie',
        '*.password',
        '*.refreshToken',
        '*.accessToken',
        '*.token',
        '*.activationCode',
      ],
      censor: '[redacted]',
    },
  })
}
