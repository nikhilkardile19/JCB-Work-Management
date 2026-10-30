import { beforeEach, describe, expect, it } from 'vitest'
import { apiAs } from './helpers/api.js'
import { createUser, PROFILE, seedCompany } from './helpers/factories.js'
import { useTestApp } from './helpers/testApp.js'

/**
 * Company onboarding (ADR 0002), company users (port of the Functions'
 * users tests and abuse limits) and invoice numbering (port of
 * invoiceNumbers.test.ts).
 */
const env = useTestApp()
const as = apiAs(env)

describe('registration and memberships', () => {
  beforeEach(async () => {
    await createUser(env.db, 'newbie')
  })

  it('registers a pending company owned by the caller, idempotently', async () => {
    const res = await as('newbie', 'post', '/companies', { id: 'co-new', ...PROFILE })
    expect(res.status).toBe(201)
    expect(res.body).toMatchObject({ id: 'co-new', status: 'pending', ownerUid: 'newbie', currency: 'INR' })
    expect((await as('newbie', 'post', '/companies', { id: 'co-new', ...PROFILE })).status).toBe(200)
    const m = await as('newbie', 'get', '/me/memberships')
    expect(m.body.items).toEqual([expect.objectContaining({ role: 'owner', status: 'active', company: expect.objectContaining({ id: 'co-new' }) })])
  })

  it("can't take over someone else's company ID", async () => {
    await seedCompany(env.db)
    const res = await as('newbie', 'post', '/companies', { id: 'co', ...PROFILE })
    expect(res.status).toBe(409)
    expect((await env.db.companyMember.findMany({ where: { userId: 'newbie' } })).length).toBe(0)
  })

  it('validates the profile like the app does', async () => {
    const res = await as('newbie', 'post', '/companies', { id: 'x', ...PROFILE, invoicePrefix: 'bad prefix', gstin: '123', phone: '12' })
    expect(res.status).toBe(400)
    expect(Object.keys(res.body.error.fields)).toEqual(expect.arrayContaining(['invoicePrefix', 'gstin', 'phone']))
    // Empty optional fields are stored as null.
    const ok = await as('newbie', 'post', '/companies', { id: 'y', ...PROFILE, email: '', gstin: '' })
    expect(ok.body).toMatchObject({ email: null, gstin: null })
  })

  it('lists only active memberships; disabled members see nothing', async () => {
    await seedCompany(env.db)
    expect((await as('op', 'get', '/me/memberships')).body.items).toHaveLength(1)
    await env.db.companyMember.update({ where: { companyId_userId: { companyId: 'co', userId: 'op' } }, data: { status: 'disabled' } })
    expect((await as('op', 'get', '/me/memberships')).body.items).toHaveLength(0)
  })

  it('owners/admins edit the profile, never status or owner; others cannot', async () => {
    await seedCompany(env.db)
    const res = await as('admin', 'patch', '/companies/co', { ...PROFILE, name: 'Sai Earthmovers Pvt Ltd' })
    expect(res.status).toBe(200)
    expect(res.body.name).toBe('Sai Earthmovers Pvt Ltd')
    expect((await as('admin', 'patch', '/companies/co', { ...PROFILE, status: 'active' })).body.status).toBe('active')
    expect((await env.db.company.findUniqueOrThrow({ where: { id: 'co' } })).status).toBe('active')
    await env.db.company.update({ where: { id: 'co' }, data: { status: 'pending' } })
    await as('owner', 'patch', '/companies/co', { ...PROFILE, status: 'active', ownerUserId: 'mgr' })
    expect(await env.db.company.findUniqueOrThrow({ where: { id: 'co' } })).toMatchObject({ status: 'pending', ownerUserId: 'owner' })
    expect((await as('mgr', 'patch', '/companies/co', PROFILE)).status).toBe(403)
  })
})

