import type { Request } from 'express'
import type { Api } from '../../lib/http.js'
import { emailSchema, z } from '../../lib/validation.js'
import { CompanyProfileInput } from '../companies/companyProfile.js'
import { currentUser, forgotPassword, login, resetPassword, signUp } from './authService.js'
import { MAX_PASSWORD_LENGTH, MIN_PASSWORD_LENGTH } from './passwords.js'
import { endSession, refreshSession, type ClientMeta } from './sessions.js'

const Session = z
  .object({
    accessToken: z.string(),
    accessTokenExpiresAt: z.number().int().openapi({ description: 'Epoch ms' }),
    refreshToken: z.string(),
    refreshTokenExpiresAt: z.number().int().nullable().openapi({ description: 'Epoch ms; null for mobile sessions, which never expire' }),
    user: z.object({ id: z.string(), email: z.string() }),
  })
  .openapi('Session')

const NewPassword = z
  .string()
  .min(MIN_PASSWORD_LENGTH, `Use at least ${MIN_PASSWORD_LENGTH} characters.`)
  .max(MAX_PASSWORD_LENGTH)

const Me = z
  .object({
    id: z.string(),
    email: z.string(),
    developerAdmin: z
      .object({ role: z.enum(['super', 'support']), permissions: z.array(z.string()) })
      .nullable(),
  })
  .openapi('CurrentUser')

const RefreshBody = z.object({ refreshToken: z.string().min(16).max(200) })

const meta = (req: Request): ClientMeta => ({ ip: req.ip, userAgent: req.get('user-agent') })

export function registerAuthRoutes(api: Api) {
  const { ctx } = api

  api.route(
    {
      method: 'post',
      path: '/auth/signup',
      tag: 'Auth',
      summary: 'Create an account and its company (pending approval); does not sign in',
      description:
        'The company starts `pending` with the new user as owner. When a developer admin approves it, the activation code is emailed to this address. ' +
        'An email that already has an account gets `409 already_exists` with `reason: "email_taken"`.',
      auth: 'none',
      body: z.object({ email: emailSchema, password: NewPassword, company: CompanyProfileInput }),
      response: z.object({ userId: z.string(), companyId: z.string() }),
      status: 201,
      errors: [409, 429],
    },
    ({ body, req }) => signUp(ctx, body, meta(req)),
  )

  api.route(
    {
      method: 'post',
      path: '/auth/login',
      tag: 'Auth',
      summary: 'Sign in with email and password',
      auth: 'none',
      body: z.object({
        email: emailSchema,
        password: z.string().min(1).max(MAX_PASSWORD_LENGTH),
        client: z.enum(['mobile', 'portal']),
      }),
      response: Session,
      errors: [403, 429],
    },
    ({ body, req }) => login(ctx, body, meta(req)),
  )

  api.route(
    {
      method: 'post',
      path: '/auth/refresh',
      tag: 'Auth',
      summary: 'Exchange a refresh token for a new token pair (rotation)',
      auth: 'none',
      body: RefreshBody,
      response: Session,
    },
    ({ body, req }) => refreshSession(ctx, body.refreshToken, meta(req)),
  )

  api.route(
    {
      method: 'post',
      path: '/auth/logout',
      tag: 'Auth',
      summary: 'End the session this refresh token belongs to',
      auth: 'none',
      body: RefreshBody,
    },
    async ({ body }) => {
      await endSession(ctx, body.refreshToken)
    },
  )

  api.route(
    { method: 'get', path: '/auth/me', tag: 'Auth', summary: 'The signed-in user', response: Me },
    ({ user }) => currentUser(ctx, user.id),
  )

  api.route(
    {
      method: 'post',
      path: '/auth/forgot-password',
      tag: 'Auth',
      summary: 'Email a password reset link (always 204)',
      auth: 'none',
      body: z.object({ email: emailSchema }),
      errors: [429],
    },
    async ({ body, req }) => {
      await forgotPassword(ctx, body.email, req.ip)
    },
  )

  api.route(
    {
      method: 'post',
      path: '/auth/reset-password',
      tag: 'Auth',
      summary: 'Set a new password from a reset link; signs out every session',
      auth: 'none',
      body: z.object({ token: z.string().min(16).max(200), password: NewPassword }),
    },
    async ({ body }) => {
      await resetPassword(ctx, body.token, body.password)
    },
  )
}
