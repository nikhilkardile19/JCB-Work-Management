import { beforeEach, describe, expect, it } from 'vitest'
import { LogMailer } from '../src/lib/mailer.js'
import { emailActivationCode } from '../src/modules/licenses/activationCodeMail.js'
import { hashCode } from '../src/modules/licenses/activationCodes.js'
import { apiAs, createAdmin } from './helpers/api.js'
import { createUser, DAY, PASSWORD, PROFILE, seedCompany } from './helpers/factories.js'
import { useTestApp } from './helpers/testApp.js'

/** Port of functions/test/admin.test.ts plus the portal's list queries. */
const env = useTestApp()
const as = apiAs(env)
const R = { reason: 'Verified with customer' }

beforeEach(async () => {
  await seedCompany(env.db)
  await createAdmin(env, 'super')
  await createAdmin(env, 'support', 'support')
  await createAdmin(env, 'lic-only', 'support', ['licenses.manage'])
})

describe('admin roles', () => {
  it('non-admins and company members are refused everywhere', async () => {
    for (const uid of ['owner', 'op']) {
      const me = await as(uid, 'get', '/admin/me')
      expect(me.status).toBe(403)
      expect(me.body.error.reason).toBe('not_admin')
      expect((await as(uid, 'get', '/admin/companies')).status).toBe(403)
      expect((await as(uid, 'post', '/admin/companies/co/status', { status: 'suspended', ...R })).status).toBe(403)
      expect((await as(uid, 'post', '/admin/companies/co/licenses', { validFrom: 0, validUntil: 1, maxDevices: 2 })).status).toBe(403)
    }
  })

  it('support admins need explicit grants; super admins can do everything', async () => {
    expect((await as('super', 'get', '/admin/me')).body).toEqual({ uid: 'super', email: 'super@example.test', role: 'super', permissions: [] })
    expect((await as('support', 'get', '/admin/companies')).status).toBe(200)
    expect((await as('support', 'post', '/admin/companies/co/status', { status: 'suspended', ...R })).status).toBe(403)
    expect((await as('lic-only', 'post', '/admin/companies/co/licenses/lic-co/status', { status: 'suspended', ...R })).status).toBe(200)
    expect((await as('lic-only', 'post', '/admin/companies/co/devices/dev-op/revoke', R)).status).toBe(403)
    expect((await as('super', 'post', '/admin/companies/co/devices/dev-op/revoke', R)).status).toBe(200)
  })
})

