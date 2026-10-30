import { beforeEach, describe, expect, it } from 'vitest'
import { generateActivationCode, hashCode, normalizeCode } from '../src/modules/licenses/activationCodes.js'
import { apiAs, createAdmin } from './helpers/api.js'
import { createUser, DAY, seedCompany } from './helpers/factories.js'
import { useTestApp } from './helpers/testApp.js'

/** Port of functions/test/licenses.test.ts, replacements.test.ts and abuse.test.ts (licensing part). */
const env = useTestApp()
const as = apiAs(env)
const CODE = 'JCBW-AAAA-BBBB-CCCC'

const activate = (uid: string, deviceId: string, code = CODE, company = 'co') =>
  as(uid, 'post', `/companies/${company}/license/activate`, { activationCode: code, deviceId, deviceModel: 'Pixel 8' })
const validate = (uid: string, deviceId: string, company = 'co') => as(uid, 'post', `/companies/${company}/license/validate`, { deviceId })
const devices = () => env.db.device.count({ where: { companyId: 'co', status: 'active' } })

beforeEach(async () => {
  await seedCompany(env.db, { maxDevices: 2, devices: false, activationCode: CODE })
})

describe('activation codes', () => {
  it('are random, readable, and normalized for lookup', () => {
    const code = generateActivationCode()
    expect(code).toMatch(/^JCBW-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$/)
    expect(generateActivationCode()).not.toBe(code)
    expect(normalizeCode(' jcbw-abcd efgh-ijkl ')).toBe('ABCDEFGHIJKL')
    expect(hashCode('abcd-efgh-ijkl')).toBe(hashCode('JCBW-ABCD-EFGH-IJKL'))
  })
})

describe('activate', () => {
  it('activates a device with a valid code and is idempotent for that device', async () => {
    const res = await activate('op', 'phone-1', 'jcbw aaaa bbbb cccc')
    expect(res.status).toBe(200)
    expect(res.body).toMatchObject({ licenseId: 'lic-co', licenseStatus: 'active', deviceStatus: 'active', maxDevices: 2 })
    expect((await activate('op', 'phone-1')).status).toBe(200)
    expect(await devices()).toBe(1)
    const types = (await env.db.auditEvent.findMany({ orderBy: { at: 'asc' } })).map((e) => e.type)
    expect(types).toEqual(['device.activate', 'device.revalidate'])
  })

  it('enforces the device limit on the server', async () => {
    await activate('op', 'phone-1')
    await activate('op2', 'phone-2')
    const res = await activate('mgr', 'phone-3')
    expect(res.status).toBe(409)
    expect(res.body.error).toMatchObject({ code: 'failed_precondition', reason: 'device_limit' })
  })

  it('concurrent activations never exceed the limit', async () => {
    const results = await Promise.all(['a', 'b', 'c', 'd', 'e'].map((d) => activate('op', `phone-${d}`)))
    expect(results.filter((r) => r.status === 200)).toHaveLength(2)
    expect(await devices()).toBe(2)
  })

  it('denies wrong codes, codes of another company, and non-members', async () => {
    await seedCompany(env.db, { id: 'co-b', members: { bob: 'owner' }, devices: false, activationCode: 'JCBW-ZZZZ-YYYY-XXXX' })
    expect((await activate('op', 'phone-1', 'JCBW-WRON-GCOD-E222')).body.error.reason).toBe('invalid_code')
    expect((await activate('op', 'phone-1', 'JCBW-ZZZZ-YYYY-XXXX')).body.error.reason).toBe('invalid_code')
    const outsider = await activate('bob', 'phone-9')
    expect(outsider.status).toBe(403)
    expect(outsider.body.error.reason).toBe('not_member')
  })

  it('denies inactive companies', async () => {
    await env.db.company.update({ where: { id: 'co' }, data: { status: 'pending' } })
    const res = await activate('op', 'phone-1')
    expect(res.status).toBe(409)
    expect(res.body.error.reason).toBe('company_inactive')
  })

  it('denies suspended, revoked, expired and not-yet-started licenses', async () => {
    const lic = (data: object) => env.db.license.update({ where: { id: 'lic-co' }, data })
    await lic({ status: 'suspended' })
    expect((await activate('op', 'p1')).body.error.reason).toBe('suspended')
    await lic({ status: 'revoked' })
    expect((await activate('op', 'p1')).body.error.reason).toBe('revoked')
    await lic({ status: 'active', validFrom: new Date(Date.now() + DAY), validUntil: new Date(Date.now() + 2 * DAY) })
    expect((await activate('op', 'p1')).body.error.reason).toBe('not_started')
    await lic({ validFrom: new Date(Date.now() - 2 * DAY), validUntil: new Date(Date.now() - DAY) })
    expect((await activate('op', 'p1')).body.error.reason).toBe('expired')
    // The lapse is recorded even though the activation was refused.
    expect((await env.db.license.findUniqueOrThrow({ where: { id: 'lic-co' } })).status).toBe('expired')
  })

  it('a revoked device cannot re-activate itself', async () => {
    await activate('op', 'phone-1')
    await env.db.device.update({ where: { companyId_id: { companyId: 'co', id: 'phone-1' } }, data: { status: 'revoked' } })
    expect((await activate('op', 'phone-1')).body.error.reason).toBe('device_revoked')
  })
})

