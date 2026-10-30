import {
  PAGE_SIZE,
  type AdminApi,
  type AdminProfile,
  type AuditEvent,
  type Company,
  type CompanyProfile,
  type Device,
  type License,
  type Member,
  type Page,
  type ReplacementRequest,
} from '../lib/adminApi'

const DAY = 86_400_000

function paginate<T>(rows: T[], after: unknown): Page<T> {
  const start = typeof after === 'string' ? Number(after) : 0
  const items = rows.slice(start, start + PAGE_SIZE)
  return { items, next: start + PAGE_SIZE < rows.length ? String(start + PAGE_SIZE) : null }
}

/** In-memory stand-in for the `/admin` REST API. */
export class FakeAdminApi implements AdminApi {
  profile: AdminProfile = { uid: 'admin', email: 'admin@jcbworks.in', role: 'super', permissions: [] }
  companies: Company[] = []
  members: Record<string, Member[]> = {}
  licenses: License[] = []
  devices: Device[] = []
  events: AuditEvent[] = []
  issuedCodes: string[] = []
  requests: ReplacementRequest[] = []
  private seq = 0

  addCompany(c: Partial<Company> & { name: string }): Company {
    const company: Company = {
      id: c.id ?? `co${++this.seq}`,
      contactPerson: 'Owner',
      phone: '9876543210',
      address: 'Pune, Maharashtra',
      invoicePrefix: 'JCB',
      email: null,
      gstin: null,
      status: 'pending',
      ownerUid: 'owner',
      createdAt: Date.now() - this.seq * 1000,
      ...c,
    }
    this.companies.push(company)
    this.members[company.id] = [{ uid: 'owner', email: 'owner@x.in', role: 'owner', status: 'active' }]
    return company
  }

  addLicense(l: Partial<License> & { companyId: string }): License {
    const license: License = {
      id: `lic${++this.seq}`,
      companyName: this.companies.find((c) => c.id === l.companyId)?.name ?? null,
      status: 'active',
      validFrom: Date.now() - DAY,
      validUntil: Date.now() + 100 * DAY,
      maxDevices: 2,
      lastValidatedAt: null,
      ...l,
    }
    this.licenses.push(license)
    return license
  }

  addDevice(d: Partial<Device> & { companyId: string; licenseId: string }): Device {
    const device: Device = {
      id: `dev${++this.seq}`,
      userId: 'owner',
      deviceModel: 'android 14',
      status: 'active',
      activatedAt: Date.now() - DAY,
      lastSeenAt: Date.now(),
      revokeReason: null,
      replacementForDeviceId: null,
      replacedBy: null,
      ...d,
    } as Device
    this.devices.push(device)
    return device
  }

  private log(type: string, fields: Partial<AuditEvent> & { details?: Record<string, unknown> }) {
    this.events.unshift({
      id: `e${++this.seq}`,
      type,
      actorId: this.profile.uid,
      companyId: null,
      licenseId: null,
      deviceId: null,
      reason: null,
      at: Date.now(),
      details: {},
      ...fields,
    })
  }

  private require(p: string) {
    if (this.profile.role !== 'super' && !this.profile.permissions.includes(p as never)) {
      throw new Error(`Your admin role does not allow ${p}.`)
    }
  }

  async me() {
    return this.profile
  }

  async metrics() {
    const n = (f: (l: License) => boolean) => this.licenses.filter(f).length
    return {
      companies: {
        pending: this.companies.filter((c) => c.status === 'pending').length,
        active: this.companies.filter((c) => c.status === 'active').length,
        suspended: this.companies.filter((c) => c.status === 'suspended').length,
      },
      licenses: {
        active: n((l) => l.status === 'active'),
        expiringSoon: n((l) => l.status === 'active' && l.validUntil < Date.now() + 30 * DAY),
        expired: n((l) => l.status === 'expired'),
        suspended: n((l) => l.status === 'suspended'),
      },
      activeDevices: this.devices.filter((d) => d.status === 'active').length,
      pendingRequests: 0,
    }
  }

  async listCompanies({ status, search, after }: { status?: Company['status']; search?: string; after?: unknown }) {
    const term = search?.trim().toLowerCase()
    const rows = this.companies
      .filter((c) => (!status || c.status === status) && (!term || c.name.toLowerCase().startsWith(term)))
      .sort((a, b) => (term ? a.name.localeCompare(b.name) : (b.createdAt ?? 0) - (a.createdAt ?? 0)))
    return paginate(rows, after)
  }

  async getCompany(id: string) {
    return this.companies.find((c) => c.id === id) ?? null
  }

  async companyMembers(id: string) {
    return this.members[id] ?? []
  }

  async listLicenses({ status, companyId, after }: { status?: License['status']; companyId?: string; after?: unknown }) {
    return paginate(
      this.licenses.filter((l) => (!status || l.status === status) && (!companyId || l.companyId === companyId)).sort((a, b) => a.validUntil - b.validUntil),
      after,
    )
  }

  async getLicense(companyId: string, licenseId: string) {
    return this.licenses.find((l) => l.companyId === companyId && l.id === licenseId) ?? null
  }

  async listDevices({ status, companyId, licenseId, after }: { status?: Device['status']; companyId?: string; licenseId?: string; after?: unknown }) {
    return paginate(
      this.devices.filter((d) => (!status || d.status === status) && (!companyId || d.companyId === companyId) && (!licenseId || d.licenseId === licenseId)),
      after,
    )
  }

  async getDevice(companyId: string, deviceId: string) {
    return this.devices.find((d) => d.companyId === companyId && d.id === deviceId) ?? null
  }

