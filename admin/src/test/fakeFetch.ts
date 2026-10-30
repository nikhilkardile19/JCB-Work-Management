import { vi } from 'vitest'
import type { Session } from '../lib/apiClient'

export const BASE_URL = 'http://api.test/api/v1'

export interface Call {
  method: string
  /** Path below BASE_URL, e.g. /admin/companies. */
  path: string
  /** Raw query string without '?'. */
  query: string
  body: unknown
  auth: string | null
}

/** Stand-in for `fetch` that records each call and answers from [reply]. */
export function fakeFetch(reply: (call: Call) => Response | Promise<Response>) {
  const calls: Call[] = []
  const fn = vi.fn(async (url: string, init: RequestInit = {}) => {
    const u = new URL(url)
    const call: Call = {
      method: init.method ?? 'GET',
      path: u.pathname.replace('/api/v1', ''),
      query: u.search.slice(1),
      body: typeof init.body === 'string' ? JSON.parse(init.body) : undefined,
      auth: new Headers(init.headers).get('Authorization'),
    }
    calls.push(call)
    return reply(call)
  })
  return { fn, calls, count: (path: string) => calls.filter((c) => c.path === path).length }
}

export const json = (status: number, body?: unknown) =>
  new Response(body === undefined ? null : JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } })

export const apiError = (status: number, code: string, message: string, extra: Record<string, unknown> = {}) =>
  json(status, { error: { code, message, ...extra } })

export const offline = () => Promise.reject(new TypeError('Failed to fetch'))

export function session(accessToken: string, refreshToken: string, ttlMs = 15 * 60_000): Session {
  return {
    accessToken,
    accessTokenExpiresAt: Date.now() + ttlMs,
    refreshToken,
    refreshTokenExpiresAt: Date.now() + 12 * 3_600_000,
    user: { id: 'admin', email: 'admin@jcbworks.in' },
  }
}

export const adminProfile = { uid: 'admin', email: 'admin@jcbworks.in', role: 'super', permissions: [] }
