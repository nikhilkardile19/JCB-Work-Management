import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router'
import { AppRoutes } from './app/routes'
import { AdminApiContext } from './lib/adminApi'
import { createApiClient } from './lib/apiClient'
import { AuthProvider } from './lib/auth'
import { createHttpAdminApi } from './lib/httpAdminApi'
import { createHttpAuthService } from './lib/httpAuthService'
import { ToastProvider } from './lib/toast'
import './index.css'

const configured = Boolean(import.meta.env.VITE_API_BASE_URL)

// One client (one session) shared by sign-in and the admin API.
const client = configured ? createApiClient({ baseUrl: import.meta.env.VITE_API_BASE_URL! }) : null
const services = client ? { auth: createHttpAuthService(client), api: createHttpAdminApi(client) } : null

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AuthProvider service={services?.auth ?? null}>
      <AdminApiContext.Provider value={services?.api ?? null}>
        <ToastProvider>
          <BrowserRouter>
            <AppRoutes />
          </BrowserRouter>
        </ToastProvider>
      </AdminApiContext.Provider>
    </AuthProvider>
  </StrictMode>,
)
