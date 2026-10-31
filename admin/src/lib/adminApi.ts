import { createContext, useContext } from 'react'

export type CompanyStatus = 'pending' | 'active' | 'suspended'
export type LicenseStatus = 'pending' | 'active' | 'suspended' | 'expired' | 'revoked'
export type DeviceStatus = 'active' | 'revoked'
export type AdminPermission = 'companies.manage' | 'licenses.manage' | 'devices.revoke'

export interface CompanyProfile {
  name: string
  contactPerson: string
  phone: string
  address: string
  invoicePrefix: string
  email: string | null
  gstin: string | null
}

export interface Company extends CompanyProfile {
  id: string
  status: CompanyStatus
  ownerUid: string
  createdAt: number | null
}

export interface Member {
  uid: string
  email: string | null
  role: string
  status: string
}

export interface License {
  id: string
  companyId: string
  companyName: string | null
  status: LicenseStatus
  validFrom: number
  validUntil: number
  maxDevices: number
  lastValidatedAt: number | null
  /** Codes work once: when the current code was used, and by which phone. */
  activationCodeUsedAt: number | null
  activationCodeDeviceId: string | null
}

/** A new activation code: shown once, and emailed to the owner when email is set up. */
export interface IssuedCode {
  activationCode: string
  /** Null when it was not emailed; the admin passes it on. */
  emailedTo: string | null
}

export interface LicenseTerms {
  validFrom: number
  validUntil: number
  maxDevices: number
}

export interface Device {
  id: string
  companyId: string
  licenseId: string
  userId: string
  deviceModel: string | null
  status: DeviceStatus
  activatedAt: number | null
  lastSeenAt: number | null
  revokeReason: string | null
  replacementForDeviceId: string | null
  replacedBy: string | null
}

export type RequestStatus = 'pending' | 'approved' | 'rejected'

export interface ReplacementRequest {
  id: string
  companyId: string
  companyName: string | null
  licenseId: string
  newDeviceId: string
  newDeviceModel: string | null
  requestedBy: string
  requesterEmail: string | null
  reason: string
  status: RequestStatus
  createdAt: number | null
  reviewReason: string | null
  revokedDeviceId: string | null
}

export interface AuditEvent {
  id: string
  type: string
  actorId: string | null
  companyId: string | null
  licenseId: string | null
  deviceId: string | null
  reason: string | null
  at: number | null
  details: Record<string, unknown>
}

/** Opaque cursor for "load more": the server's `next`, sent back as `?cursor=`. */
export type Cursor = string

export interface Page<T> {
  items: T[]
  next: Cursor | null
}

export interface DashboardMetrics {
  companies: Record<CompanyStatus, number>
  licenses: { active: number; expiringSoon: number; expired: number; suspended: number }
  activeDevices: number
  pendingRequests: number
}

export interface AdminProfile {
  uid: string
  email: string | null
  role: 'super' | 'support'
  permissions: AdminPermission[]
}

export const PAGE_SIZE = 25
export const EXPIRING_DAYS = 30

/**
 * Everything the portal reads and changes, served by the REST API under
 * `/admin`. The server re-checks the admin's role on every call and writes
 * the audit trail for every change.
 */
export interface AdminApi {
  me(): Promise<AdminProfile>
  metrics(): Promise<DashboardMetrics>

  listCompanies(q: { status?: CompanyStatus; search?: string; after?: Cursor }): Promise<Page<Company>>
  getCompany(id: string): Promise<Company | null>
  companyMembers(id: string): Promise<Member[]>
  listLicenses(q: { status?: LicenseStatus; companyId?: string; after?: Cursor }): Promise<Page<License>>
  getLicense(companyId: string, licenseId: string): Promise<License | null>
  listDevices(q: { status?: DeviceStatus; companyId?: string; licenseId?: string; after?: Cursor }): Promise<Page<Device>>
  getDevice(companyId: string, deviceId: string): Promise<Device | null>
  listReplacementRequests(q: { status?: RequestStatus; after?: Cursor }): Promise<Page<ReplacementRequest>>
  listEvents(q: { companyId?: string; licenseId?: string; deviceId?: string; type?: string; after?: Cursor }): Promise<Page<AuditEvent>>

  setCompanyStatus(companyId: string, status: CompanyStatus, reason: string): Promise<void>
  /** Activates a pending company and issues its license in one step. */
  approveCompany(input: LicenseTerms & { companyId: string; reason: string }): Promise<IssuedCode & { licenseId: string }>
  createCompany(profile: CompanyProfile & { ownerEmail: string }): Promise<{ companyId: string; newUser: boolean }>
  updateCompany(companyId: string, profile: CompanyProfile): Promise<void>
  createLicense(input: LicenseTerms & { companyId: string }): Promise<IssuedCode & { licenseId: string }>
  setLicenseStatus(companyId: string, licenseId: string, status: 'active' | 'suspended' | 'revoked', reason: string): Promise<void>
  updateLicense(companyId: string, licenseId: string, changes: { validUntil?: number; maxDevices?: number }, reason: string): Promise<void>
  rotateActivationCode(companyId: string, licenseId: string, reason: string): Promise<IssuedCode>
  revokeDevice(companyId: string, deviceId: string, reason: string): Promise<void>
  /** Approve (optionally revoking [revokeDeviceId]) or reject. */
  reviewReplacement(input: { companyId: string; requestId: string; decision: 'approve' | 'reject'; reason: string; revokeDeviceId?: string }): Promise<void>
}

export const AdminApiContext = createContext<AdminApi | null>(null)

export function useAdminApi(): AdminApi {
  const api = useContext(AdminApiContext)
  if (!api) throw new Error('useAdminApi must be used inside <AdminApiContext.Provider>')
  return api
}

export function can(profile: AdminProfile | null, permission: AdminPermission): boolean {
  return !!profile && (profile.role === 'super' || profile.permissions.includes(permission))
}