  addRequest(r: Partial<ReplacementRequest> & { companyId: string; licenseId: string; requestedBy: string }): ReplacementRequest {
    const req: ReplacementRequest = {
      id: `req${++this.seq}`,
      companyName: this.companies.find((c) => c.id === r.companyId)?.name ?? null,
      newDeviceId: `new${this.seq}`,
      newDeviceModel: 'android 15',
      requesterEmail: `${r.requestedBy}@x.in`,
      reason: 'Phone damaged',
      status: 'pending',
      createdAt: Date.now() - this.seq,
      reviewReason: null,
      revokedDeviceId: null,
      ...r,
    }
    this.requests.push(req)
    return req
  }

  async listReplacementRequests({ status, after }: { status?: ReplacementRequest['status']; after?: unknown }) {
    return paginate(this.requests.filter((r) => !status || r.status === status), after)
  }

  async reviewReplacement(input: { companyId: string; requestId: string; decision: 'approve' | 'reject'; reason: string; revokeDeviceId?: string }) {
    this.require('devices.revoke')
    const r = this.requests.find((x) => x.id === input.requestId)!
    if (r.status !== 'pending') throw new Error(`This request was already ${r.status}.`)
    const l = (await this.getLicense(r.companyId, r.licenseId))!
    if (input.decision === 'approve') {
      const active = this.devices.filter((d) => d.licenseId === l.id && d.status === 'active')
      if (active.length - (input.revokeDeviceId ? 1 : 0) + 1 > l.maxDevices) throw new Error('The license is full. Choose which phone this one replaces.')
      if (input.revokeDeviceId) Object.assign(this.devices.find((d) => d.id === input.revokeDeviceId)!, { status: 'revoked', replacedBy: r.newDeviceId })
      this.addDevice({ id: r.newDeviceId, companyId: r.companyId, licenseId: l.id, userId: r.requestedBy, replacementForDeviceId: input.revokeDeviceId ?? null })
    }
    Object.assign(r, { status: input.decision === 'approve' ? 'approved' : 'rejected', reviewReason: input.reason, revokedDeviceId: input.revokeDeviceId ?? null })
    this.log(`replacement.${input.decision}`, { companyId: r.companyId, licenseId: l.id, deviceId: r.newDeviceId, reason: input.reason })
  }

  async listEvents({ companyId, licenseId, deviceId, type, after }: { companyId?: string; licenseId?: string; deviceId?: string; type?: string; after?: unknown }) {
    return paginate(
      this.events.filter((e) => (!companyId || e.companyId === companyId) && (!licenseId || e.licenseId === licenseId) && (!deviceId || e.deviceId === deviceId) && (!type || e.type === type)),
      after,
    )
  }

  async setCompanyStatus(companyId: string, status: Company['status'], reason: string) {
    this.require('companies.manage')
    const c = this.companies.find((x) => x.id === companyId)!
    this.log('company.status', { companyId, reason, details: { from: c.status, to: status } })
    c.status = status
  }

  async createCompany(p: CompanyProfile & { ownerEmail: string }) {
    this.require('companies.manage')
    const { ownerEmail: _, ...profile } = p
    const c = this.addCompany({ ...profile, status: 'active' })
    this.log('company.create', { companyId: c.id, details: { name: c.name } })
    return { companyId: c.id, newUser: true }
  }

  async updateCompany(companyId: string, profile: CompanyProfile) {
    this.require('companies.manage')
    Object.assign(this.companies.find((c) => c.id === companyId)!, profile)
    this.log('company.update', { companyId, details: { changed: { name: {} } } })
  }

  async createLicense(input: { companyId: string; validFrom: number; validUntil: number; maxDevices: number }) {
    this.require('licenses.manage')
    const l = this.addLicense(input)
    const activationCode = `JCBW-TEST-CODE-${String(this.seq).padStart(4, '0')}`
    this.issuedCodes.push(activationCode)
    this.log('license.create', { companyId: input.companyId, licenseId: l.id })
    return { licenseId: l.id, activationCode }
  }

  async setLicenseStatus(companyId: string, licenseId: string, status: 'active' | 'suspended' | 'revoked', reason: string) {
    this.require('licenses.manage')
    const l = (await this.getLicense(companyId, licenseId))!
    this.log('license.status', { companyId, licenseId, reason, details: { from: l.status, to: status } })
    l.status = status
  }

  async updateLicense(companyId: string, licenseId: string, changes: { validUntil?: number; maxDevices?: number }, reason: string) {
    this.require('licenses.manage')
    const l = (await this.getLicense(companyId, licenseId))!
    const active = this.devices.filter((d) => d.licenseId === licenseId && d.status === 'active').length
    if (changes.maxDevices !== undefined && changes.maxDevices < active) {
      throw new Error(`${active} devices are active. Revoke some before lowering the limit to ${changes.maxDevices}.`)
    }
    Object.assign(l, changes)
    this.log('license.update', { companyId, licenseId, reason, details: { changed: changes } })
  }

  async rotateActivationCode(companyId: string, licenseId: string, reason: string) {
    this.require('licenses.manage')
    const activationCode = `JCBW-NEWC-ODE0-${String(++this.seq).padStart(4, '0')}`
    this.log('license.rotate_code', { companyId, licenseId, reason })
    return { activationCode }
  }

  async revokeDevice(companyId: string, deviceId: string, reason: string) {
    this.require('devices.revoke')
    const d = (await this.getDevice(companyId, deviceId))!
    d.status = 'revoked'
    d.revokeReason = reason
    this.log('device.revoke', { companyId, deviceId, licenseId: d.licenseId, reason })
  }
}
