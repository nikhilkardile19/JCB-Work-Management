import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing'
import {
  collectionGroup,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore'
import { readFileSync } from 'node:fs'
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest'

let env

const profile = {
  name: 'Sai Earthmovers',
  contactPerson: 'Ravi Patil',
  phone: '9876543210',
  email: null,
  address: 'Plot 4, MIDC, Pune',
  gstin: null,
  invoicePrefix: 'SAI',
}

function companyDoc(id, uid, overrides = {}) {
  return {
    ...profile,
    id,
    currency: 'INR',
    status: 'pending',
    ownerUid: uid,
    createdBy: uid,
    updatedBy: uid,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    schemaVersion: 1,
    ...overrides,
  }
}

function ownerMember(id, uid, overrides = {}) {
  return {
    uid,
    companyId: id,
    email: `${uid}@x.in`,
    role: 'owner',
    status: 'active',
    createdAt: serverTimestamp(),
    ...overrides,
  }
}

/** The batch the mobile app sends on registration. */
function registerBatch(db, id, uid, { company = {}, member = {} } = {}) {
  const batch = writeBatch(db)
  batch.set(doc(db, 'companies', id), companyDoc(id, uid, company))
  batch.set(doc(db, 'companies', id, 'companyUsers', uid), ownerMember(id, uid, member))
  return batch.commit()
}

const as = (uid) => env.authenticatedContext(uid).firestore()

/** Seeds an existing company with members, bypassing rules. */
async function seedCompany(id, { status = 'active', members = { alice: 'owner' } } = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore()
    const owner = Object.keys(members)[0]
    await setDoc(doc(db, 'companies', id), { ...companyDoc(id, owner), status, createdAt: new Date(), updatedAt: new Date() })
    for (const [uid, role] of Object.entries(members)) {
      await setDoc(doc(db, 'companies', id, 'companyUsers', uid), {
        ...ownerMember(id, uid),
        role,
        createdAt: new Date(),
      })
    }
  })
}

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-jcb-rules',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  })
})

afterAll(() => env.cleanup())
beforeEach(() => env.clearFirestore())

describe('company registration', () => {
  it('lets a signed-in user register a pending company as owner', async () => {
    await assertSucceeds(registerBatch(as('alice'), 'c1', 'alice'))
  })

  it('rejects unauthenticated registration', async () => {
    const db = env.unauthenticatedContext().firestore()
    await assertFails(registerBatch(db, 'c1', 'alice'))
  })

  it('rejects a company created already active', async () => {
    await assertFails(registerBatch(as('alice'), 'c1', 'alice', { company: { status: 'active' } }))
  })

  it('rejects a company owned by someone else', async () => {
    await assertFails(registerBatch(as('mallory'), 'c1', 'alice'))
  })

  it('rejects a company without the owner membership in the same batch', async () => {
    await assertFails(setDoc(doc(as('alice'), 'companies', 'c1'), companyDoc('c1', 'alice')))
  })

  it('accepts a matching lower-case search name and rejects a mismatched one', async () => {
    await assertSucceeds(registerBatch(as('alice'), 'c1', 'alice', { company: { nameLower: 'sai earthmovers' } }))
    await assertFails(registerBatch(as('bob'), 'c2', 'bob', { company: { nameLower: 'someone else' } }))
  })

  it('rejects a mismatched company id, unknown fields and invalid profiles', async () => {
    await assertFails(registerBatch(as('alice'), 'c1', 'alice', { company: { id: 'c2' } }))
    await assertFails(registerBatch(as('alice'), 'c1', 'alice', { company: { licenseStatus: 'active' } }))
    await assertFails(registerBatch(as('alice'), 'c1', 'alice', { company: { invoicePrefix: 'bad/prefix' } }))
    await assertFails(registerBatch(as('alice'), 'c1', 'alice', { company: { name: 'x' } }))
  })

  it('rejects registering with a non-owner or inactive role', async () => {
    await assertFails(registerBatch(as('alice'), 'c1', 'alice', { member: { role: 'admin' } }))
    await assertFails(registerBatch(as('alice'), 'c1', 'alice', { member: { status: 'pending' } }))
  })
})

describe('membership cannot be self-granted', () => {
  it('blocks joining an existing company as owner', async () => {
    await seedCompany('c1')
    await assertFails(setDoc(doc(as('mallory'), 'companies', 'c1', 'companyUsers', 'mallory'), ownerMember('c1', 'mallory')))
  })

  it('blocks changing your own role', async () => {
    await seedCompany('c1', { members: { alice: 'owner', bob: 'operator' } })
    await assertFails(updateDoc(doc(as('bob'), 'companies', 'c1', 'companyUsers', 'bob'), { role: 'admin' }))
    await assertFails(deleteDoc(doc(as('bob'), 'companies', 'c1', 'companyUsers', 'bob')))
  })
})

