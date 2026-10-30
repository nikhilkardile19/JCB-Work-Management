/** Session returned by `POST /auth/login` and `POST /auth/refresh`. Times are epoch ms (server clock). */
export interface Session {
  accessToken: string
  accessTokenExpiresAt: number
  refreshToken: string
  refreshTokenExpiresAt: number
  user: { id: string; email: string }
}

export type Method = 'GET' | 'POST' | 'PATCH' | 'DELETE'
/** Query parameters; undefined, null and '' are left out. */
export type Query = Record<string, string | number | null | undefined>
export type Fetch = (url: string, init: RequestInit) => Promise<Response>

export interface RequestOptions {
  body?: unknown
  query?: Query
  /** Send the access token and recover from a 401 by refreshing once (default true). */
  auth?: boolean
}

export const NETWORK_ERROR_MESSAGE = 'No internet connection, or the server is unreachable. Check your connection and try again.'
export const SESSION_EXPIRED_MESSAGE = 'Your session has expired. Sign in again.'
/** Per-tab: survives a reload, not a closed tab. */
export const REFRESH_TOKEN_KEY = 'jcbAdmin.refreshToken'

/** A failed call: the server's `{error:{code,message,reason?}}`, or status 0 when it could not be reached. */
export class ApiError extends Error {
  readonly status: number
  readonly code: string
  readonly reason: string | undefined
  readonly retryAfterMs: number | undefined
  readonly fields: Record<string, string> | undefined

  constructor(e: { status: number; code: string; message: string; reason?: string; retryAfterMs?: number; fields?: Record<string, string> }) {
    super(e.message)
    this.name = 'ApiError'
    this.status = e.status
    this.code = e.code
    this.reason = e.reason
    this.retryAfterMs = e.retryAfterMs
    this.fields = e.fields
  }
}

export interface ApiClient {
  request<T>(method: Method, path: string, options?: RequestOptions): Promise<T>
  /** Keeps a new session: access token in memory, refresh token in sessionStorage. */
  setSession(session: Session): void
  /** True when this tab holds a refresh token. */
  hasSession(): boolean
  /** Rotates the session; concurrent callers share one request. Ends the session if the server refuses. */
  refresh(): Promise<Session>
  /** Revokes the session on the server (best effort) and forgets it locally. */
  logout(): Promise<void>
  /** Called when the server ends the session (refresh refused), not on logout. Returns unsubscribe. */
  onSessionEnd(listener: () => void): () => void
}

/** Template tag that URL-encodes each interpolated segment: path`/admin/companies/${id}`. */
export function path(strings: TemplateStringsArray, ...segments: string[]): string {
  return String.raw({ raw: strings }, ...segments.map((s) => encodeURIComponent(s)))
}

const REFRESH_AHEAD_MS = 60_000
/** Floor for the refresh timer, so a badly skewed clock cannot cause a refresh loop. */
const MIN_REFRESH_DELAY_MS = 30_000
const MAX_TIMER_MS = 2 ** 31 - 1
const TIMEOUT_MS = 30_000

const storage = {
  get(): string | null {
    try {
      return sessionStorage.getItem(REFRESH_TOKEN_KEY)
    } catch {
      return null
    }
  },
  set(token: string | null) {
    try {
      if (token) sessionStorage.setItem(REFRESH_TOKEN_KEY, token)
      else sessionStorage.removeItem(REFRESH_TOKEN_KEY)
    } catch {
      // Storage blocked: the session still works, it just won't survive a reload.
    }
  },
}

function queryString(query: Query | undefined): string {
  const qs = new URLSearchParams()
  for (const [k, v] of Object.entries(query ?? {})) if (v !== undefined && v !== null && v !== '') qs.set(k, String(v))
  const s = qs.toString()
  return s ? `?${s}` : ''
}

function fallback(status: number): { code: string; message: string } {
  if (status === 401) return { code: 'unauthenticated', message: SESSION_EXPIRED_MESSAGE }
  if (status === 403) return { code: 'permission_denied', message: 'Your admin role does not allow this.' }
  if (status === 404) return { code: 'not_found', message: 'That record was not found.' }
  if (status === 429) return { code: 'resource_exhausted', message: 'Too many requests. Wait a moment and try again.' }
  if (status === 502 || status === 503 || status === 504) return { code: 'unavailable', message: 'The server is unreachable right now. Try again in a moment.' }
  if (status >= 500) return { code: 'internal', message: 'Something went wrong on the server. Try again in a moment.' }
  return { code: status === 400 ? 'invalid_argument' : status === 409 ? 'failed_precondition' : 'unknown', message: 'The server refused this action.' }
}

function errorFrom(status: number, data: unknown): ApiError {
  const e = (data as { error?: Record<string, unknown> } | null | undefined)?.error ?? {}
  const base = fallback(status)
  return new ApiError({
    status,
    code: typeof e.code === 'string' ? e.code : base.code,
    message: typeof e.message === 'string' && e.message ? e.message : base.message,
    reason: typeof e.reason === 'string' ? e.reason : undefined,
    retryAfterMs: typeof e.retryAfterMs === 'number' ? e.retryAfterMs : undefined,
    fields: e.fields && typeof e.fields === 'object' ? (e.fields as Record<string, string>) : undefined,
  })
}

