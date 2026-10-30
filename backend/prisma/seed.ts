/**
 * Development data only — never real people or credentials. Refuses to run in
 * production. Prints the sign-in details and the activation code.
 *
 *   npm run db:seed            (SEED_PASSWORD overrides the default password)
 */
import { loadConfig } from '../src/config/env.js'
import { createPrisma, type Tx } from '../src/database/prisma.js'
import { hashPassword } from '../src/modules/auth/passwords.js'
import { hashCode } from '../src/modules/licenses/activationCodes.js'
import { saveRecord, type CollectionName } from '../src/modules/sync/collections.js'

const config = loadConfig()
if (config.NODE_ENV === 'production') throw new Error('Refusing to seed a production database.')
const db = createPrisma(config.DATABASE_URL, 2)
const password = process.env.SEED_PASSWORD ?? 'jcb-dev-password'
const ACTIVATION_CODE = 'JCBW-DEVA-CODE-2026'
const CO = 'demo-company'
const DAY = 86_400_000

const users = [
  { id: 'dev-admin', email: 'admin@jcb.local' },
  { id: 'demo-owner', email: 'owner@jcb.local' },
  { id: 'demo-operator', email: 'operator@jcb.local' },
  { id: 'demo-accounts', email: 'accounts@jcb.local' },
]

try {
  const passwordHash = await hashPassword(password)
  for (const u of users) {
    await db.user.upsert({ where: { id: u.id }, create: { ...u, passwordHash }, update: { passwordHash } })
  }
  await db.developerAdmin.upsert({ where: { userId: 'dev-admin' }, create: { userId: 'dev-admin', role: 'super' }, update: {} })
  await db.company.upsert({
    where: { id: CO },
    create: {
      id: CO,
      name: 'Demo Earthmovers',
      contactPerson: 'Demo Owner',
      phone: '9000000000',
      address: '1 Demo Road, Pune',
      invoicePrefix: 'DEMO',
      status: 'active',
      ownerUserId: 'demo-owner',
    },
    update: {},
  })
  const roles = { 'demo-owner': 'owner', 'demo-operator': 'operator', 'demo-accounts': 'accounts' } as const
  for (const [userId, role] of Object.entries(roles)) {
    await db.companyMember.upsert({ where: { companyId_userId: { companyId: CO, userId } }, create: { companyId: CO, userId, role }, update: {} })
  }
  const now = Date.now()
  await db.license.upsert({
    where: { id: 'demo-license' },
    create: {
      id: 'demo-license',
      companyId: CO,
      status: 'active',
      validFrom: new Date(now - DAY),
      validUntil: new Date(now + 365 * DAY),
      maxDevices: 5,
      activationCodeHash: hashCode(ACTIVATION_CODE),
    },
    update: {},
  })

  const base = { companyId: CO, notes: null, isActive: true, createdAt: now, updatedAt: now, deletedAt: null, createdBy: 'demo-owner', updatedBy: 'demo-owner', version: 1 }
  const masters: [CollectionName, Record<string, unknown>][] = [
    ['clients', { ...base, id: 'demo-client', name: 'Patil Constructions', contactPerson: null, phone: null, email: null, billingAddress: null, gstin: null }],
    ['sites', { ...base, id: 'demo-site', clientId: 'demo-client', name: 'Hinjewadi Phase 3', address: null, contactPerson: null, phone: null, defaultHourlyRatePaise: 150000 }],
    ['machines', { ...base, id: 'demo-machine', name: 'JCB 3DX #1', registrationNumber: null, serialNumber: null, model: '3DX', initialMeterReading: 120000, meterUnit: 'hours' }],
    ['operators', { ...base, id: 'demo-operator-master', name: 'Suresh', phone: null, code: null }],
    ['petrolPumps', { ...base, id: 'demo-pump', name: 'HP Highway Pump', phone: null, address: null }],
  ]
  // Masters go through the sync tables so phones download them; seed once.
  const seeded = await db.client.findFirst({ where: { companyId: CO } })
  await db.$transaction(async (tx) => {
    for (const [collection, data] of seeded ? [] : masters) {
      const [row] = await tx.$queryRaw<{ seq: bigint }[]>`
        INSERT INTO company_sync_state (company_id, seq) VALUES (${CO}, 1)
        ON CONFLICT (company_id) DO UPDATE SET seq = company_sync_state.seq + 1 RETURNING seq`
      await saveRecord(tx as Tx, collection, data, { rev: 1, syncSeq: row.seq, serverUpdatedAt: new Date(), pushedBy: 'demo-owner', deviceId: null })
    }
  })
  console.log('Seeded development data. Password for every account:', password)
  for (const u of users) console.log(`  ${u.email}`)
  console.log('Company "Demo Earthmovers" activation code:', ACTIVATION_CODE)
} finally {
  await db.$disconnect()
}