describe('validate', () => {
  it('reports active state and refreshes lastSeen', async () => {
    await activate('op', 'phone-1')
    await env.db.device.update({ where: { companyId_id: { companyId: 'co', id: 'phone-1' } }, data: { lastSeenAt: new Date(0) } })
    const res = await validate('op', 'phone-1')
    expect(res.body).toMatchObject({ licenseStatus: 'active', deviceStatus: 'active' })
    const d = await env.db.device.findUniqueOrThrow({ where: { companyId_id: { companyId: 'co', id: 'phone-1' } } })
    expect(d.lastSeenAt!.getTime()).toBeGreaterThan(0)
  })

  it('reports unknown devices, revoked devices and expiry without throwing', async () => {
    expect((await validate('op', 'never-seen')).body).toMatchObject({ licenseStatus: 'none', deviceStatus: 'unknown' })
    await activate('op', 'phone-1')
    // Another user's phone looks unknown.
    expect((await validate('op2', 'phone-1')).body.deviceStatus).toBe('unknown')
    await env.db.device.update({ where: { companyId_id: { companyId: 'co', id: 'phone-1' } }, data: { status: 'revoked' } })
    expect((await validate('op', 'phone-1')).body.deviceStatus).toBe('revoked')
    await env.db.license.update({ where: { id: 'lic-co' }, data: { validUntil: new Date(Date.now() - 1000) } })
    const res = await validate('op', 'phone-1')
    expect(res.status).toBe(200)
    expect(res.body.licenseStatus).toBe('expired')
    expect((await env.db.license.findUniqueOrThrow({ where: { id: 'lic-co' } })).status).toBe('expired')
  })

  it('non-members are refused', async () => {
    await createUser(env.db, 'stranger')
    expect((await validate('stranger', 'phone-1')).status).toBe(403)
  })
})

describe('activation code guessing', () => {
  it('locks a user out after 10 wrong codes, even with the right code', async () => {
    for (let i = 0; i < 10; i++) expect((await activate('op', 'p1', 'JCBW-XXXX-XXXX-XXXX')).status).toBe(409)
    const res = await activate('op', 'p1')
    expect(res.status).toBe(429)
    expect(res.body.error.reason).toBe('rate_limited')
    // Other users are unaffected.
    expect((await activate('op2', 'p2')).status).toBe(200)
  })

  it('successful activations and other refusals do not count', async () => {
    for (let i = 0; i < 12; i++) await activate('op', 'p1')
    await env.db.license.update({ where: { id: 'lic-co' }, data: { status: 'suspended' } })
    for (let i = 0; i < 12; i++) expect((await activate('op', 'p1')).body.error.reason).toBe('suspended')
  })

  it('wrong codes on replacement requests count towards the same limit', async () => {
    for (let i = 0; i < 10; i++) {
      await as('op', 'post', '/companies/co/device-replacements', { activationCode: 'JCBW-XXXX-XXXX-XXXX', newDeviceId: 'p1', reason: 'Lost phone' })
    }
    expect((await activate('op', 'p1')).status).toBe(429)
  })

  it('activation codes have a sane length', async () => {
    expect((await activate('op', 'p1', 'X'.repeat(41))).status).toBe(400)
  })
})

