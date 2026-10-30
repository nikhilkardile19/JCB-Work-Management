import { describe, expect, it } from 'vitest'
import { createUser, DAY, PASSWORD } from './helpers/factories.js'
import { useTestApp } from './helpers/testApp.js'

const env = useTestApp()
const login = (email: string, password = PASSWORD, client = 'mobile') =>
  env.request.post('/api/v1/auth/login').send({ email, password, client })

describe('login', () => {
  it('returns a session and never exposes the password hash', async () => {
    await createUser(env.db, 'u1', { email: 'Ravi@Example.test'.toLowerCase() })
    const res = await login('RAVI@example.test')
    expect(res.status).toBe(200)
    expect(res.body).toMatchObject({ user: { id: 'u1', email: 'ravi@example.test' } })
    expect(res.body.accessToken).toMatch(/^ey/)
    expect(res.body.refreshToken.length).toBeGreaterThan(30)
    expect(JSON.stringify(res.body)).not.toMatch(/argon2/)
    const stored = await env.db.refreshToken.findFirstOrThrow()
    expect(stored.tokenHash).not.toBe(res.body.refreshToken)
  })

  it('gives the same answer for a wrong password and an unknown email', async () => {
    await createUser(env.db, 'u1')
    const wrong = await login('u1@example.test', 'wrong-password')
    const unknown = await login('nobody@example.test')
    expect(wrong.status).toBe(401)
    expect(unknown.status).toBe(401)
    expect(wrong.body).toEqual(unknown.body)
    expect(wrong.body.error).toMatchObject({ code: 'unauthenticated', reason: 'invalid_credentials' })
  })

  it('refuses accounts without a password (invited, not yet set)', async () => {
    await createUser(env.db, 'u1', { password: false })
    expect((await login('u1@example.test')).body.error.reason).toBe('invalid_credentials')
  })

  it('refuses disabled accounts after checking the password', async () => {
    await createUser(env.db, 'u1', { disabled: true })
    const res = await login('u1@example.test')
    expect(res.status).toBe(403)
    expect(res.body.error.reason).toBe('user_disabled')
  })

  it('locks an email after 10 wrong passwords', async () => {
    await createUser(env.db, 'u1')
    for (let i = 0; i < 10; i++) expect((await login('u1@example.test', 'nope')).status).toBe(401)
    const res = await login('u1@example.test')
    expect(res.status).toBe(429)
    expect(res.body.error).toMatchObject({ code: 'resource_exhausted', reason: 'rate_limited' })
    expect(res.headers['retry-after']).toBeDefined()
  })

  it('validates the body', async () => {
    const res = await env.request.post('/api/v1/auth/login').send({ email: 'not-an-email', password: 'x', client: 'tv' })
    expect(res.status).toBe(400)
    expect(Object.keys(res.body.error.fields)).toEqual(expect.arrayContaining(['email', 'client']))
  })
})

describe('access tokens', () => {
  it('protect endpoints and identify the user', async () => {
    await createUser(env.db, 'u1')
    expect((await env.request.get('/api/v1/auth/me')).status).toBe(401)
    const { accessToken } = (await login('u1@example.test')).body
    const me = await env.request.get('/api/v1/auth/me').set('Authorization', `Bearer ${accessToken}`)
    expect(me.body).toEqual({ id: 'u1', email: 'u1@example.test', developerAdmin: null })
  })

  it('expire', async () => {
    await createUser(env.db, 'u1')
    const { accessToken } = (await login('u1@example.test')).body
    env.clock.advance(16 * 60_000)
    const res = await env.request.get('/api/v1/auth/me').set('Authorization', `Bearer ${accessToken}`)
    expect(res.status).toBe(401)
    expect(res.body.error.reason).toBe('token_expired')
  })

  it('are rejected when tampered with or signed with another key', async () => {
    await createUser(env.db, 'u1')
    const { accessToken } = (await login('u1@example.test')).body
    const [h, p] = accessToken.split('.')
    const forged = `${h}.${p}.${'A'.repeat(43)}`
    expect((await env.request.get('/api/v1/auth/me').set('Authorization', `Bearer ${forged}`)).status).toBe(401)
  })

  it('die when the account is disabled', async () => {
    await createUser(env.db, 'u1')
    const { accessToken } = (await login('u1@example.test')).body
    await env.db.user.update({ where: { id: 'u1' }, data: { status: 'disabled' } })
    expect((await env.request.get('/api/v1/auth/me').set('Authorization', `Bearer ${accessToken}`)).status).toBe(401)
  })
})