describe('company users', () => {
  beforeEach(async () => {
    await seedCompany(env.db)
  })
  const members = async () => (await as('owner', 'get', '/companies/co/members')).body.items as { uid: string; role: string; status: string }[]

  it('owner invites, changes roles and disables; actions are audited', async () => {
    const inv = await as('owner', 'post', '/companies/co/members', { email: 'New.Person@Example.test', role: 'operator' })
    expect(inv.body.newUser).toBe(true)
    const uid = inv.body.userId
    expect((await members()).find((m) => m.uid === uid)).toMatchObject({ role: 'operator', status: 'active' })
    expect((await as('owner', 'patch', `/companies/co/members/${uid}`, { role: 'admin' })).body).toEqual({ role: 'admin' })
    expect((await as('owner', 'patch', `/companies/co/members/${uid}`, { status: 'disabled' })).body).toEqual({ status: 'disabled' })
    const types = (await env.db.auditEvent.findMany({ orderBy: { at: 'asc' } })).map((e) => e.type)
    expect(types).toEqual(['user.invite', 'user.role', 'user.status'])
    // The invited account has no password until they reset it.
    expect((await env.db.user.findUniqueOrThrow({ where: { id: uid } })).passwordHash).toBeNull()
    expect((await as('owner', 'post', '/companies/co/members', { email: 'new.person@example.test', role: 'manager' })).body.newUser).toBe(false)
  })

  it('admins manage staff but not admins or the owner; nobody changes themselves', async () => {
    expect((await as('admin', 'patch', '/companies/co/members/op', { role: 'manager' })).status).toBe(200)
    expect((await as('admin', 'patch', '/companies/co/members/op', { role: 'admin' })).status).toBe(403)
    expect((await as('admin', 'post', '/companies/co/members', { email: 'x@example.test', role: 'admin' })).status).toBe(403)
    expect((await as('admin', 'patch', '/companies/co/members/owner', { status: 'disabled' })).status).toBe(409)
    expect((await as('admin', 'patch', '/companies/co/members/admin', { status: 'disabled' })).status).toBe(409)
    expect((await as('owner', 'patch', '/companies/co/members/owner', { role: 'admin' })).status).toBe(409)
    expect((await as('owner', 'patch', '/companies/co/members/op', { role: 'owner' })).status).toBe(400)
    expect((await as('owner', 'patch', '/companies/co/members/op', { role: 'manager', status: 'active' })).status).toBe(400)
  })

  it('managers, operators and outsiders cannot manage users', async () => {
    await seedCompany(env.db, { id: 'co-b', members: { bob: 'owner' } })
    for (const uid of ['mgr', 'op', 'acc', 'bob']) {
      expect((await as(uid, 'post', '/companies/co/members', { email: 'y@example.test', role: 'operator' })).status).toBe(403)
    }
    expect((await as('bob', 'get', '/companies/co/members')).status).toBe(403)
    // Every member may see the team list.
    expect((await as('op', 'get', '/companies/co/members')).status).toBe(200)
  })

  it('an admin cannot re-enable an admin the owner disabled', async () => {
    await as('owner', 'patch', '/companies/co/members/admin', { status: 'disabled' })
    await createUser(env.db, 'admin2')
    await env.db.companyMember.create({ data: { companyId: 'co', userId: 'admin2', role: 'admin', status: 'active' } })
    const res = await as('admin2', 'post', '/companies/co/members', { email: 'admin@example.test', role: 'manager' })
    expect(res.status).toBe(403)
  })

  it('already-active members cannot be invited twice', async () => {
    expect((await as('owner', 'post', '/companies/co/members', { email: 'op@example.test', role: 'manager' })).status).toBe(409)
  })

  it('limits users added per company per day, and rejects oversized emails', async () => {
    for (let i = 0; i < 30; i++) expect((await as('owner', 'post', '/companies/co/members', { email: `p${i}@example.test`, role: 'operator' })).status).toBe(200)
    expect((await as('owner', 'post', '/companies/co/members', { email: 'p31@example.test', role: 'operator' })).status).toBe(429)
    expect((await as('owner', 'post', '/companies/co/members', { email: `${'a'.repeat(200)}@example.test`, role: 'operator' })).status).toBe(400)
  })
})