describe('device replacement', () => {
  const request = (uid: string, newDeviceId: string, o: object = {}) =>
    as(uid, 'post', '/companies/co/device-replacements', { activationCode: CODE, newDeviceId, newDeviceModel: 'Galaxy', reason: 'Old phone broke', ...o })
  const review = (uid: string, requestId: string, o: object) =>
    as(uid, 'post', `/admin/companies/co/replacement-requests/${requestId}/review`, { reason: 'Verified by phone', ...o })

  beforeEach(async () => {
    await createAdmin(env, 'dev-super')
    await activate('op', 'old-1')
    await activate('op2', 'old-2')
  })

  it('the full license refuses activation; the new phone files a request instead', async () => {
    expect((await activate('op', 'new-1')).body.error.reason).toBe('device_limit')
    const res = await request('op', 'new-1')
    expect(res.body).toMatchObject({ status: 'pending' })
    expect(res.body.requestId).toBeTruthy()
  })

  it('is idempotent per new phone and needs the activation code and a reason', async () => {
    const first = await request('op', 'new-1')
    expect((await request('op', 'new-1')).body.requestId).toBe(first.body.requestId)
    expect((await request('op', 'new-2', { activationCode: 'JCBW-XXXX-XXXX-XXXX' })).body.error.reason).toBe('invalid_code')
    expect((await request('op', 'new-2', { reason: 'x' })).status).toBe(400)
  })

  it('an already-active phone needs nothing; a revoked phone must reinstall', async () => {
    expect((await request('op', 'old-1')).body).toEqual({ requestId: null, status: 'already_active' })
    await env.db.device.update({ where: { companyId_id: { companyId: 'co', id: 'old-2' } }, data: { status: 'revoked' } })
    expect((await request('op2', 'old-2')).body.error.reason).toBe('device_revoked')
  })

  it('approve swaps phones atomically; the limit is never exceeded', async () => {
    const { requestId } = (await request('op', 'new-1')).body
    expect((await review('dev-super', requestId, { decision: 'approve' })).body.error.reason).toBe('device_limit')
    const res = await review('dev-super', requestId, { decision: 'approve', revokeDeviceId: 'old-1' })
    expect(res.body).toEqual({ status: 'approved', revokedDeviceId: 'old-1' })
    expect(await devices()).toBe(2)
    const neu = await env.db.device.findUniqueOrThrow({ where: { companyId_id: { companyId: 'co', id: 'new-1' } } })
    expect(neu).toMatchObject({ status: 'active', userId: 'op', replacementForDeviceId: 'old-1' })
    expect((await validate('op', 'old-1')).body.deviceStatus).toBe('revoked')
    // The requester sees the outcome.
    expect((await as('op', 'get', `/companies/co/device-replacements/${requestId}`)).body).toMatchObject({ status: 'approved', reviewReason: 'Verified by phone' })
    expect((await review('dev-super', requestId, { decision: 'reject' })).status).toBe(409)
  })

  it('a free slot allows approval without revoking anything', async () => {
    await env.db.license.update({ where: { id: 'lic-co' }, data: { maxDevices: 3 } })
    await env.db.deviceReplacementRequest.create({
      data: { id: 'r1', companyId: 'co', licenseId: 'lic-co', newDeviceId: 'new-1', requestedBy: 'op', reason: 'x', status: 'pending' },
    })
    expect((await review('dev-super', 'r1', { decision: 'approve' })).body).toEqual({ status: 'approved', revokedDeviceId: null })
    expect(await devices()).toBe(3)
  })

  it('reject keeps the new phone inactive and records the reason', async () => {
    const { requestId } = (await request('op', 'new-1')).body
    expect((await review('dev-super', requestId, { decision: 'reject', reason: 'Unknown caller' })).body.status).toBe('rejected')
    expect(await env.db.device.findUnique({ where: { companyId_id: { companyId: 'co', id: 'new-1' } } })).toBeNull()
    expect((await as('op', 'get', `/companies/co/device-replacements/${requestId}`)).body.reviewReason).toBe('Unknown caller')
  })

  it('two approvals racing for the last slot cannot both win', async () => {
    await env.db.license.update({ where: { id: 'lic-co' }, data: { maxDevices: 3 } })
    const a = (await request('op', 'new-a')).body.requestId
    const b = (await request('op2', 'new-b')).body.requestId
    const results = await Promise.all([review('dev-super', a, { decision: 'approve' }), review('dev-super', b, { decision: 'approve' })])
    expect(results.map((r) => r.status).sort()).toEqual([200, 409])
    expect(await devices()).toBe(3)
  })

  it('only admins with devices.revoke can review; reasons are required; inactive licenses refuse', async () => {
    await createAdmin(env, 'dev-support', 'support', ['licenses.manage'])
    const { requestId } = (await request('op', 'new-1')).body
    expect((await review('dev-support', requestId, { decision: 'reject' })).status).toBe(403)
    expect((await review('owner', requestId, { decision: 'reject' })).status).toBe(403)
    expect((await review('dev-super', requestId, { decision: 'reject', reason: '' })).status).toBe(400)
    await env.db.license.update({ where: { id: 'lic-co' }, data: { status: 'suspended' } })
    expect((await review('dev-super', requestId, { decision: 'approve', revokeDeviceId: 'old-1' })).status).toBe(409)
  })

  it('the requester and owner/admins can read a request; other members cannot', async () => {
    const { requestId } = (await request('op', 'new-1')).body
    expect((await as('op', 'get', `/companies/co/device-replacements/${requestId}`)).status).toBe(200)
    expect((await as('owner', 'get', `/companies/co/device-replacements/${requestId}`)).status).toBe(200)
    expect((await as('op2', 'get', `/companies/co/device-replacements/${requestId}`)).status).toBe(403)
    expect((await as('mgr', 'get', `/companies/co/device-replacements/${requestId}`)).status).toBe(403)
  })

  it('limits new requests per user per day; repeating a pending one is free', async () => {
    for (let i = 0; i < 5; i++) {
      const r = await request('op', `n-${i}`)
      expect(r.status).toBe(200)
      await env.db.deviceReplacementRequest.update({ where: { id: r.body.requestId }, data: { status: 'rejected' } })
    }
    expect((await request('op', 'n-9')).status).toBe(429)
  })
})
