import type { Db } from '../../src/database/prisma.js'
import type { CompanyRole, CompanyStatus, LicenseStatus } from '../../src/generated/prisma/client.js'
import { hashPassword } from '../../src/modules/auth/passwords.js'
import { hashCode } from '../../src/modules/licenses/activationCodes.js'
import type { TestEnv } from './testApp.js'

export const DAY = 86_400_000
export const PASSWORD = 'correct horse battery'

let hashed: Promise<string> | null = null
const passwordHash = () => (hashed ??= hashPassword(PASSWORD))

export async function createUser(db: Db, id: string, opts: { email?: string; password?: boolean; disabled?: boolean } = {}) {
  return db.user.create({
    data: {
      id,
      email: opts.email ?? `${id}@example.test`,
      passwordHash: opts.password === false ? null : await passwordHash(),
      status: opts.disabled ? 'disabled' : 'active',
    },
  })
}

export const PROFILE = {
  name: 'Sai Earthmovers',
  contactPerson: 'Ravi Kumar',
  phone: '9876543210',
  address: '12 MG Road, Pune',
  invoicePrefix: 'SAI',
  email: 'office@sai.example',
  gstin: null,
}

/** The roles used by the ported rules tests. */
export const MEMBERS: Record<string, CompanyRole> = {
  owner: 'owner',
  admin: 'admin',
  mgr: 'manager',
  op: 'operator',
  op2: 'operator',
  acc: 'accounts',
}

/**
 * A company with a license, members (users named after their keys) and one
 * active device per member (`dev-<uid>`), like the old rules tests' seed.
 */
export async function seedCompany(
  db: Db,
  {
    id = 'co',
    status = 'active' as CompanyStatus,
    members = MEMBERS,
    licenseStatus = 'active' as LicenseStatus,
    activationCode = 'JCBW-AAAA-BBBB-CCCC',
    maxDevices = 10,
    devices = true,
  } = {},
) {
  for (const uid of Object.keys(members)) {
    if (!(await db.user.findUnique({ where: { id: uid } }))) await createUser(db, uid)
  }
  const owner = Object.entries(members).find(([, r]) => r === 'owner')?.[0] ?? Object.keys(members)[0]
  await db.company.create({ data: { id, ...PROFILE, status, ownerUserId: owner } })
  for (const [userId, role] of Object.entries(members)) {
    await db.companyMember.create({ data: { companyId: id, userId, role, status: 'active' } })
  }
  const now = Date.now()
  await db.license.create({
    data: {
      id: `lic-${id}`,
      companyId: id,
      status: licenseStatus,
      validFrom: new Date(now - DAY),
      validUntil: new Date(now + 365 * DAY),
      maxDevices,
      activationCodeHash: hashCode(activationCode),
    },
  })
  if (devices) {
    for (const uid of Object.keys(members)) {
      await db.device.create({
        data: { companyId: id, id: `dev-${uid}`, licenseId: `lic-${id}`, userId: uid, status: 'active', activatedAt: new Date() },
      })
    }
  }
  return { companyId: id, licenseId: `lic-${id}`, activationCode }
}

/** Signs in and returns an access token. */
export async function tokenFor(env: TestEnv, uid: string, client: 'mobile' | 'portal' = 'mobile') {
  const user = await env.db.user.findUniqueOrThrow({ where: { id: uid } })
  const res = await env.request.post('/api/v1/auth/login').send({ email: user.email, password: PASSWORD, client })
  if (res.status !== 200) throw new Error(`login failed for ${uid}: ${res.status} ${JSON.stringify(res.body)}`)
  return res.body.accessToken as string
}

/** Cached tokens per test (sign-in costs an Argon2 verification). */
export function tokens(env: TestEnv) {
  const cache = new Map<string, Promise<string>>()
  return (uid: string) => {
    if (!cache.has(uid)) cache.set(uid, tokenFor(env, uid))
    return cache.get(uid)!
  }
}
