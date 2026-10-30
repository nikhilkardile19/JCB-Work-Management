/**
 * Error codes and HTTP statuses of the API (docs/migration/api-contract.md).
 * The codes are those the Cloud Functions used, so clients map them the same
 * way they did before.
 */
export type ErrorCode =
  | 'invalid_argument'
  | 'unauthenticated'
  | 'permission_denied'
  | 'not_found'
  | 'already_exists'
  | 'failed_precondition'
  | 'conflict'
  | 'resource_exhausted'
  | 'internal'

const STATUS: Record<ErrorCode, number> = {
  invalid_argument: 400,
  unauthenticated: 401,
  permission_denied: 403,
  not_found: 404,
  already_exists: 409,
  failed_precondition: 409,
  conflict: 409,
  resource_exhausted: 429,
  internal: 500,
}

export interface ErrorExtra {
  /** Stable machine-readable reason the client may branch on. */
  reason?: string
  fields?: Record<string, string>
  retryAfterMs?: number
  /** Extra top-level body fields (sync conflicts). */
  body?: Record<string, unknown>
  /** Overrides the default status for the code. */
  status?: number
}

export class ApiError extends Error {
  readonly status: number

  constructor(
    readonly code: ErrorCode,
    message: string,
    readonly extra: ErrorExtra = {},
  ) {
    super(message)
    this.status = extra.status ?? STATUS[code]
  }

  toBody() {
    const { reason, fields, retryAfterMs, body } = this.extra
    return {
      error: {
        code: this.code,
        message: this.message,
        ...(reason ? { reason } : {}),
        ...(fields ? { fields } : {}),
        ...(retryAfterMs !== undefined ? { retryAfterMs } : {}),
      },
      ...body,
    }
  }
}

export const invalid = (message: string, fields?: Record<string, string>) =>
  new ApiError('invalid_argument', message, { fields })
export const unauthenticated = (message = 'Sign in first.', reason?: string) =>
  new ApiError('unauthenticated', message, { reason })
export const denied = (message: string, reason?: string) => new ApiError('permission_denied', message, { reason })
export const notFound = (what: string) => new ApiError('not_found', `${what} not found.`)
export const precondition = (message: string, reason?: string) =>
  new ApiError('failed_precondition', message, { reason })
export const alreadyExists = (message: string) => new ApiError('already_exists', message)