describe('refresh rotation', () => {
  const refresh = (refreshToken: string) => env.request.post('/api/v1/auth/refresh').send({ refreshToken })

  it('issues a new pair and retires the old refresh token', async () => {
    await createUser(env.db, 'u1')
    const first = (await login('u1@example.test')).body
    const second = await refresh(first.refreshToken)
    expect(second.status).toBe(200)
    expect(second.body.refreshToken).not.toBe(first.refreshToken)
    expect((await refresh(second.body.refreshToken)).status).toBe(200)
  })

  it('revokes the whole session when a rotated token is reused', async () => {
    await createUser(env.db, 'u1')
    const first = (await login('u1@example.test')).body
    const second = (await refresh(first.refreshToken)).body
    await refresh(second.refreshToken) // successor used → grace no longer applies
    const reuse = await refresh(first.refreshToken)
    expect(reuse.status).toBe(401)
    expect(reuse.body.error.reason).toBe('invalid_refresh_token')
    const live = await env.db.refreshToken.count({ where: { revokedAt: null } })
    expect(live).toBe(0)
    expect(await env.db.auditEvent.count({ where: { type: 'auth.refresh_reuse' } })).toBe(1)
  })

  it('lets a phone retry after a lost response (grace window, successor unused)', async () => {
    await createUser(env.db, 'u1')
    const first = (await login('u1@example.test')).body
    const lost = (await refresh(first.refreshToken)).body
    const retry = await refresh(first.refreshToken)
    expect(retry.status).toBe(200)
    // The response that never arrived is no longer valid…
    expect((await refresh(lost.refreshToken)).status).toBe(401)
    // …and presenting it again counts as a fork, ending the session.
    expect((await refresh(retry.body.refreshToken)).status).toBe(401)
  })

  it('does not apply the grace window after it has passed', async () => {
    await createUser(env.db, 'u1')
    const first = (await login('u1@example.test')).body
    await refresh(first.refreshToken)
    env.clock.advance(2 * 60_000)
    expect((await refresh(first.refreshToken)).status).toBe(401)
  })

  it('mobile sessions slide; portal sessions end 12 hours after sign-in', async () => {
    await createUser(env.db, 'u1')
    const mobile = (await login('u1@example.test')).body
    expect(mobile.refreshTokenExpiresAt - Date.now()).toBeGreaterThan(59 * DAY)
    const portal = (await login('u1@example.test', PASSWORD, 'portal')).body
    env.clock.advance(11 * 3_600_000)
    const later = (await refresh(portal.refreshToken)).body
    expect(later.refreshTokenExpiresAt).toBe(portal.refreshTokenExpiresAt)
    env.clock.advance(2 * 3_600_000)
    expect((await refresh(later.refreshToken)).status).toBe(401)
  })

  it('logout ends the session', async () => {
    await createUser(env.db, 'u1')
    const s = (await login('u1@example.test')).body
    expect((await env.request.post('/api/v1/auth/logout').send({ refreshToken: s.refreshToken })).status).toBe(204)
    expect((await refresh(s.refreshToken)).status).toBe(401)
  })
})

