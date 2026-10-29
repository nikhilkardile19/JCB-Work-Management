import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router'
import { AppRoutes } from './app/routes'
import { AdminApiContext, type AdminApi } from './lib/adminApi'
import { AuthProvider } from './lib/auth'
import type { AuthService } from './lib/authContext'
import { ToastProvider } from './lib/toast'
import './index.css'

const configured = Boolean(import.meta.env.VITE_FIREBASE_API_KEY && import.meta.env.VITE_FIREBASE_PROJECT_ID)

// Firebase SDK is loaded as a separate chunk so the shell paints sooner.
const services: { auth: AuthService; api: AdminApi } | null = configured
  ? (await import('./lib/firebaseAuthService')).createFirebaseServices()
  : null

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