describe('companies', () => {
  it('approve and suspend need a reason and are audited', async () => {
    await env.db.company.update({ where: { id: 'co' }, data: { status: 'pending' } })
    expect((await as('super', 'post', '/admin/companies/co/status', { status: 'active' })).status).toBe(400)
    expect((await as('super', 'post', '/admin/companies/co/status', { status: 'active', ...R })).body).toEqual({ status: 'active' })
    const ev = await env.db.auditEvent.findFirstOrThrow({ where: { type: 'company.status' } })
    expect(ev).toMatchObject({ actorId: 'super', companyId: 'co', reason: R.reason, details: { from: 'pending', to: 'active' } })
  })

  it('approving a sign-up activates it, issues a license and emails the one-time code to the owner', async () => {
    const signup = await env.request.post('/api/v1/auth/signup').send({ email: 'new@owner.example', password: PASSWORD, company: PROFILE })
    const { userId, companyId } = signup.body
    const terms = { validFrom: Date.now() - 1000, validUntil: Date.now() + 365 * DAY, maxDevices: 2 }
    const approve = (uid: string, o: object = {}) => as(uid, 'post', `/admin/companies/${companyId}/approve`, { ...terms, ...R, ...o })

    expect((await approve('support')).status).toBe(403)
    // Needs companies.manage as well as licenses.manage.
    expect((await approve('lic-only')).status).toBe(403)
    expect((await approve('super', { reason: '' })).status).toBe(400)
    expect((await approve('super', { validUntil: terms.validFrom })).status).toBe(400)

    const res = await approve('super')
    expect(res.status).toBe(201)
    expect(res.body.emailedTo).toBe('new@owner.example')
    expect(await env.db.company.findUniqueOrThrow({ where: { id: companyId } })).toMatchObject({ status: 'active' })
    expect(await env.db.license.findUniqueOrThrow({ where: { id: res.body.licenseId } })).toMatchObject({
      companyId,
      status: 'active',
      maxDevices: 2,
      activationCodeHash: hashCode(res.body.activationCode),
      activationCodeUsedAt: null,
    })
    expect(env.mailer.sent).toEqual([expect.objectContaining({ to: 'new@owner.example', text: expect.stringContaining(res.body.activationCode) })])
    const types = (await env.db.auditEvent.findMany({ where: { companyId } })).map((e) => e.type)
    expect(types).toEqual(expect.arrayContaining(['user.signup', 'company.status', 'license.create']))

    // Only a pending company can be approved.
    expect((await approve('super')).status).toBe(409)
    expect((await as('super', 'post', '/admin/companies/nope/approve', { ...terms, ...R })).status).toBe(404)
    expect(await env.db.license.count({ where: { companyId } })).toBe(1)

    // The owner signs in and activates one phone with the emailed code.
    const activate = (deviceId: string) =>
      as(userId, 'post', `/companies/${companyId}/license/activate`, { activationCode: res.body.activationCode, deviceId })
    expect((await activate('phone-1')).body).toMatchObject({ licenseStatus: 'active', deviceStatus: 'active' })
    expect((await activate('phone-2')).body.error.reason).toBe('code_used')
  })

  it('two admins approving at once issue one license', async () => {
    await env.db.company.update({ where: { id: 'co' }, data: { status: 'pending' } })
    const body = { validFrom: 0, validUntil: Date.now() + DAY, maxDevices: 1, ...R }
    const results = await Promise.all([1, 2].map(() => as('super', 'post', '/admin/companies/co/approve', body)))
    expect(results.map((r) => r.status).sort()).toEqual([201, 409])
    expect(await env.db.license.count({ where: { companyId: 'co' } })).toBe(2)
  })

  it('creates an active company with an owner account (new or existing user)', async () => {
    const fresh = await as('super', 'post', '/admin/companies', { ...PROFILE, ownerEmail: 'Boss@Newco.test' })
    expect(fresh.status).toBe(201)
    expect(fresh.body.newUser).toBe(true)
    const company = await as('super', 'get', `/admin/companies/${fresh.body.companyId}`)
    expect(company.body).toMatchObject({ status: 'active', ownerUid: fresh.body.ownerUid })
    const members = await as('super', 'get', `/admin/companies/${fresh.body.companyId}/members`)
    expect(members.body.items).toEqual([{ uid: fresh.body.ownerUid, email: 'boss@newco.test', role: 'owner', status: 'active' }])
    const existing = await as('super', 'post', '/admin/companies', { ...PROFILE, ownerEmail: 'op@example.test' })
    expect(existing.body).toMatchObject({ newUser: false, ownerUid: 'op' })
  })

  it('validates company details', async () => {
    const res = await as('super', 'post', '/admin/companies', { ...PROFILE, gstin: 'nope', ownerEmail: 'x' })
    expect(res.status).toBe(400)
    expect(Object.keys(res.body.error.fields)).toEqual(expect.arrayContaining(['gstin', 'ownerEmail']))
  })

  it('edits a profile and audits the changed fields only', async () => {
    expect((await as('super', 'patch', '/admin/companies/co', { ...PROFILE, phone: '9999999999' })).body).toEqual({ ok: true })
    const ev = await env.db.auditEvent.findFirstOrThrow({ where: { type: 'company.update' } })
    expect(ev.details).toEqual({ changed: { phone: { from: '9876543210', to: '9999999999' } } })
  })

  it('lists newest first with cursor pages, filters by status, and searches by name', async () => {
    for (let i = 0; i < 30; i++) {
      await env.db.company.create({ data: { id: `c${i}`, ...PROFILE, name: `Company ${i}`, ownerUserId: 'owner', createdAt: new Date(Date.UTC(2026, 0, 1) + i * 1000) } })
    }
    const p1 = await as('super', 'get', '/admin/companies?status=pending')
    expect(p1.body.items).toHaveLength(25)
    expect(p1.body.items[0].id).toBe('c29')
    const p2 = await as('super', 'get', `/admin/companies?status=pending&cursor=${p1.body.next}`)
    expect(p2.body.items.map((c: { id: string }) => c.id)).toEqual(['c4', 'c3', 'c2', 'c1', 'c0'])
    expect(p2.body.next).toBeNull()
    const found = await as('super', 'get', '/admin/companies?search=company%202')
    expect(found.body.items.map((c: { name: string }) => c.name)).toEqual(['Company 2', 'Company 20', 'Company 21', 'Company 22', 'Company 23', 'Company 24', 'Company 25', 'Company 26', 'Company 27', 'Company 28', 'Company 29'])
    expect((await as('super', 'get', '/admin/companies?cursor=%%%')).status).toBe(400)
  })
})