describe('tenant isolation', () => {
  beforeEach(async () => {
    await seedCompany('a', { members: { alice: 'owner' } })
    await seedCompany('b', { members: { bob: 'owner' } })
  })

  it('members read their own company', async () => {
    await assertSucceeds(getDoc(doc(as('alice'), 'companies', 'a')))
  })

  it('company A user cannot read or write company B', async () => {
    await assertFails(getDoc(doc(as('alice'), 'companies', 'b')))
    await assertFails(getDoc(doc(as('alice'), 'companies', 'b', 'companyUsers', 'bob')))
    await assertFails(updateDoc(doc(as('alice'), 'companies', 'b'), { name: 'Hijacked Co', updatedBy: 'alice', updatedAt: serverTimestamp() }))
  })

  it('membership lookup only returns your own memberships', async () => {
    await assertSucceeds(getDocs(query(collectionGroup(as('alice'), 'companyUsers'), where('uid', '==', 'alice'))))
    await assertFails(getDocs(query(collectionGroup(as('alice'), 'companyUsers'), where('uid', '==', 'bob'))))
    await assertFails(getDocs(collectionGroup(as('alice'), 'companyUsers')))
  })

  it('invoice counters and issued numbers are server-only', async () => {
    await assertFails(getDoc(doc(as('alice'), 'companies', 'a', 'counters', 'invoices-2026-27')))
    await assertFails(setDoc(doc(as('alice'), 'companies', 'a', 'counters', 'invoices-2026-27'), { last: 0 }))
    await assertFails(setDoc(doc(as('alice'), 'companies', 'a', 'invoiceNumbers', 'x'), { invoiceNumber: 'SAI/2026-27/0001' }))
  })

  it('unknown collections are denied by default', async () => {
    await assertFails(setDoc(doc(as('alice'), 'companies', 'a', 'clients', 'x'), { name: 'x' }))
    await assertFails(getDoc(doc(as('alice'), 'licenses', 'x')))
  })
})

describe('company profile updates', () => {
  beforeEach(() => seedCompany('c1', { members: { alice: 'owner', olga: 'operator', adam: 'admin' } }))

  it('a pending owner cannot activate their own company', async () => {
    await seedCompany('p1', { status: 'pending', members: { pat: 'owner' } })
    await assertFails(updateDoc(doc(as('pat'), 'companies', 'p1'), { status: 'active', updatedBy: 'pat', updatedAt: serverTimestamp() }))
  })

  const edit = (uid, extra = {}) =>
    updateDoc(doc(as(uid), 'companies', 'c1'), { name: 'Sai Infra', updatedBy: uid, updatedAt: serverTimestamp(), ...extra })

  it('owner and admin can edit profile fields', async () => {
    await assertSucceeds(edit('alice'))
    await assertSucceeds(edit('adam'))
  })

  it('operators cannot edit the company', async () => {
    await assertFails(edit('olga'))
  })

  it('nobody can self-approve or change owner, id or currency', async () => {
    await assertFails(edit('alice', { status: 'suspended' }))
    await assertFails(edit('alice', { ownerUid: 'mallory' }))
    await assertFails(edit('alice', { id: 'other' }))
    await assertFails(edit('alice', { currency: 'USD' }))
  })

  it('companies cannot be deleted by clients', async () => {
    await assertFails(deleteDoc(doc(as('alice'), 'companies', 'c1')))
  })

  it('suspended members lose access', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'companies', 'c1', 'companyUsers', 'olga'), { status: 'disabled' }),
    )
    await assertFails(getDoc(doc(as('olga'), 'companies', 'c1')))
  })
})

describe('developer admins', () => {
  beforeEach(async () => {
    await seedCompany('c1')
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'developerAdmins', 'dev'), { email: 'dev@x.in' }))
  })

  it('admins can read any company; others cannot', async () => {
    await assertSucceeds(getDoc(doc(as('dev'), 'companies', 'c1')))
    await assertFails(getDoc(doc(as('mallory'), 'companies', 'c1')))
  })

  it('can read only their own admin doc', async () => {
    await assertSucceeds(getDoc(doc(as('dev'), 'developerAdmins', 'dev')))
    await assertSucceeds(getDoc(doc(as('mallory'), 'developerAdmins', 'mallory')))
    await assertFails(getDoc(doc(as('mallory'), 'developerAdmins', 'dev')))
  })

  it('no client can make itself a developer admin', async () => {
    await assertFails(setDoc(doc(as('mallory'), 'developerAdmins', 'mallory'), { email: 'm@x.in' }))
    await assertFails(setDoc(doc(as('dev'), 'developerAdmins', 'mallory'), { email: 'm@x.in' }))
  })

  it('only admins can read server audit events; nobody can write them', async () => {
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'auditEvents', 'e1'), { type: 'device.activate' }))
    await assertSucceeds(getDoc(doc(as('dev'), 'auditEvents', 'e1')))
    await assertFails(getDoc(doc(as('mallory'), 'auditEvents', 'e1')))
    await assertFails(setDoc(doc(as('dev'), 'auditEvents', 'e2'), { type: 'fake' }))
  })

  it('admins can list licenses and devices across companies', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'companies', 'c1', 'licenses', 'l1'), { status: 'active' })
      await setDoc(doc(ctx.firestore(), 'companies', 'c1', 'authorizedDevices', 'd1'), { status: 'active' })
    })
    await assertSucceeds(getDocs(collectionGroup(as('dev'), 'licenses')))
    await assertSucceeds(getDocs(collectionGroup(as('dev'), 'authorizedDevices')))
    await assertSucceeds(getDocs(collectionGroup(as('dev'), 'companyUsers')))
    await assertFails(getDocs(collectionGroup(as('alice'), 'licenses')))
    await assertFails(getDocs(collectionGroup(as('alice'), 'authorizedDevices')))
    await assertSucceeds(getDocs(collectionGroup(as('dev'), 'deviceReplacementRequests')))
  })

  it('admins cannot approve companies directly from the client (Cloud Functions only)', async () => {
    await assertFails(updateDoc(doc(as('dev'), 'companies', 'c1'), { status: 'active' }))
  })
})