describe('password reset', () => {
  const tokenFromMail = () => {
    const text = env.mailer.sent.at(-1)!.text
    return new URL(/https:\S+/.exec(text)![0]).searchParams.get('token')!
  }

  it('never reveals whether an account exists', async () => {
    await createUser(env.db, 'u1')
    const known = await env.request.post('/api/v1/auth/forgot-password').send({ email: 'u1@example.test' })
    const unknown = await env.request.post('/api/v1/auth/forgot-password').send({ email: 'x@example.test' })
    expect(known.status).toBe(204)
    expect(unknown.status).toBe(204)
    expect(env.mailer.sent).toHaveLength(1)
  })

  it('sets the password once, signs out everywhere, and kills old access tokens', async () => {
    await createUser(env.db, 'u1', { password: false })
    await createUser(env.db, 'u2')
    const other = (await login('u2@example.test')).body
    await env.request.post('/api/v1/auth/forgot-password').send({ email: 'u1@example.test' })
    const token = tokenFromMail()
    const set = await env.request.post('/api/v1/auth/reset-password').send({ token, password: 'new password 1' })
    expect(set.status).toBe(204)
    expect((await login('u1@example.test', 'new password 1')).status).toBe(200)
    const again = await env.request.post('/api/v1/auth/reset-password').send({ token, password: 'another one 2' })
    expect(again.status).toBe(400)
    expect(again.body.error.reason).toBe('invalid_reset_token')
    // Unrelated users keep their sessions.
    expect((await env.request.post('/api/v1/auth/refresh').send({ refreshToken: other.refreshToken })).status).toBe(200)
  })

  it('revokes existing sessions of that user', async () => {
    await createUser(env.db, 'u1')
    const s = (await login('u1@example.test')).body
    await env.request.post('/api/v1/auth/forgot-password').send({ email: 'u1@example.test' })
    await env.request.post('/api/v1/auth/reset-password').send({ token: tokenFromMail(), password: 'new password 1' })
    expect((await env.request.get('/api/v1/auth/me').set('Authorization', `Bearer ${s.accessToken}`)).status).toBe(401)
    expect((await env.request.post('/api/v1/auth/refresh').send({ refreshToken: s.refreshToken })).status).toBe(401)
  })

  it('links expire and only the newest one works', async () => {
    await createUser(env.db, 'u1')
    await env.request.post('/api/v1/auth/forgot-password').send({ email: 'u1@example.test' })
    const older = tokenFromMail()
    await env.request.post('/api/v1/auth/forgot-password').send({ email: 'u1@example.test' })
    const newer = tokenFromMail()
    expect((await env.request.post('/api/v1/auth/reset-password').send({ token: older, password: 'new password 1' })).status).toBe(400)
    env.clock.advance(61 * 60_000)
    expect((await env.request.post('/api/v1/auth/reset-password').send({ token: newer, password: 'new password 1' })).status).toBe(400)
  })

  it('limits reset requests per client, whatever the address', async () => {
    for (let i = 0; i < 20; i++) {
      expect((await env.request.post('/api/v1/auth/forgot-password').send({ email: `x${i}@example.test` })).status).toBe(204)
    }
    expect((await env.request.post('/api/v1/auth/forgot-password').send({ email: 'y@example.test' })).status).toBe(429)
  })

  it('requires at least 8 characters', async () => {
    const res = await env.request.post('/api/v1/auth/reset-password').send({ token: 'x'.repeat(40), password: 'short' })
    expect(res.status).toBe(400)
    expect(res.body.error.fields.password).toMatch(/8 characters/)
  })
})

describe('platform', () => {
  it('health checks', async () => {
    expect((await env.request.get('/health')).body).toEqual({ status: 'ok' })
    expect((await env.request.get('/health/ready')).body).toEqual({ status: 'ok', database: 'ok' })
  })

  it('unknown routes and bad JSON get the error envelope', async () => {
    expect((await env.request.get('/api/v1/nope')).body.error.code).toBe('not_found')
    const bad = await env.request.post('/api/v1/auth/login').set('Content-Type', 'application/json').send('{"email":')
    expect(bad.status).toBe(400)
    expect(bad.body.error.code).toBe('invalid_argument')
  })

  it('CORS only for configured origins', async () => {
    const ok = await env.request.options('/api/v1/auth/login').set('Origin', 'https://admin.example.test').set('Access-Control-Request-Method', 'POST')
    expect(ok.headers['access-control-allow-origin']).toBe('https://admin.example.test')
    const evil = await env.request.options('/api/v1/auth/login').set('Origin', 'https://evil.example').set('Access-Control-Request-Method', 'POST')
    expect(evil.headers['access-control-allow-origin']).toBeUndefined()
  })

  it('serves the OpenAPI document', async () => {
    const doc = (await env.request.get('/api/docs/openapi.json')).body
    expect(doc.openapi).toBe('3.1.0')
    expect(doc.paths['/auth/login'].post).toBeDefined()
  })
})