const sessionExpired = () => new ApiError({ status: 401, code: 'unauthenticated', reason: 'session_expired', message: SESSION_EXPIRED_MESSAGE })

/** JSON client for the REST API (`VITE_API_BASE_URL`, e.g. `http://localhost:3000/api/v1`). */
export function createApiClient({ baseUrl, fetch: doFetch = (url, init) => fetch(url, init) }: { baseUrl: string; fetch?: Fetch }): ApiClient {
  const base = baseUrl.replace(/\/+$/, '')
  let accessToken: string | null = null
  let refreshToken: string | null = null
  let timer: ReturnType<typeof setTimeout> | undefined
  let inflight: Promise<Session> | null = null
  /** Bumped whenever the session is replaced or cleared, so stale refreshes are dropped. */
  let epoch = 0
  const endListeners = new Set<() => void>()

  const currentRefreshToken = () => refreshToken ?? storage.get()

  async function send<T>(method: Method, url: string, body: unknown, token: string | null): Promise<T> {
    const headers: Record<string, string> = { Accept: 'application/json' }
    if (body !== undefined) headers['Content-Type'] = 'application/json'
    if (token) headers.Authorization = `Bearer ${token}`
    let res: Response
    let text: string
    try {
      res = await doFetch(base + url, {
        method,
        headers,
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: typeof AbortSignal.timeout === 'function' ? AbortSignal.timeout(TIMEOUT_MS) : undefined,
      })
      text = await res.text()
    } catch {
      throw new ApiError({ status: 0, code: 'unavailable', reason: 'network', message: NETWORK_ERROR_MESSAGE })
    }
    let data: unknown
    if (text) {
      try {
        data = JSON.parse(text)
      } catch {
        if (res.ok) throw new ApiError({ status: res.status, code: 'internal', message: 'The server sent an unexpected response.' })
      }
    }
    if (!res.ok) throw errorFrom(res.status, data)
    return data as T
  }

  function setSession(s: Session) {
    epoch++
    accessToken = s.accessToken
    refreshToken = s.refreshToken
    storage.set(s.refreshToken)
    clearTimeout(timer)
    const delay = Math.min(Math.max(s.accessTokenExpiresAt - Date.now() - REFRESH_AHEAD_MS, MIN_REFRESH_DELAY_MS), MAX_TIMER_MS)
    // A failed proactive refresh is not fatal: the next 401 retries it.
    timer = setTimeout(() => void refresh().catch(() => {}), delay)
  }

  function clear() {
    epoch++
    accessToken = null
    refreshToken = null
    storage.set(null)
    clearTimeout(timer)
  }

  /** The server refused the session: forget it and tell the auth layer. */
  function end(): ApiError {
    clear()
    endListeners.forEach((l) => l())
    return sessionExpired()
  }

  async function runRefresh(): Promise<Session> {
    const token = currentRefreshToken()
    if (!token) throw end()
    const started = epoch
    let s: Session
    try {
      s = await send<Session>('POST', '/auth/refresh', { refreshToken: token }, null)
    } catch (e) {
      if (started === epoch && e instanceof ApiError && (e.status === 401 || e.status === 403)) throw end()
      throw e
    }
    if (started !== epoch) throw sessionExpired() // signed out (or in again) meanwhile
    setSession(s)
    return s
  }

  function refresh(): Promise<Session> {
    inflight ??= runRefresh().finally(() => {
      inflight = null
    })
    return inflight
  }

  async function request<T>(method: Method, p: string, { body, query, auth = true }: RequestOptions = {}): Promise<T> {
    const url = p + queryString(query)
    if (!auth) return send<T>(method, url, body, null)
    const token = accessToken ?? (await refresh()).accessToken
    try {
      return await send<T>(method, url, body, token)
    } catch (e) {
      if (!(e instanceof ApiError && e.status === 401)) throw e
    }
    // Expired or revoked access token: refresh once (shared with concurrent callers), then retry once.
    const fresh = accessToken && accessToken !== token ? accessToken : (await refresh()).accessToken
    try {
      return await send<T>(method, url, body, fresh)
    } catch (e) {
      if (e instanceof ApiError && e.status === 401 && accessToken === fresh) throw end()
      throw e
    }
  }

  async function logout() {
    const token = accessToken
    const rt = currentRefreshToken()
    clear()
    if (!rt) return
    try {
      await send('POST', '/auth/logout', { refreshToken: rt }, token)
    } catch (e) {
      if (!(e instanceof ApiError && e.status === 401)) return
      // Access token already expired: trade the refresh token for a fresh pair just to revoke it.
      try {
        const s = await send<Session>('POST', '/auth/refresh', { refreshToken: rt }, null)
        await send('POST', '/auth/logout', { refreshToken: s.refreshToken }, s.accessToken)
      } catch {
        // Best effort: the session expires on its own.
      }
    }
  }

  return {
    request,
    setSession,
    hasSession: () => Boolean(currentRefreshToken()),
    refresh,
    logout,
    onSessionEnd(listener) {
      endListeners.add(listener)
      return () => {
        endListeners.delete(listener)
      }
    },
  }
}
