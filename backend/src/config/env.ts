import { z } from 'zod'

const bool = z
  .enum(['true', 'false', '1', '0'])
  .transform((v) => v === 'true' || v === '1')

const list = z
  .string()
  .transform((v) => v.split(',').map((s) => s.trim()).filter(Boolean))

/** Every setting comes from the environment; see `.env.example`. */
const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  DATABASE_POOL_MAX: z.coerce.number().int().positive().default(10),

  JWT_ACCESS_SECRET: z.string().min(32, 'JWT_ACCESS_SECRET must be at least 32 characters'),
  JWT_ISSUER: z.string().default('jcb-api'),
  JWT_AUDIENCE: z.string().default('jcb-clients'),
  ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().min(60).max(3600).default(900),
  /** Mobile sessions slide: every refresh issues a token valid this long. */
  REFRESH_TOKEN_TTL_DAYS_MOBILE: z.coerce.number().int().min(1).max(365).default(60),
  REFRESH_TOKEN_TTL_HOURS_PORTAL: z.coerce.number().int().min(1).max(720).default(12),
  /** A rotated refresh token presented again within this window, while its
   *  successor is still unused, is treated as a retry after a lost response. */
  REFRESH_REUSE_GRACE_SECONDS: z.coerce.number().int().min(0).max(600).default(60),

  PASSWORD_RESET_URL: z.url(),
  PASSWORD_RESET_TTL_MINUTES: z.coerce.number().int().min(5).max(1440).default(60),

  CORS_ORIGINS: list.default([]),
  /** Express `trust proxy`: number of proxy hops in front of the API. */
  TRUST_PROXY: z.coerce.number().int().min(0).default(0),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),
  API_DOCS_ENABLED: bool.optional(),

  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.coerce.number().int().positive().default(587),
  SMTP_SECURE: bool.default(false),
  SMTP_USER: z.string().optional(),
  SMTP_PASSWORD: z.string().optional(),
  MAIL_FROM: z.string().default('JCB Works <no-reply@localhost>'),
})

export type Config = ReturnType<typeof loadConfig>

export function loadConfig(env: NodeJS.ProcessEnv = process.env) {
  const parsed = schema.safeParse(env)
  if (!parsed.success) {
    const problems = parsed.error.issues.map((i) => `  ${i.path.join('.')}: ${i.message}`).join('\n')
    throw new Error(`Invalid configuration:\n${problems}`)
  }
  const c = parsed.data
  if (c.NODE_ENV === 'production' && c.CORS_ORIGINS.some((o) => o === '*')) {
    throw new Error('Invalid configuration: CORS_ORIGINS must list exact origins in production')
  }
  return { ...c, apiDocsEnabled: c.API_DOCS_ENABLED ?? c.NODE_ENV !== 'production' }
}
