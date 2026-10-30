import { afterEach, describe, expect, it, vi } from 'vitest'
import { adminProfile, apiError, BASE_URL, fakeFetch, json, offline, session, type Call } from '../test/fakeFetch'
import { ApiError, createApiClient, REFRESH_TOKEN_KEY, SESSION_EXPIRED_MESSAGE } from './apiClient'
import { createHttpAdminApi } from './httpAdminApi'
import { createHttpAuthService, messageForAuthError, NOT_ADMIN_MESSAGE } from './httpAuthService'

const stored = () => sessionStorage.getItem(REFRESH_TOKEN_KEY)
const route = (c: Call) => `${c.method} ${c.path}`
const fieldsOf = (e: unknown) => {
  expect(e).toBeInstanceOf(ApiError)
  const { status, code, reason, message, retryAfterMs } = e as ApiError
  return { status, code, reason, message, retryAfterMs }
}

afterEach(() => {
  sessionStorage.clear()
  vi.useRealTimers()
  vi.restoreAllMocks()
})

describe('api client', () => {
  it('turns error envelopes, bare gateway errors and network failures into ApiError', async () => {
    const f = fakeFetch((c) => {
      if (c.path === '/conflict') return apiError(409, 'failed_precondition', 'The license allows 2 phones.', { reason: 'device_limit' })
      if (c.path === '/limited') return apiError(429, 'resource_exhausted', 'Slow down.', { reason: 'rate_limited', retryAfterMs: 1500 })
      if (c.path === '/gateway') return new Response('<html>Bad gateway</html>', { status: 502 })
      return offline()
    })
    const client = createApiClient({ baseUrl: `${BASE_URL}/`, fetch: f.fn })
    const fail = (p: string) => client.request('GET', p, { auth: false }).catch((e: unknown) => e)

    expect(fieldsOf(await fail('/conflict'))).toEqual({
      status: 409,
      code: 'failed_precondition',
      reason: 'device_limit',
      message: 'The license allows 2 phones.',
      retryAfterMs: undefined,
    })
    expect(fieldsOf(await fail('/limited'))).toMatchObject({ status: 429, reason: 'rate_limited', retryAfterMs: 1500 })
    expect(fieldsOf(await fail('/gateway'))).toMatchObject({ status: 502, code: 'unavailable', message: expect.stringMatching(/unreachable/) })
    expect(fieldsOf(await fail('/down'))).toMatchObject({ status: 0, reason: 'network', message: expect.stringMatching(/^No internet connection/) })
    expect(f.calls.map((c) => c.path)).toEqual(['/conflict', '/limited', '/gateway', '/down'])
  })

  it('refreshes once for concurrent 401s, then retries each call with the new token', async () => {
    const f = fakeFetch(async (c) => {
      if (c.path === '/auth/refresh') {
        await new Promise((r) => setTimeout(r, 10))
        return json(200, session('A2', 'r2'))
      }
      return c.auth === 'Bearer A2' ? json(200, { path: c.path }) : apiError(401, 'unauthenticated', 'Token expired.')
    })
    const client = createApiClient({ baseUrl: BASE_URL, fetch: f.fn })
    client.setSession(session('A1', 'r1'))
    expect(stored()).toBe('r1')

    const results = await Promise.all(['/x', '/y', '/z'].map((p) => client.request<{ path: string }>('GET', p)))

    expect(results.map((r) => r.path)).toEqual(['/x', '/y', '/z'])
    expect(f.count('/auth/refresh')).toBe(1)
    expect(f.calls.find((c) => c.path === '/auth/refresh')).toMatchObject({ method: 'POST', body: { refreshToken: 'r1' }, auth: null })
    for (const p of ['/x', '/y', '/z']) expect(f.calls.filter((c) => c.path === p).map((c) => c.auth)).toEqual(['Bearer A1', 'Bearer A2'])
    expect(stored()).toBe('r2')
  })

  it('clears the session and tells the auth layer when the refresh is refused', async () => {
    const f = fakeFetch((c) =>
      c.path === '/auth/refresh'
        ? apiError(401, 'unauthenticated', 'Sign in again.', { reason: 'invalid_refresh_token' })
        : apiError(401, 'unauthenticated', 'Token expired.'),
    )
    const client = createApiClient({ baseUrl: BASE_URL, fetch: f.fn })
    const ended = vi.fn()
    client.onSessionEnd(ended)
    client.setSession(session('A1', 'r1'))

    const e = await client.request('GET', '/admin/metrics').catch((err: unknown) => err)

    expect(fieldsOf(e)).toMatchObject({ status: 401, message: SESSION_EXPIRED_MESSAGE })
    expect(ended).toHaveBeenCalledTimes(1)
    expect(client.hasSession()).toBe(false)
    expect(stored()).toBeNull()
    expect(f.calls.map(route)).toEqual(['GET /admin/metrics', 'POST /auth/refresh'])
  })

  it('refreshes shortly before the access token expires', async () => {
    vi.useFakeTimers()
    const f = fakeFetch(() => json(200, session('A2', 'r2')))
    const client = createApiClient({ baseUrl: BASE_URL, fetch: f.fn })
    client.setSession(session('A1', 'r1', 5 * 60_000))

    await vi.advanceTimersByTimeAsync(3 * 60_000)
    expect(f.calls).toHaveLength(0)
    await vi.advanceTimersByTimeAsync(60_000 + 1)
    expect(f.calls.map(route)).toEqual(['POST /auth/refresh'])
    expect(stored()).toBe('r2')
  })

  it('keeps working in memory when sessionStorage is blocked', async () => {
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new DOMException('blocked', 'SecurityError')
    })
    const f = fakeFetch(() => json(200, { ok: true }))
    const client = createApiClient({ baseUrl: BASE_URL, fetch: f.fn })
    client.setSession(session('A1', 'r1'))
    expect(client.hasSession()).toBe(true)
    expect(await client.request('GET', '/admin/metrics')).toEqual({ ok: true })
    expect(f.calls[0].auth).toBe('Bearer A1')
  })
})

