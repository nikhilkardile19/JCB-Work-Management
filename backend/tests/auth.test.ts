import { describe, expect, it } from 'vitest'
import { hashCode } from '../src/modules/licenses/activationCodes.js'
import { freshCode } from '../src/modules/licenses/licenseRules.js'
import { createUser, DAY, PASSWORD, seedCompany } from './helpers/factories.js'
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

describe('sign-up', () => {
  const COMPANY = { name: 'Sai Earthmovers', contactPerson: 'Ravi Patil', phone: '9876543210', address: 'Plot 4, MIDC Bhosari, Pune', invoicePrefix: 'SAI' }
  const signUp = (o: object = {}) =>
    env.request.post('/api/v1/auth/signup').send({ email: 'Ravi@Sai.example', password: 'strong-pass-1', company: COMPANY, ...o })

  it('creates the account and a pending company owned by it, without signing in', async () => {
    const res = await signUp()
    expect(res.status).toBe(201)
    expect(Object.keys(res.body).sort()).toEqual(['companyId', 'userId'])
    const { userId, companyId } = res.body
    expect(await env.db.user.findUniqueOrThrow({ where: { id: userId } })).toMatchObject({ email: 'ravi@sai.example', status: 'active' })
    expect(await env.db.company.findUniqueOrThrow({ where: { id: companyId } })).toMatchObject({
      name: 'Sai Earthmovers',
      status: 'pending',
      ownerUserId: userId,
      email: null,
    })
    expect(await env.db.refreshToken.count()).toBe(0)
    expect(await env.db.auditEvent.findFirstOrThrow({ where: { type: 'user.signup' } })).toMatchObject({ actorId: userId, companyId })

    // Signing in later shows the company awaiting approval.
    const { accessToken } = (await login('ravi@sai.example', 'strong-pass-1')).body
    const memberships = await env.request.get('/api/v1/me/memberships').set('Authorization', `Bearer ${accessToken}`)
    expect(memberships.body.items).toEqual([expect.objectContaining({ role: 'owner', company: expect.objectContaining({ id: companyId, status: 'pending' }) })])
  })

  it('refuses an email that already has an account (any case, with or without a password)', async () => {
    await signUp()
    const again = await signUp({ email: 'RAVI@sai.example' })
    expect(again.status).toBe(409)
    expect(again.body.error).toMatchObject({ code: 'already_exists', reason: 'email_taken' })
    await createUser(env.db, 'invited', { email: 'invited@example.test', password: false })
    expect((await signUp({ email: 'invited@example.test' })).body.error.reason).toBe('email_taken')
    expect(await env.db.company.count()).toBe(1)
  })

  it('needs no password: the owner signs in later with the activation code', async () => {
    const { password: _, ...withoutPassword } = { email: 'new@sai.example', password: '', company: COMPANY }
    const res = await env.request.post('/api/v1/auth/signup').send(withoutPassword)
    expect(res.status).toBe(201)
    expect(await env.db.user.findUniqueOrThrow({ where: { id: res.body.userId } })).toMatchObject({
      passwordHash: null,
      passwordChangedAt: null,
    })
  })

  it('validates the account and company details', async () => {
    const res = await signUp({ email: 'nope', password: 'short', company: { ...COMPANY, phone: '12', invoicePrefix: 'bad prefix' } })
    expect(res.status).toBe(400)
    expect(Object.keys(res.body.error.fields)).toEqual(expect.arrayContaining(['email', 'password', 'company.phone', 'company.invoicePrefix']))
    expect(await env.db.user.count()).toBe(0)
  })

  it('limits sign-ups per client', async () => {
    await createUser(env.db, 'u1')
    for (let i = 0; i < 20; i++) expect((await signUp({ email: 'u1@example.test' })).status).toBe(409)
    const res = await signUp({ email: 'new@example.test' })
    expect(res.status).toBe(429)
    expect(res.body.error.reason).toBe('rate_limited')
  })
})

