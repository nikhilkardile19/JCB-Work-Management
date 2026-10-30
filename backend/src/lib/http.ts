import { OpenAPIRegistry } from '@asteasolutions/zod-to-openapi'
import { Router, type Request, type Response } from 'express'
import type { ZodType } from 'zod'
import type { AppContext } from '../context.js'
import { authenticate, type AuthUser } from '../modules/auth/tokens.js'
import { parse, z } from './validation.js'

type Method = 'get' | 'post' | 'put' | 'patch' | 'delete'

export interface RouteSpec<B, Q, P> {
  method: Method
  /** Express path relative to `/api/v1`, e.g. `/companies/:companyId`. */
  path: string
  tag: string
  summary: string
  description?: string
  /** `none` for public endpoints; default requires a signed-in user. */
  auth?: 'none' | 'user'
  body?: ZodType<B>
  query?: ZodType<Q>
  params?: ZodType<P>
  /** Documented success body. */
  response?: ZodType
  /** Success status (default 200, or 204 when the handler returns nothing). */
  status?: number
  /** Error statuses worth documenting besides 400/401/500. */
  errors?: number[]
}

export interface HandlerArgs<B, Q, P> {
  body: B
  query: Q
  params: P
  req: Request
  res: Response
  /** The signed-in user (routes with `auth: 'none'` get a placeholder). */
  user: AuthUser
}

/** Explicit status and body, for handlers whose status depends on the outcome. */
export class Reply {
  constructor(
    readonly status: number,
    readonly body?: unknown,
  ) {}
}

const ERROR_TEXT: Record<number, string> = {
  400: 'Validation failed (`invalid_argument`)',
  401: 'Not signed in or session expired (`unauthenticated`)',
  403: 'Not allowed (`permission_denied`)',
  404: 'Not found (`not_found`)',
  409: 'State conflict (`already_exists`, `failed_precondition`, `conflict`)',
  429: 'Rate limited (`resource_exhausted`)',
  500: 'Unexpected error (`internal`)',
}

export const ErrorBody = z
  .object({
    error: z.object({
      code: z.string(),
      message: z.string(),
      reason: z.string().optional(),
      fields: z.record(z.string(), z.string()).optional(),
      retryAfterMs: z.number().optional(),
    }),
  })
  .openapi('Error')

const NO_USER: AuthUser = { id: '', email: '' }

/** Router + OpenAPI registry: one declaration validates, documents and serves a route. */
export class Api {
  readonly router = Router()
  readonly registry = new OpenAPIRegistry()

  constructor(readonly ctx: AppContext) {
    this.registry.registerComponent('securitySchemes', 'bearerAuth', {
      type: 'http',
      scheme: 'bearer',
      bearerFormat: 'JWT',
    })
  }

  route<B = undefined, Q = undefined, P = undefined>(
    spec: RouteSpec<B, Q, P>,
    handler: (args: HandlerArgs<B, Q, P>) => Promise<unknown> | unknown,
  ) {
    const secured = spec.auth !== 'none'
    this.document(spec, secured)
    this.router[spec.method](spec.path, async (req: Request, res: Response) => {
      const user = secured ? await authenticate(this.ctx, req.headers.authorization) : NO_USER
      const params = (spec.params ? parse(spec.params, req.params, 'path') : req.params) as P
      const query = (spec.query ? parse(spec.query, req.query, 'query') : undefined) as Q
      const body = (spec.body ? parse(spec.body, req.body ?? {}, 'body') : undefined) as B
      const result = await handler({ body, query, params, req, res, user })
      if (res.headersSent) return
      if (result instanceof Reply) {
        if (result.body === undefined) res.status(result.status).end()
        else res.status(result.status).json(result.body)
      } else if (result === undefined) {
        res.status(204).end()
      } else {
        res.status(spec.status ?? 200).json(result)
      }
    })
  }

  private document(spec: RouteSpec<unknown, unknown, unknown>, secured: boolean) {
    const errorStatuses = new Set([400, 500, ...(secured ? [401] : []), ...(spec.errors ?? [])])
    const responses: Record<number, { description: string; content?: object }> = {}
    const ok = spec.status ?? (spec.response ? 200 : 204)
    responses[ok] = spec.response
      ? { description: 'Success', content: { 'application/json': { schema: spec.response } } }
      : { description: 'Success (no content)' }
    for (const s of errorStatuses) {
      responses[s] = { description: ERROR_TEXT[s] ?? 'Error', content: { 'application/json': { schema: ErrorBody } } }
    }
    this.registry.registerPath({
      method: spec.method,
      path: spec.path.replace(/:(\w+)/g, '{$1}'),
      tags: [spec.tag],
      summary: spec.summary,
      description: spec.description,
      security: secured ? [{ bearerAuth: [] }] : [],
      request: {
        params: spec.params as never,
        query: spec.query as never,
        body: spec.body ? { content: { 'application/json': { schema: spec.body } } } : undefined,
      },
      responses,
    })
  }
}