describe('http auth service', () => {
  const service = (reply: (c: Call) => Response | Promise<Response>) => {
    const f = fakeFetch(reply)
    return { f, auth: createHttpAuthService(createApiClient({ baseUrl: BASE_URL, fetch: f.fn })) }
  }

  it('signs in as a portal client, then checks the admin allowlist', async () => {
    const { f, auth } = service((c) => (c.path === '/auth/login' ? json(200, session('A1', 'r1')) : json(200, adminProfile)))

    expect(await auth.signIn(' admin@jcbworks.in ', 'supersecret')).toEqual({ uid: 'admin', email: 'admin@jcbworks.in' })
    expect(f.calls.map(route)).toEqual(['POST /auth/login', 'GET /admin/me'])
    expect(f.calls[0]).toMatchObject({ body: { email: 'admin@jcbworks.in', password: 'supersecret', client: 'portal' }, auth: null })
    expect(f.calls[1].auth).toBe('Bearer A1')
    expect(stored()).toBe('r1')
  })

  it('signs non-admins straight back out', async () => {
    const { f, auth } = service((c) => {
      if (c.path === '/auth/login') return json(200, session('A1', 'r1'))
      if (c.path === '/admin/me') return apiError(403, 'permission_denied', 'Not a developer admin.')
      return json(204)
    })

    await expect(auth.signIn('owner@customer.in', 'supersecret')).rejects.toThrow(NOT_ADMIN_MESSAGE)
    expect(f.calls.at(-1)).toMatchObject({ method: 'POST', path: '/auth/logout', body: { refreshToken: 'r1' }, auth: 'Bearer A1' })
    expect(stored()).toBeNull()
  })

  it('maps login failures to the same messages as before', async () => {
    const cases: [() => Response | Promise<Response>, string][] = [
      [() => apiError(401, 'unauthenticated', 'Wrong password.', { reason: 'invalid_credentials' }), 'Incorrect email or password.'],
      [() => apiError(403, 'permission_denied', 'Disabled.', { reason: 'user_disabled' }), 'This account has been disabled.'],
      [() => apiError(429, 'resource_exhausted', 'Slow down.', { reason: 'rate_limited', retryAfterMs: 60_000 }), 'Too many attempts. Wait a few minutes and try again.'],
      [offline, 'No internet connection. Connect and try again.'],
      [() => apiError(500, 'internal', 'Internal error.'), 'Sign-in failed. Please try again.'],
    ]
    for (const [reply, message] of cases) {
      const { f, auth } = service(reply)
      await expect(auth.signIn('admin@jcbworks.in', 'supersecret')).rejects.toThrow(message)
      expect(f.calls.map(route)).toEqual(['POST /auth/login'])
    }
    expect(messageForAuthError('user_disabled')).toBe('This account has been disabled.')
  })

  it("restores this tab's session on startup", async () => {
    sessionStorage.setItem(REFRESH_TOKEN_KEY, 'r1')
    const { f, auth } = service((c) => (c.path === '/auth/refresh' ? json(200, session('A2', 'r2')) : json(200, adminProfile)))
    const cb = vi.fn()
    auth.onChange(cb)

    await vi.waitFor(() => expect(cb).toHaveBeenCalledWith({ uid: 'admin', email: 'admin@jcbworks.in' }))
    expect(f.calls.map(route)).toEqual(['POST /auth/refresh', 'GET /admin/me'])
    expect(f.calls[0].body).toEqual({ refreshToken: 'r1' })
    expect(f.calls[1].auth).toBe('Bearer A2')
    expect(stored()).toBe('r2')
  })

  it('reports signed out without a stored session, and after a refused one', async () => {
    const fresh = service(() => json(500))
    const cb = vi.fn()
    fresh.auth.onChange(cb)
    await vi.waitFor(() => expect(cb).toHaveBeenCalledWith(null))
    expect(fresh.f.calls).toHaveLength(0)

    sessionStorage.setItem(REFRESH_TOKEN_KEY, 'stale')
    const refused = service(() => apiError(401, 'unauthenticated', 'Sign in again.', { reason: 'invalid_refresh_token' }))
    const cb2 = vi.fn()
    refused.auth.onChange(cb2)
    await vi.waitFor(() => expect(cb2).toHaveBeenCalledWith(null))
    expect(cb2).not.toHaveBeenCalledWith(expect.objectContaining({ uid: expect.anything() }))
    expect(stored()).toBeNull()
  })

  it('never reveals whether an account exists on password reset', async () => {
    const { f, auth } = service((c) => (c.body as { email: string }).email === 'ghost@x.in' ? apiError(404, 'not_found', 'No such user.') : json(204))
    await expect(auth.sendPasswordReset(' admin@jcbworks.in ')).resolves.toBeUndefined()
    await expect(auth.sendPasswordReset('ghost@x.in')).resolves.toBeUndefined()
    expect(f.calls[0]).toMatchObject({ method: 'POST', path: '/auth/forgot-password', body: { email: 'admin@jcbworks.in' }, auth: null })

    const limited = service(() => apiError(429, 'resource_exhausted', 'Slow down.', { reason: 'rate_limited' }))
    await expect(limited.auth.sendPasswordReset('admin@jcbworks.in')).rejects.toThrow('Too many attempts')
  })

  it('signs out on the server best-effort and always clears the session', async () => {
    const { f, auth } = service((c) => {
      if (c.path === '/auth/login') return json(200, session('A1', 'r1'))
      if (c.path === '/admin/me') return json(200, adminProfile)
      return offline()
    })
    const cb = vi.fn()
    auth.onChange(cb)
    await auth.signIn('admin@jcbworks.in', 'supersecret')

    await expect(auth.signOut()).resolves.toBeUndefined()
    expect(f.calls.at(-1)).toMatchObject({ path: '/auth/logout', body: { refreshToken: 'r1' }, auth: 'Bearer A1' })
    expect(cb).toHaveBeenLastCalledWith(null)
    expect(stored()).toBeNull()
  })
})

