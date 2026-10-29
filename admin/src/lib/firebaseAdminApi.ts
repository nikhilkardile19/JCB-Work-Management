import type { FirebaseApp } from 'firebase/app'
import type { Auth } from 'firebase/auth'
import {
  collection,
  collectionGroup,
  doc,
  getCountFromServer,
  getDoc,
  getDocs,
  getFirestore,
  limit,
  orderBy,
  query,
  startAfter,
  Timestamp,
  where,
  type DocumentData,
  type DocumentSnapshot,
  type QueryConstraint,
} from 'firebase/firestore'
import { getFunctions, httpsCallable } from 'firebase/functions'
import {
  EXPIRING_DAYS,
  PAGE_SIZE,
  type AdminApi,
  type AdminPermission,
  type AuditEvent,
  type Company,
  type Cursor,
  type Device,
  type License,
  type Page,
  type ReplacementRequest,
} from './adminApi'

const ms = (v: unknown): number | null => (v instanceof Timestamp ? v.toMillis() : typeof v === 'number' ? v : null)

function toCompany(d: DocumentSnapshot<DocumentData>): Company {
  const x = d.data()!
  return {
    id: d.id,
    name: x.name,
    contactPerson: x.contactPerson,
    phone: x.phone,
    address: x.address,
    invoicePrefix: x.invoicePrefix,
    email: x.email ?? null,
    gstin: x.gstin ?? null,
    status: x.status,
    ownerUid: x.ownerUid,
    createdAt: ms(x.createdAt),
  }
}

function toLicense(d: DocumentSnapshot<DocumentData>): License {
  const x = d.data()!
  return {
    id: d.id,
    companyId: x.companyId ?? d.ref.parent.parent!.id,
    companyName: x.companyName ?? null,
    status: x.status,
    validFrom: ms(x.validFrom) ?? 0,
    validUntil: ms(x.validUntil) ?? 0,
    maxDevices: x.maxDevices,
    lastValidatedAt: ms(x.lastValidatedAt),
  }
}

function toDevice(d: DocumentSnapshot<DocumentData>): Device {
  const x = d.data()!
  return {
    id: d.id,
    companyId: x.companyId ?? d.ref.parent.parent!.id,
    licenseId: x.licenseId,
    userId: x.userId,
    deviceModel: x.deviceModel ?? null,
    status: x.status,
    activatedAt: ms(x.activatedAt),
    lastSeenAt: ms(x.lastSeenAt),
    revokeReason: x.revokeReason ?? null,
    replacementForDeviceId: x.replacementForDeviceId ?? null,
    replacedBy: x.replacedBy ?? null,
  }
}

function toRequest(d: DocumentSnapshot<DocumentData>): ReplacementRequest {
  const x = d.data()!
  return {
    id: d.id,
    companyId: x.companyId ?? d.ref.parent.parent!.id,
    companyName: x.companyName ?? null,
    licenseId: x.licenseId,
    newDeviceId: x.newDeviceId,
    newDeviceModel: x.newDeviceModel ?? null,
    requestedBy: x.requestedBy,
    requesterEmail: x.requesterEmail ?? null,
    reason: x.reason,
    status: x.status,
    createdAt: ms(x.createdAt),
    reviewReason: x.reviewReason ?? null,
    revokedDeviceId: x.revokedDeviceId ?? null,
  }
}

function toEvent(d: DocumentSnapshot<DocumentData>): AuditEvent {
  const { type, actorId, companyId, licenseId, deviceId, reason, at, ...details } = d.data()!
  return {
    id: d.id,
    type,
    actorId: actorId ?? details.uid ?? null,
    companyId: companyId ?? null,
    licenseId: licenseId ?? null,
    deviceId: deviceId ?? null,
    reason: reason ?? null,
    at: ms(at),
    details,
  }
}