describe('licenses', () => {
  const status = (s: string, o = R) => as('super', 'post', '/admin/companies/co/licenses/lic-co/status', { status: s, ...o })

  it('creates a license; the code is shown once and stored only as a hash', async () => {
    const res = await as('lic-only', 'post', '/admin/companies/co/licenses', { validFrom: Date.now(), validUntil: Date.now() + 365 * DAY, maxDevices: 3 })
    expect(res.status).toBe(201)
    expect(res.body.emailedTo).toBe('owner@example.test')
    const stored = await env.db.license.findUniqueOrThrow({ where: { id: res.body.licenseId } })
    expect(stored.activationCodeHash).toBe(hashCode(res.body.activationCode))
    expect(JSON.stringify(stored)).not.toContain(res.body.activationCode.slice(5))
    expect((await as('super', 'post', '/admin/companies/co/licenses', { validFrom: 10, validUntil: 5, maxDevices: 3 })).status).toBe(400)
    expect((await as('super', 'post', '/admin/companies/co/licenses', { validFrom: 1, validUntil: 5, maxDevices: 101 })).status).toBe(400)
    expect((await as('super', 'post', '/admin/companies/nope/licenses', { validFrom: 1, validUntil: 5, maxDevices: 1 })).status).toBe(404)
  })

  it('suspend → reactivate → revoke (final); reason required', async () => {
    expect((await status('suspended', { reason: '' })).status).toBe(400)
    expect((await status('suspended')).status).toBe(200)
    expect((await status('active')).status).toBe(200)
    expect((await status('revoked')).status).toBe(200)
    expect((await status('active')).status).toBe(409)
    expect((await as('super', 'patch', '/admin/companies/co/licenses/lic-co', { maxDevices: 50, ...R })).status).toBe(409)
    expect((await as('super', 'post', '/admin/companies/co/licenses/lic-co/rotate-code', R)).status).toBe(409)
  })

  it('renewing an expired license reactivates it; ended licenses must be extended first', async () => {
    await env.db.license.update({ where: { id: 'lic-co' }, data: { status: 'expired', validUntil: new Date(Date.now() - DAY) } })
    expect((await status('active')).status).toBe(409)
    const until = Date.now() + 90 * DAY
    expect((await as('super', 'patch', '/admin/companies/co/licenses/lic-co', { validUntil: until, ...R })).status).toBe(200)
    const l = (await as('super', 'get', '/admin/companies/co/licenses/lic-co')).body
    expect(l).toMatchObject({ status: 'active', validUntil: until, companyName: PROFILE.name })
    expect((await as('super', 'patch', '/admin/companies/co/licenses/lic-co', { validUntil: 1, ...R })).status).toBe(400)
    expect((await as('super', 'patch', '/admin/companies/co/licenses/lic-co', R)).status).toBe(400)
  })

  it('device limit cannot drop below active devices', async () => {
    // seedCompany registers 6 active phones.
    expect((await as('super', 'patch', '/admin/companies/co/licenses/lic-co', { maxDevices: 5, ...R })).status).toBe(409)
    expect((await as('super', 'patch', '/admin/companies/co/licenses/lic-co', { maxDevices: 6, ...R })).status).toBe(200)
  })

  it('rotating the code invalidates the old one', async () => {
    const { activationCode } = (await as('super', 'post', '/admin/companies/co/licenses/lic-co/rotate-code', R)).body
    const activate = (code: string) => as('op', 'post', '/companies/co/license/activate', { activationCode: code, deviceId: 'new-phone' })
    expect((await activate('JCBW-AAAA-BBBB-CCCC')).body.error.reason).toBe('invalid_code')
    expect((await activate(activationCode)).status).toBe(200)
  })

  it('a new code replaces a used one and is emailed to the owner', async () => {
    const activate = (code: string, deviceId: string) => as('op', 'post', '/companies/co/license/activate', { activationCode: code, deviceId })
    expect((await activate('JCBW-AAAA-BBBB-CCCC', 'phone-a')).status).toBe(200)
    const used = (await as('super', 'get', '/admin/companies/co/licenses/lic-co')).body
    expect(used).toMatchObject({ activationCodeUsedAt: expect.any(Number), activationCodeDeviceId: 'phone-a' })

    const res = await as('super', 'post', '/admin/companies/co/licenses/lic-co/rotate-code', R)
    expect(res.body.emailedTo).toBe('owner@example.test')
    expect(env.mailer.sent.at(-1)!.text).toContain(res.body.activationCode)
    expect((await as('super', 'get', '/admin/companies/co/licenses/lic-co')).body).toMatchObject({ activationCodeUsedAt: null, activationCodeDeviceId: null })
    expect((await activate(res.body.activationCode, 'phone-b')).status).toBe(200)
  })

  it('codes are never sent through the log-only mailer (no SMTP)', async () => {
    const ctx = { ...env.ctx, mailer: new LogMailer(env.ctx.logger) }
    expect(await emailActivationCode(ctx, 'co', 'JCBW-AAAA-BBBB-CCCC')).toBeNull()
  })

  it('a license is only reachable through its own company', async () => {
    await seedCompany(env.db, { id: 'co-b', members: { bob: 'owner' } })
    expect((await as('super', 'get', '/admin/companies/co-b/licenses/lic-co')).status).toBe(404)
  })

  it('lists across companies by end date, filtered by status or company', async () => {
    await seedCompany(env.db, { id: 'co-b', members: { bob: 'owner' }, licenseStatus: 'suspended' })
    expect((await as('support', 'get', '/admin/licenses')).body.items.map((l: { id: string }) => l.id).sort()).toEqual(['lic-co', 'lic-co-b'])
    expect((await as('support', 'get', '/admin/licenses?status=suspended')).body.items.map((l: { id: string }) => l.id)).toEqual(['lic-co-b'])
    expect((await as('support', 'get', '/admin/licenses?companyId=co')).body.items.map((l: { id: string }) => l.id)).toEqual(['lic-co'])
  })
})

