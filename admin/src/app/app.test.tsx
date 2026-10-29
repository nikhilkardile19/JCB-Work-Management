import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, useLocation } from 'react-router'
import { afterEach, describe, expect, it } from 'vitest'
import { AdminApiContext } from '../lib/adminApi'
import { AuthProvider } from '../lib/auth'
import { ToastProvider } from '../lib/toast'
import { FakeAdminApi } from '../test/fakeAdminApi'
import { FakeAuthService } from '../test/fakeAuth'
import type { AuthService } from '../lib/authContext'
import { messageForAuthError, NOT_ADMIN_MESSAGE } from '../lib/firebaseAuthService'
import { validators } from '../lib/validators'
import { AppRoutes } from './routes'

function LocationProbe() {
  return <output data-testid="path">{useLocation().pathname}</output>
}

function renderAt(path: string, service: AuthService | null = new FakeAuthService(), api = new FakeAdminApi()) {
  render(
    <AuthProvider service={service}>
      <AdminApiContext.Provider value={api}>
        <ToastProvider>
          <MemoryRouter initialEntries={[path]}>
            <AppRoutes />
            <LocationProbe />
          </MemoryRouter>
        </ToastProvider>
      </AdminApiContext.Provider>
    </AuthProvider>,
  )
  return service
}

const path = () => screen.getByTestId('path').textContent
const loginHeading = () => screen.findByRole('heading', { name: 'Developer Admin' })

async function fillLogin(email: string, password: string) {
  await userEvent.type(screen.getByLabelText('Email'), email)
  await userEvent.type(screen.getByLabelText('Password'), password)
  await userEvent.click(screen.getByRole('button', { name: /sign in/i }))
}

afterEach(cleanup)

describe('validators and error messages', () => {
  it('validates email and password', () => {
    expect(validators.email('')).toBeTruthy()
    expect(validators.email('admin@site')).toBeTruthy()
    expect(validators.email(' admin@jcbworks.in ')).toBeNull()
    expect(validators.password('short')).toMatch(/at least 8/)
    expect(validators.password('longenough')).toBeNull()
  })

  it('maps Firebase auth codes to friendly messages', () => {
    expect(messageForAuthError('auth/invalid-credential')).toBe('Incorrect email or password.')
    expect(messageForAuthError('auth/unknown')).toMatch(/try again/)
  })
})

describe('route protection', () => {
  it('redirects signed-out users to login', async () => {
    renderAt('/licenses')
    expect(await loginHeading()).toBeInTheDocument()
    expect(path()).toBe('/login')
  })

  it('restores an existing admin session', async () => {
    renderAt('/devices', new FakeAuthService({ uid: 'u', email: 'admin@jcbworks.in' }))
    expect(await screen.findByRole('heading', { name: 'Devices' })).toBeInTheDocument()
  })

  it('shows validation errors and does not sign in', async () => {
    renderAt('/login')
    await loginHeading()
    await userEvent.click(screen.getByRole('button', { name: /sign in/i }))
    expect(screen.getByText('Enter your email address')).toBeInTheDocument()
    expect(screen.getByText('Enter your password')).toBeInTheDocument()
    expect(path()).toBe('/login')
  })

  it('rejects accounts that are not developer admins', async () => {
    renderAt('/login')
    await loginHeading()
    await fillLogin('owner@customer.in', 'supersecret')
    expect(await screen.findByText(NOT_ADMIN_MESSAGE)).toBeInTheDocument()
    expect(path()).toBe('/login')
  })

  it('shows wrong-password errors', async () => {
    renderAt('/login')
    await loginHeading()
    await fillLogin('admin@jcbworks.in', 'wrong-password')
    expect(await screen.findByText('Incorrect email or password.')).toBeInTheDocument()
  })

  it('shows and hides the password', async () => {
    renderAt('/login')
    await loginHeading()
    const input = screen.getByLabelText('Password')
    expect(input).toHaveAttribute('type', 'password')
    await userEvent.click(screen.getByRole('button', { name: 'Show password' }))
    expect(input).toHaveAttribute('type', 'text')
    await userEvent.click(screen.getByRole('button', { name: 'Hide password' }))
    expect(input).toHaveAttribute('type', 'password')
  })

  it('signs in, returns to the requested page, navigates and signs out', async () => {
    renderAt('/licenses')
    await loginHeading()
    await fillLogin('admin@jcbworks.in', 'supersecret')

    expect(await screen.findByRole('heading', { name: 'Licenses' })).toBeInTheDocument()
    expect(path()).toBe('/licenses')

    await userEvent.click(screen.getByRole('link', { name: 'Devices' }))
    expect(screen.getByRole('heading', { name: 'Devices' })).toBeInTheDocument()

    await userEvent.click(screen.getByRole('button', { name: /sign out/i }))
    expect(await loginHeading()).toBeInTheDocument()
  })

  it('sends a password reset for the typed email', async () => {
    const service = new FakeAuthService()
    renderAt('/login', service)
    await loginHeading()
    await userEvent.type(screen.getByLabelText('Email'), 'admin@jcbworks.in')
    await userEvent.click(screen.getByRole('button', { name: /forgot password/i }))
    expect(await screen.findByText(/reset link is on its way/)).toBeInTheDocument()
    expect(service.resetEmail).toBe('admin@jcbworks.in')
  })

  it('explains when Firebase is not configured and disables sign-in', async () => {
    renderAt('/login', null)
    expect(await loginHeading()).toBeInTheDocument()
    expect(screen.getByText(/not configured/)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /sign in/i })).toBeDisabled()
  })

  it('shows not-found inside the shell for unknown routes', async () => {
    renderAt('/nope', new FakeAuthService({ uid: 'u', email: 'admin@jcbworks.in' }))
    expect(await screen.findByText('Page not found')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Dashboard' })).toBeInTheDocument()
  })
})
