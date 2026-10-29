import { useRoutes, type RouteObject } from 'react-router'
import { AuditLogsPage } from '../features/audit/AuditLogsPage'
import { CompaniesPage } from '../features/companies/CompaniesPage'
import { CompanyDetailPage } from '../features/companies/CompanyDetailPage'
import { DashboardPage } from '../features/dashboard/DashboardPage'
import { DeviceDetailPage } from '../features/devices/DeviceDetailPage'
import { DevicesPage } from '../features/devices/DevicesPage'
import { ReplacementRequestsPage } from '../features/devices/ReplacementRequestsPage'
import { LicenseDetailPage } from '../features/licenses/LicenseDetailPage'
import { LicensesPage } from '../features/licenses/LicensesPage'
import { LoginPage } from '../features/login/LoginPage'
import { NotFoundPage } from '../features/sections/NotFoundPage'
import { RequireAuth } from '../lib/auth'
import { AppLayout } from './AppLayout'

const routes: RouteObject[] = [
  { path: '/login', element: <LoginPage /> },
  {
    path: '/',
    element: (
      <RequireAuth>
        <AppLayout />
      </RequireAuth>
    ),
    children: [
      { index: true, element: <DashboardPage /> },
      { path: 'companies', element: <CompaniesPage /> },
      { path: 'companies/:companyId', element: <CompanyDetailPage /> },
      { path: 'licenses', element: <LicensesPage /> },
      { path: 'licenses/:companyId/:licenseId', element: <LicenseDetailPage /> },
      { path: 'devices', element: <DevicesPage /> },
      { path: 'devices/:companyId/:deviceId', element: <DeviceDetailPage /> },
      { path: 'replacement-requests', element: <ReplacementRequestsPage /> },
      { path: 'audit-logs', element: <AuditLogsPage /> },
      { path: '*', element: <NotFoundPage /> },
    ],
  },
]

export function AppRoutes() {
  return useRoutes(routes)
}