describe('invoice numbers', () => {
  beforeEach(async () => {
    await seedCompany(env.db)
  })
  const allocate = (uid: string, invoiceId: string, o: { fy?: string; company?: string; device?: string } = {}) =>
    as(uid, 'post', `/companies/${o.company ?? 'co'}/invoice-numbers`, { invoiceId, financialYear: o.fy ?? '2026-27' }, { 'X-Device-Id': o.device ?? `dev-${uid}` })

  it('issues sequential numbers per company and financial year with the company prefix', async () => {
    expect((await allocate('acc', 'i1')).body.invoiceNumber).toBe('SAI/2026-27/0001')
    expect((await allocate('acc', 'i2')).body.invoiceNumber).toBe('SAI/2026-27/0002')
    expect((await allocate('acc', 'i3', { fy: '2027-28' })).body.invoiceNumber).toBe('SAI/2027-28/0001')
  })

  it('is idempotent per invoice (safe to retry)', async () => {
    const a = await allocate('acc', 'i1')
    const b = await allocate('owner', 'i1')
    expect(b.body.invoiceNumber).toBe(a.body.invoiceNumber)
    expect((await allocate('acc', 'i2')).body.invoiceNumber).toBe('SAI/2026-27/0002')
  })

  it('never issues duplicates or gaps under concurrent requests, including retries', async () => {
    const ids = Array.from({ length: 12 }, (_, i) => `i${i % 8}`)
    const results = await Promise.all(ids.map((id, i) => allocate(i % 2 ? 'acc' : 'owner', id)))
    expect(results.every((r) => r.status === 200)).toBe(true)
    const byInvoice = new Map(results.map((r, i) => [ids[i], r.body.invoiceNumber]))
    results.forEach((r, i) => expect(r.body.invoiceNumber).toBe(byInvoice.get(ids[i])))
    expect([...new Set(byInvoice.values())].sort()).toEqual(Array.from({ length: 8 }, (_, i) => `SAI/2026-27/000${i + 1}`))
  })

  it('companies have independent sequences', async () => {
    await seedCompany(env.db, { id: 'co-b', members: { bob: 'owner' } })
    await allocate('acc', 'i1')
    expect((await allocate('bob', 'x1', { company: 'co-b' })).body.invoiceNumber).toBe('SAI/2026-27/0001')
  })

  it('rejects unauthenticated callers, non-members, wrong roles and disabled members', async () => {
    expect((await env.request.post('/api/v1/companies/co/invoice-numbers').send({ invoiceId: 'i1', financialYear: '2026-27' })).status).toBe(401)
    for (const uid of ['mgr', 'op']) expect((await allocate(uid, 'i1')).status).toBe(403)
    await seedCompany(env.db, { id: 'co-b', members: { bob: 'owner' } })
    expect((await allocate('bob', 'i1')).status).toBe(403)
    await env.db.companyMember.update({ where: { companyId_userId: { companyId: 'co', userId: 'acc' } }, data: { status: 'disabled' } })
    expect((await allocate('acc', 'i1')).status).toBe(403)
  })

  it('requires an active company', async () => {
    await env.db.company.update({ where: { id: 'co' }, data: { status: 'suspended' } })
    expect((await allocate('acc', 'i1')).status).toBe(409)
  })

  it('only an activated phone on an active license can take numbers', async () => {
    expect((await allocate('acc', 'i1', { device: 'dev-owner' })).body.error.reason).toBe('license')
    expect((await allocate('acc', 'i1', { device: 'unknown' })).status).toBe(409)
    await env.db.license.update({ where: { id: 'lic-co' }, data: { status: 'suspended' } })
    expect((await allocate('acc', 'i1')).status).toBe(409)
    expect(await env.db.issuedInvoiceNumber.count()).toBe(0)
  })

  it('validates input', async () => {
    expect((await allocate('acc', 'i1', { fy: '2026-28' })).status).toBe(400)
    expect((await allocate('acc', 'i/1')).status).toBe(400)
  })
})