describe('http admin api', () => {
  function signedIn(reply: (c: Call) => Response | Promise<Response>) {
    const f = fakeFetch(reply)
    const client = createApiClient({ baseUrl: BASE_URL, fetch: f.fn })
    client.setSession(session('A1', 'r1'))
    return { f, api: createHttpAdminApi(client) }
  }

  it('builds list query strings, omits empty filters and hands back the cursor', async () => {
    const { f, api } = signedIn(() => json(200, { items: [{ id: 'c1' }], next: 'cur-2' }))

    const page = await api.listCompanies({ status: 'pending', search: '  Patil ', after: 'cur-1' })
    expect(page).toEqual({ items: [{ id: 'c1' }], next: 'cur-2' })
    expect(f.calls[0]).toMatchObject({ method: 'GET', path: '/admin/companies', query: 'status=pending&search=Patil&cursor=cur-1', auth: 'Bearer A1' })

    await api.listCompanies({ search: '   ' })
    await api.listDevices({ companyId: 'c1', licenseId: '' })
    await api.listEvents({ deviceId: 'd 1', type: 'license.status' })
    await api.listReplacementRequests({ status: 'pending', after: 'a/b=' })
    expect(f.calls.slice(1).map((c) => `${c.path}?${c.query}`)).toEqual([
      '/admin/companies?',
      '/admin/devices?companyId=c1',
      '/admin/audit-events?deviceId=d+1&type=license.status',
      '/admin/replacement-requests?status=pending&cursor=a%2Fb%3D',
    ])
  })

  it('sends mutations with the right method, path and body', async () => {
    const { f, api } = signedIn(() => json(200, { ok: true }))

    await api.setLicenseStatus('c1', 'l1', 'suspended', 'Unpaid invoice')
    await api.updateLicense('c1', 'l1', { maxDevices: 3 }, 'Upgraded plan')
    await api.reviewReplacement({ companyId: 'c/1', requestId: 'r1', decision: 'approve', reason: 'Phone lost', revokeDeviceId: 'd1' })
    const company = { id: 'c1', status: 'active', ownerUid: 'u', createdAt: 1, name: 'Patil', contactPerson: 'A', phone: '9', address: 'Pune', invoicePrefix: 'PC', email: null, gstin: null } as const
    await api.updateCompany('c1', company)

    expect(f.calls.map((c) => [route(c), c.body])).toEqual([
      ['POST /admin/companies/c1/licenses/l1/status', { status: 'suspended', reason: 'Unpaid invoice' }],
      ['PATCH /admin/companies/c1/licenses/l1', { maxDevices: 3, reason: 'Upgraded plan' }],
      ['POST /admin/companies/c%2F1/replacement-requests/r1/review', { decision: 'approve', reason: 'Phone lost', revokeDeviceId: 'd1' }],
      ['PATCH /admin/companies/c1', { name: 'Patil', contactPerson: 'A', phone: '9', address: 'Pune', invoicePrefix: 'PC', email: null, gstin: null }],
    ])
    expect(f.calls.every((c) => c.auth === 'Bearer A1')).toBe(true)
  })

  it('returns null for a missing record and surfaces other errors', async () => {
    const { api } = signedIn((c) => (c.path.endsWith('/gone') ? apiError(404, 'not_found', 'Company not found.') : apiError(500, 'internal', 'Internal error.')))
    expect(await api.getCompany('gone')).toBeNull()
    await expect(api.getLicense('c1', 'l1')).rejects.toThrow('Internal error.')
  })
})
