import type {
  AdminApi,
  AdminProfile,
  AuditEvent,
  Company,
  CompanyProfile,
  Cursor,
  DashboardMetrics,
  Device,
  License,
  Member,
  Page,
  ReplacementRequest,
} from './adminApi'
import { ApiError, path, type ApiClient, type Query } from './apiClient'

/** Only the editable fields: the edit form starts from a full Company. */
const profileOf = (p: CompanyProfile): CompanyProfile => ({
  name: p.name,
  contactPerson: p.contactPerson,
  phone: p.phone,
  address: p.address,
  invoicePrefix: p.invoicePrefix,
  email: p.email,
  gstin: p.gstin,
})

/** `AdminApi` over `/admin/*`. The server re-checks the admin's role and writes the audit trail. */
export function createHttpAdminApi(client: ApiClient): AdminApi {
  const get = <T>(url: string, query?: Query) => client.request<T>('GET', url, { query })
  const post = <T>(url: string, body: unknown) => client.request<T>('POST', url, { body })
  const patch = (url: string, body: unknown) => client.request<unknown>('PATCH', url, { body })

  async function page<T>(url: string, query: Query, after: Cursor | undefined): Promise<Page<T>> {
    const r = await get<Page<T>>(url, { ...query, cursor: after })
    return { items: r.items, next: r.next ?? null }
  }

  const orNull = <T>(p: Promise<T>): Promise<T | null> =>
    p.catch((e: unknown) => {
      if (e instanceof ApiError && e.status === 404) return null
      throw e
    })

  const license = (companyId: string, licenseId: string) => path`/admin/companies/${companyId}/licenses/${licenseId}`

  return {
    me: () => get<AdminProfile>('/admin/me'),
    metrics: () => get<DashboardMetrics>('/admin/metrics'),

    listCompanies: ({ status, search, after }) => page<Company>('/admin/companies', { status, search: search?.trim() }, after),
    getCompany: (id) => orNull(get<Company>(path`/admin/companies/${id}`)),
    companyMembers: async (id) => (await get<{ items: Member[] }>(path`/admin/companies/${id}/members`)).items,
    listLicenses: ({ status, companyId, after }) => page<License>('/admin/licenses', { status, companyId }, after),
    getLicense: (companyId, licenseId) => orNull(get<License>(license(companyId, licenseId))),
    listDevices: ({ status, companyId, licenseId, after }) => page<Device>('/admin/devices', { status, companyId, licenseId }, after),
    getDevice: (companyId, deviceId) => orNull(get<Device>(path`/admin/companies/${companyId}/devices/${deviceId}`)),
    listReplacementRequests: ({ status, after }) => page<ReplacementRequest>('/admin/replacement-requests', { status }, after),
    listEvents: ({ companyId, licenseId, deviceId, type, after }) =>
      page<AuditEvent>('/admin/audit-events', { companyId, licenseId, deviceId, type }, after),

    async setCompanyStatus(companyId, status, reason) {
      await post(path`/admin/companies/${companyId}/status`, { status, reason })
    },
    createCompany: (input) => post<{ companyId: string; newUser: boolean }>('/admin/companies', { ...profileOf(input), ownerEmail: input.ownerEmail }),
    async updateCompany(companyId, profile) {
      await patch(path`/admin/companies/${companyId}`, profileOf(profile))
    },
    createLicense: ({ companyId, validFrom, validUntil, maxDevices }) =>
      post<{ licenseId: string; activationCode: string }>(path`/admin/companies/${companyId}/licenses`, { validFrom, validUntil, maxDevices }),
    async setLicenseStatus(companyId, licenseId, status, reason) {
      await post(`${license(companyId, licenseId)}/status`, { status, reason })
    },
    async updateLicense(companyId, licenseId, { validUntil, maxDevices }, reason) {
      await patch(license(companyId, licenseId), { validUntil, maxDevices, reason })
    },
    rotateActivationCode: (companyId, licenseId, reason) =>
      post<{ activationCode: string }>(`${license(companyId, licenseId)}/rotate-code`, { reason }),
    async revokeDevice(companyId, deviceId, reason) {
      await post(path`/admin/companies/${companyId}/devices/${deviceId}/revoke`, { reason })
    },
    async reviewReplacement({ companyId, requestId, decision, reason, revokeDeviceId }) {
      await post(path`/admin/companies/${companyId}/replacement-requests/${requestId}/review`, { decision, reason, revokeDeviceId })
    },
  }
}
