import { OpenApiGeneratorV31 } from '@asteasolutions/zod-to-openapi'
import cors from 'cors'
import express from 'express'
import { rateLimit } from 'express-rate-limit'
import helmet from 'helmet'
import { pinoHttp } from 'pino-http'
import swaggerUi from 'swagger-ui-express'
import type { AppContext } from './context.js'
import { Api } from './lib/http.js'
import { newId } from './lib/ids.js'
import { errorHandler, notFoundHandler } from './middleware/errors.js'
import { registerRoutes } from './routes.js'

export const API_PREFIX = '/api/v1'

export function createApp(ctx: AppContext) {
  const app = express()
  app.disable('x-powered-by')
  app.set('trust proxy', ctx.config.TRUST_PROXY)

  app.use(
    pinoHttp({
      logger: ctx.logger,
      genReqId: (req, res) => {
        const incoming = req.headers['x-request-id']
        const id = typeof incoming === 'string' && /^[\w-]{1,64}$/.test(incoming) ? incoming : newId()
        res.setHeader('X-Request-Id', id)
        return id
      },
      autoLogging: { ignore: (req) => req.url?.startsWith('/health') ?? false },
      customLogLevel: (_req, res, err) => (err || res.statusCode >= 500 ? 'error' : 'info'),
    }),
  )
  app.use(helmet())
  app.use(
    cors({
      origin: ctx.config.CORS_ORIGINS,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
      allowedHeaders: ['Authorization', 'Content-Type', 'X-Device-Id', 'X-Request-Id'],
      exposedHeaders: ['X-Request-Id', 'Retry-After'],
      maxAge: 600,
    }),
  )
  app.use(express.json({ limit: '1mb' }))

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' })
  })
  app.get('/health/ready', async (_req, res) => {
    try {
      await ctx.db.$queryRaw`SELECT 1`
      res.json({ status: 'ok', database: 'ok' })
    } catch {
      res.status(503).json({ status: 'unavailable', database: 'unreachable' })
    }
  })

  // Coarse per-IP throttle in front of the unauthenticated auth endpoints;
  // the per-account limits live in the database (shared by all instances).
  if (ctx.config.NODE_ENV !== 'test') {
    app.use(
      `${API_PREFIX}/auth`,
      rateLimit({ windowMs: 15 * 60_000, limit: 300, standardHeaders: 'draft-8', legacyHeaders: false }),
    )
  }

  const api = new Api(ctx)
  registerRoutes(api)
  app.use(API_PREFIX, api.router)

  if (ctx.config.apiDocsEnabled) {
    const document = new OpenApiGeneratorV31(api.registry.definitions).generateDocument({
      openapi: '3.1.0',
      info: {
        title: 'JCB Work Management API',
        version: '1.0.0',
        description: 'REST API for the JCB Works mobile app and developer admin portal. See docs/migration/api-contract.md.',
      },
      servers: [{ url: API_PREFIX }],
    })
    app.get('/api/docs/openapi.json', (_req, res) => {
      res.json(document)
    })
    app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(document))
  }

  app.use(notFoundHandler)
  app.use(errorHandler)
  return { app, api }
}