/** Firestore reads + Cloud Function writes (region asia-south1). */
export function createFirebaseAdminApi(app: FirebaseApp, auth: Auth): AdminApi {
  const db = getFirestore(app)
  const fns = getFunctions(app, 'asia-south1')
  const call = async <T>(name: string, data: unknown): Promise<T> => {
    try {
      return (await httpsCallable(fns, name)(data)).data as T
    } catch (e) {
      throw new Error((e as { message?: string }).message ?? 'The server refused this action.')
    }
  }

  async function page<T>(base: ReturnType<typeof collection> | ReturnType<typeof collectionGroup>, constraints: QueryConstraint[], after: Cursor | undefined, map: (d: DocumentSnapshot) => T): Promise<Page<T>> {
    const q = query(base, ...constraints, ...(after ? [startAfter(after as DocumentSnapshot)] : []), limit(PAGE_SIZE))
    const snap = await getDocs(q)
    return { items: snap.docs.map(map), next: snap.docs.length === PAGE_SIZE ? snap.docs[snap.docs.length - 1] : null }
  }

  const count = async (q: Parameters<typeof getCountFromServer>[0]) => (await getCountFromServer(q)).data().count

  return {
    async me() {
      const uid = auth.currentUser?.uid
      if (!uid) throw new Error('Not signed in')
      const d = (await getDoc(doc(db, 'developerAdmins', uid))).data() ?? {}
      return {
        uid,
        email: auth.currentUser?.email ?? null,
        role: d.role === 'super' ? 'super' : 'support',
        permissions: (d.permissions ?? []) as AdminPermission[],
      }
    },

    async metrics() {
      const companies = collection(db, 'companies')
      const licenses = collectionGroup(db, 'licenses')
      const soon = Timestamp.fromMillis(Date.now() + EXPIRING_DAYS * 86_400_000)
      const [pending, active, suspended, lActive, lSoon, lExpired, lSuspended, devices, requests] = await Promise.all([
        count(query(companies, where('status', '==', 'pending'))),
        count(query(companies, where('status', '==', 'active'))),
        count(query(companies, where('status', '==', 'suspended'))),
        count(query(licenses, where('status', '==', 'active'))),
        count(query(licenses, where('status', '==', 'active'), where('validUntil', '<=', soon))),
        count(query(licenses, where('status', '==', 'expired'))),
        count(query(licenses, where('status', '==', 'suspended'))),
        count(query(collectionGroup(db, 'authorizedDevices'), where('status', '==', 'active'))),
        count(query(collectionGroup(db, 'deviceReplacementRequests'), where('status', '==', 'pending'))),
      ])
      return {
        companies: { pending, active, suspended },
        licenses: { active: lActive, expiringSoon: lSoon, expired: lExpired, suspended: lSuspended },
        activeDevices: devices,
        pendingRequests: requests,
      }
    },

    listCompanies({ status, search, after }) {
      const c: QueryConstraint[] = status ? [where('status', '==', status)] : []
      const term = search?.trim().toLowerCase()
      if (term) c.push(orderBy('nameLower'), where('nameLower', '>=', term), where('nameLower', '<=', `${term}`))
      else c.push(orderBy('createdAt', 'desc'))
      return page(collection(db, 'companies'), c, after, toCompany)
    },

    async getCompany(id) {
      const d = await getDoc(doc(db, 'companies', id))
      return d.exists() ? toCompany(d) : null
    },

    async companyMembers(id) {
      const snap = await getDocs(collection(db, 'companies', id, 'companyUsers'))
      return snap.docs.map((d) => ({ uid: d.id, email: d.get('email') ?? null, role: d.get('role'), status: d.get('status') }))
    },

    listLicenses({ status, companyId, after }) {
      const base = companyId ? collection(db, 'companies', companyId, 'licenses') : collectionGroup(db, 'licenses')
      return page(base, [...(status ? [where('status', '==', status)] : []), orderBy('validUntil')], after, toLicense)
    },

    async getLicense(companyId, licenseId) {
      const d = await getDoc(doc(db, 'companies', companyId, 'licenses', licenseId))
      return d.exists() ? toLicense(d) : null
    },

    listDevices({ status, companyId, licenseId, after }) {
      const base = companyId ? collection(db, 'companies', companyId, 'authorizedDevices') : collectionGroup(db, 'authorizedDevices')
      const c: QueryConstraint[] = [
        ...(licenseId ? [where('licenseId', '==', licenseId)] : []),
        ...(status ? [where('status', '==', status)] : []),
        ...(licenseId ? [] : [orderBy('lastSeenAt', 'desc')]),
      ]
      return page(base, c, after, toDevice)
    },

    async getDevice(companyId, deviceId) {
      const d = await getDoc(doc(db, 'companies', companyId, 'authorizedDevices', deviceId))
      return d.exists() ? toDevice(d) : null
    },

    listReplacementRequests({ status, after }) {
      const c: QueryConstraint[] = [...(status ? [where('status', '==', status)] : []), orderBy('createdAt', 'desc')]
      return page(collectionGroup(db, 'deviceReplacementRequests'), c, after, toRequest)
    },

    listEvents({ companyId, licenseId, deviceId, type, after }) {
      const c: QueryConstraint[] = []
      if (companyId) c.push(where('companyId', '==', companyId))
      if (licenseId) c.push(where('licenseId', '==', licenseId))
      if (deviceId) c.push(where('deviceId', '==', deviceId))
      if (type) c.push(where('type', '==', type))
      c.push(orderBy('at', 'desc'))
      return page(collection(db, 'auditEvents'), c, after, toEvent)
    },

    async setCompanyStatus(companyId, status, reason) {
      await call('setCompanyStatus', { companyId, status, reason })
    },
    createCompany: (input) => call('adminCreateCompany', input),
    async updateCompany(companyId, profile) {
      await call('adminUpdateCompany', { companyId, ...profile })
    },
    createLicense: (input) => call('createLicense', input),
    async setLicenseStatus(companyId, licenseId, status, reason) {
      await call('setLicenseStatus', { companyId, licenseId, status, reason })
    },
    async updateLicense(companyId, licenseId, changes, reason) {
      await call('updateLicense', { companyId, licenseId, ...changes, reason })
    },
    rotateActivationCode: (companyId, licenseId, reason) => call('rotateActivationCode', { companyId, licenseId, reason }),
    async revokeDevice(companyId, deviceId, reason) {
      await call('revokeDevice', { companyId, deviceId, reason })
    },
    async reviewReplacement(input) {
      await call('reviewReplacement', input)
    },
  }
}
