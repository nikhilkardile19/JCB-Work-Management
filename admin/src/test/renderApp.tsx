import { render } from '@testing-library/react'
import { MemoryRouter, useLocation } from 'react-router'
import { AppRoutes } from '../app/routes'
import { AdminApiContext } from '../lib/adminApi'
import { AuthProvider } from '../lib/auth'
import { ToastProvider } from '../lib/toast'
import type { FakeAdminApi } from './fakeAdminApi'
import { FakeAuthService } from './fakeAuth'

function LocationProbe() {
  const l = useLocation()
  return <output data-testid="path">{l.pathname + l.search}</output>
}

/** Renders the portal signed in as a developer admin, backed by [api]. */
export function renderSignedIn(path: string, api: FakeAdminApi) {
  return render(
    <AuthProvider service={new FakeAuthService({ uid: 'admin', email: 'admin@jcbworks.in' })}>
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
}
