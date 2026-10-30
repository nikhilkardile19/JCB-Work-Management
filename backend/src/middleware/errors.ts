import type { ErrorRequestHandler, RequestHandler } from 'express'
import { prismaCode } from '../database/prisma.js'
import { alreadyExists, ApiError, invalid, notFound } from '../lib/errors.js'

const REFUSALS = new Set(['unauthenticated', 'permission_denied', 'resource_exhausted'])

export const notFoundHandler: RequestHandler = (req, _res, next) => {
  next(new ApiError('not_found', `No route for ${req.method} ${req.path}.`))
}

/**
 * Turns every error into the JSON error envelope. Refusals are logged as
 * warnings (who, which route, why); unexpected errors are logged with their
 * stack, and the caller only ever sees a generic message.
 */
export const errorHandler: ErrorRequestHandler = (err, req, res, _next) => {
  let e: ApiError
  const type = (err as { type?: string })?.type
  if (err instanceof ApiError) e = err
  else if (type === 'entity.parse.failed') e = invalid('The request body is not valid JSON.')
  else if (type === 'entity.too.large') e = new ApiError('invalid_argument', 'The request is too large.', { status: 413 })
  else if (prismaCode(err) === 'P2002') e = alreadyExists('That record already exists.')
  else if (prismaCode(err) === 'P2003') e = invalid('This refers to a record that does not exist.')
  else if (prismaCode(err) === 'P2025') e = notFound('Record')
  else {
    req.log?.error({ err }, 'Request failed')
    e = new ApiError('internal', 'Something went wrong. Please try again.')
  }
  if (REFUSALS.has(e.code)) {
    req.log?.warn({ code: e.code, reason: e.extra.reason, message: e.message }, 'Request refused')
  }
  if (e.extra.retryAfterMs !== undefined) res.setHeader('Retry-After', Math.ceil(e.extra.retryAfterMs / 1000))
  res.status(e.status).json(e.toBody())
}
