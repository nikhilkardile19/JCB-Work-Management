import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, useLocation } from 'react-router'
import { afterEach, describe, expect, it } from 'vitest'
import { AppRoutes } from '../../app/routes'
import { createApiClient } from '../../lib/apiClient'
import { AuthProvider } from '../../lib/auth'
import { createHttpAuthService } from '../../lib/httpAuthService'
import { apiError, BASE_URL, fakeFetch, json, offline, type Call } from '../../test/fakeFetch'

function LocationProbe() {
  return <output data-testid="path">{useLocation().pathname}</output>
}

/** Renders the real HTTP auth service over a fake fetch; no reply means "not configured". */
function renderReset(url: string, reply?: (c: Call) => Response | Promise<Response>) {
  const f = fakeFetch(reply ?? (() => json(500)))
  const service = reply ? createHttpAuthService(createApiClient({ baseUrl: BASE_URL, fetch: f.fn })) : null
  render(
    <AuthProvider service={service}>
      <MemoryRouter initialEntries={[url]}>
        <AppRoutes />
        <LocationProbe />
      </MemoryRouter>
    </AuthProvider>,
  )
  return f
}

async function submit(password: string, confirm: string) {
  await userEvent.type(await screen.findByLabelText('New password'), password)
  await userEvent.type(screen.getByLabelText('Confirm new password'), confirm)
  await userEvent.click(screen.getByRole('button', { name: 'Change password' }))
}

afterEach(() => {
  cleanup()
  sessionStorage.clear()
})

describe('reset password page', () => {
  it('sets the new password and links back to sign-in', async () => {
    const f = renderReset('/reset-password?token=tok-1', () => json(204))
    await submit('newsecret1', 'newsecret1')

    expect(await screen.findByText(/Your password has been changed/)).toBeInTheDocument()
    expect(f.calls).toEqual([{ method: 'POST', path: '/auth/reset-password', query: '', body: { token: 'tok-1', password: 'newsecret1' }, auth: null }])

    await userEvent.click(screen.getByRole('link', { name: /back to sign in/i }))
    expect(await screen.findByRole('heading', { name: 'Developer Admin' })).toBeInTheDocument()
    expect(screen.getByTestId('path').textContent).toBe('/login')
  })

  it('checks length and confirmation before calling the server', async () => {
    const f = renderReset('/reset-password?token=tok-1', () => json(204))
    await submit('short', 'short')
    expect(screen.getByText('Password must be at least 8 characters')).toBeInTheDocument()

    await userEvent.clear(screen.getByLabelText('New password'))
    await userEvent.clear(screen.getByLabelText('Confirm new password'))
    await submit('newsecret1', 'newsecret2')
    expect(screen.getByText('Passwords do not match')).toBeInTheDocument()
    expect(f.calls).toHaveLength(0)
  })

  it('explains an invalid or expired link', async () => {
    renderReset('/reset-password?token=used', () => apiError(400, 'invalid_argument', 'Invalid token.', { reason: 'invalid_reset_token' }))
    await submit('newsecret1', 'newsecret1')
    expect(await screen.findByText('This reset link is invalid or has expired.')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Change password' })).toBeNull()
    expect(screen.getByRole('link', { name: /back to sign in/i })).toHaveAttribute('href', '/login')
  })

  it('treats a link without a token as invalid', async () => {
    const f = renderReset('/reset-password', () => json(204))
    expect(await screen.findByText('This reset link is invalid or has expired.')).toBeInTheDocument()
    expect(f.calls).toHaveLength(0)
  })

  it('keeps the form and explains a network error', async () => {
    renderReset('/reset-password?token=tok-1', offline)
    await submit('newsecret1', 'newsecret1')
    expect(await screen.findByText('No internet connection. Connect and try again.')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Change password' })).toBeEnabled()
  })

  it('shows the not-configured notice without an API', async () => {
    renderReset('/reset-password?token=tok-1')
    expect(await screen.findByRole('heading', { name: 'Reset password' })).toBeInTheDocument()
    expect(screen.getByText(/not configured/)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Change password' })).toBeDisabled()
  })
})