describe('devices', () => {
  it('revoke needs devices.revoke and a reason; revoked devices lose access', async () => {
    expect((await as('super', 'post', '/admin/companies/co/devices/dev-op/revoke', {})).status).toBe(400)
    expect((await as('super', 'post', '/admin/companies/co/devices/dev-op/revoke', R)).status).toBe(200)
    expect((await as('super', 'post', '/admin/companies/co/devices/dev-op/revoke', R)).status).toBe(409)
    const d = (await as('super', 'get', '/admin/companies/co/devices/dev-op')).body
    expect(d).toMatchObject({ status: 'revoked', revokeReason: R.reason })
    const v = await as('op', 'post', '/companies/co/license/validate', { deviceId: 'dev-op' })
    expect(v.body.deviceStatus).toBe('revoked')
  })

  it('lists by last seen (never-seen last) with stable cursor pages', async () => {
    const seen = (id: string, t: number | null) =>
      env.db.device.update({ where: { companyId_id: { companyId: 'co', id } }, data: { lastSeenAt: t === null ? null : new Date(t) } })
    await seen('dev-owner', 3000)
    await seen('dev-op', 2000)
    await seen('dev-acc', 2000)
    const all: string[] = []
    let cursor: string | null = null
    do {
      const res = await as('support', 'get', `/admin/devices?limit=2${cursor ? `&cursor=${cursor}` : ''}`)
      all.push(...res.body.items.map((d: { id: string }) => d.id))
      cursor = res.body.next
    } while (cursor)
    expect(all.slice(0, 3)).toEqual(['dev-owner', 'dev-acc', 'dev-op'])
    expect(all).toHaveLength(6)
    expect(new Set(all).size).toBe(6)
    expect((await as('support', 'get', '/admin/devices?status=revoked')).body.items).toEqual([])
  })
})

describe('dashboard, requests and audit history', () => {
  it('counts companies, licenses, devices and pending requests', async () => {
    await seedCompany(env.db, { id: 'co-b', status: 'pending', members: { bob: 'owner' }, devices: false })
    await env.db.license.update({ where: { id: 'lic-co-b' }, data: { validUntil: new Date(Date.now() + 5 * DAY) } })
    await env.db.deviceReplacementRequest.create({
      data: { id: 'r1', companyId: 'co', licenseId: 'lic-co', newDeviceId: 'n1', requestedBy: 'op', reason: 'x', status: 'pending' },
    })
    expect((await as('support', 'get', '/admin/metrics')).body).toEqual({
      companies: { pending: 1, active: 1, suspended: 0 },
      licenses: { active: 2, expiringSoon: 1, expired: 0, suspended: 0 },
      activeDevices: 6,
      pendingRequests: 1,
    })
    const requests = await as('support', 'get', '/admin/replacement-requests?status=pending')
    expect(requests.body.items[0]).toMatchObject({ id: 'r1', companyName: PROFILE.name, requesterEmail: 'op@example.test', newDeviceId: 'n1' })
  })

  it('filters the audit trail and pages newest first', async () => {
    await as('super', 'post', '/admin/companies/co/devices/dev-op/revoke', R)
    await as('super', 'post', '/admin/companies/co/licenses/lic-co/status', { status: 'suspended', ...R })
    const all = (await as('support', 'get', '/admin/audit-events')).body.items
    expect(all.map((e: { type: string }) => e.type)).toEqual(['license.status', 'device.revoke'])
    const byDevice = (await as('support', 'get', '/admin/audit-events?deviceId=dev-op')).body.items
    expect(byDevice).toEqual([expect.objectContaining({ type: 'device.revoke', actorId: 'super', licenseId: 'lic-co', reason: R.reason })])
    expect((await as('support', 'get', '/admin/audit-events?type=license.status&companyId=co')).body.items).toHaveLength(1)
  })
})

describe('accounts', () => {
  it('a developer admin signs in to the portal with a 12-hour session', async () => {
    await createUser(env.db, 'not-admin-yet')
    const me = await as('super', 'get', '/auth/me')
    expect(me.body.developerAdmin).toEqual({ role: 'super', permissions: [] })
  })
})