describe('mobile sign-in with an activation code', () => {
  const CODE = 'JCBW-AAAA-BBBB-CCCC'
  const check = (email: string) => env.request.post('/api/v1/auth/check-email').send({ email })
  const codeLogin = (email: string, activationCode = CODE, deviceId = 'phone-1') =>
    env.request.post('/api/v1/auth/login-with-code').send({ email, activationCode, deviceId, deviceModel: 'Pixel 8' })
  const sessions = () => env.db.refreshToken.count()
  const seed = (o: Parameters<typeof seedCompany>[1] = {}) =>
    seedCompany(env.db, { members: { owner: 'owner', op: 'operator' }, devices: false, maxDevices: 2, activationCode: CODE, ...o })

  describe('check-email', () => {
    it('accepts an email with an account, in any case', async () => {
      await createUser(env.db, 'u1', { password: false })
      const res = await check('U1@Example.test')
      expect(res.status).toBe(204)
    })

    it('says when there is no account, or it is disabled', async () => {
      const none = await check('nobody@example.test')
      expect(none.status).toBe(404)
      expect(none.body.error).toMatchObject({ code: 'not_found', reason: 'no_account' })
      await createUser(env.db, 'u1', { disabled: true })
      const off = await check('u1@example.test')
      expect(off.status).toBe(403)
      expect(off.body.error.reason).toBe('user_disabled')
    })

    it('is limited per client', async () => {
      for (let i = 0; i < 30; i++) expect((await check('nobody@example.test')).status).toBe(404)
      expect((await check('nobody@example.test')).status).toBe(429)
    })
  })

  describe('login-with-code', () => {
    it('signs in without a password, activates the phone and names the company', async () => {
      await seed()
      await env.db.user.update({ where: { id: 'owner' }, data: { passwordHash: null } })
      const res = await codeLogin('Owner@example.test', 'jcbw aaaa bbbb cccc')
      expect(res.status).toBe(200)
      expect(res.body).toMatchObject({
        user: { id: 'owner', email: 'owner@example.test' },
        refreshTokenExpiresAt: null,
        companyId: 'co',
        license: { licenseId: 'lic-co', licenseStatus: 'active', deviceStatus: 'active', maxDevices: 2 },
        activation: null,
      })
      expect(res.body.accessToken).toMatch(/^ey/)
      expect(await env.db.device.findUniqueOrThrow({ where: { companyId_id: { companyId: 'co', id: 'phone-1' } } })).toMatchObject({
        userId: 'owner',
        status: 'active',
      })
      expect(await env.db.license.findUniqueOrThrow({ where: { id: 'lic-co' } })).toMatchObject({
        activationCodeUsedBy: 'owner',
        activationCodeDeviceId: 'phone-1',
      })
      const me = await env.request.get('/api/v1/auth/me').set('Authorization', `Bearer ${res.body.accessToken}`)
      expect(me.body.id).toBe('owner')
    })

    it('a used code signs in again only for the same user on the same phone', async () => {
      await seed()
      expect((await codeLogin('owner@example.test')).status).toBe(200)
      // Signed out and back in on the same phone.
      expect((await codeLogin('owner@example.test')).status).toBe(200)
      const before = await sessions()
      for (const [email, phone] of [['owner@example.test', 'phone-2'], ['op@example.test', 'phone-1']]) {
        const res = await codeLogin(email, CODE, phone)
        expect(res.status).toBe(409)
        expect(res.body.error).toMatchObject({ code: 'failed_precondition', reason: 'code_used' })
      }
      expect(await sessions()).toBe(before)
    })

    it('gives one answer for a wrong code, an unknown email, or another company’s code', async () => {
      await seed()
      await seedCompany(env.db, { id: 'other', members: { stranger: 'owner' }, devices: false, activationCode: 'JCBW-ZZZZ-YYYY-XXXX' })
      const wrong = await codeLogin('owner@example.test', 'JCBW-WRNG-WRNG-WRNG')
      const unknown = await codeLogin('nobody@example.test')
      const foreign = await codeLogin('owner@example.test', 'JCBW-ZZZZ-YYYY-XXXX')
      for (const res of [wrong, unknown, foreign]) {
        expect(res.status).toBe(401)
        expect(res.body).toEqual(wrong.body)
      }
      expect(wrong.body.error).toMatchObject({ code: 'unauthenticated', reason: 'invalid_code' })
      expect(await sessions()).toBe(0)
      expect(await env.db.device.count()).toBe(0)
    })

    it('locks an email after 10 wrong codes', async () => {
      await seed()
      for (let i = 0; i < 10; i++) expect((await codeLogin('owner@example.test', 'JCBW-WRNG-WRNG-WRNG')).status).toBe(401)
      const res = await codeLogin('owner@example.test')
      expect(res.status).toBe(429)
      expect(res.body.error.reason).toBe('rate_limited')
    })

    it('refuses disabled accounts and inactive licenses without starting a session', async () => {
      await seed({ licenseStatus: 'suspended' })
      const suspended = await codeLogin('owner@example.test')
      expect(suspended.status).toBe(409)
      expect(suspended.body.error.reason).toBe('suspended')
      await env.db.user.update({ where: { id: 'owner' }, data: { status: 'disabled' } })
      const disabled = await codeLogin('owner@example.test')
      expect(disabled.status).toBe(403)
      expect(disabled.body.error.reason).toBe('user_disabled')
      expect(await sessions()).toBe(0)
    })

    it('signs in when all devices are in use, so the phone can ask for a replacement', async () => {
      await seed({ maxDevices: 1 })
      expect((await codeLogin('op@example.test', CODE, 'phone-op')).status).toBe(200)
      await env.db.license.update({ where: { id: 'lic-co' }, data: freshCode(hashCode(CODE)) })
      const res = await codeLogin('owner@example.test')
      expect(res.status).toBe(200)
      expect(res.body).toMatchObject({ companyId: 'co', license: null, activation: { reason: 'device_limit' } })
      expect(res.body.refreshToken).toBeDefined()
      // The code is still unused, for the replacement request.
      expect((await env.db.license.findUniqueOrThrow({ where: { id: 'lic-co' } })).activationCodeUsedAt).toBeNull()
    })
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

  it('mobile sessions never expire; portal sessions end 12 hours after sign-in', async () => {
    await createUser(env.db, 'u1')
    const mobile = (await login('u1@example.test')).body
    expect(mobile.refreshTokenExpiresAt).toBeNull()
    // A phone left offline for years is still signed in when it comes back.
    env.clock.advance(5 * 365 * DAY)
    const back = await refresh(mobile.refreshToken)
    expect(back.status).toBe(200)
    expect(back.body.refreshTokenExpiresAt).toBeNull()
    expect(await env.db.refreshToken.count({ where: { client: 'mobile', expiresAt: { not: null } } })).toBe(0)
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
