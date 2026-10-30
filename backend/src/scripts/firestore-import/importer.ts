import type { Db, Tx } from '../../database/prisma.js'
import { prismaCode } from '../../database/prisma.js'
import type { AdminRole, CompanyRole } from '../../generated/prisma/client.js'
import { emailSchema, idSchema, z } from '../../lib/validation.js'
import { ADMIN_PERMISSIONS } from '../../modules/admin/adminAccess.js'
import { CompanyProfileInput } from '../../modules/companies/companyProfile.js'
import { saveRecord, SCHEMAS, type CollectionName, type Json } from '../../modules/sync/collections.js'
import { AUTH_KIND, FatalImportError, FsTagged, FsTimestamp, readExport, type ExportData, type SourceDoc } from './exportReader.js'
import { reconcile, SYNC_ORDER, SYNC_TABLES, zeroTotals, type Totals } from './reconcile.js'
import { ImportReport, type ProblemCode } from './report.js'

/**
 * Loads a Firestore export (tools/firestore-export) into PostgreSQL.
 * Mapping: docs/migration/README.md ("Firestore → PostgreSQL mapping").
 *
 * Order: users → developer admins → per company, in one transaction each
 * (company → members → licenses → devices → replacement requests → issued
 * numbers / counters → clients, sites, machines, operators, petrol pumps →
 * work logs → fuel → invoices with lines → payments → audit logs) →
 * auditEvents. Every write is an upsert keyed by the Firestore IDs, so a
 * rerun of the same export changes nothing. Each record is written inside a
 * savepoint: one bad document is reported and skipped, never fatal.
 *
 * Synced records are validated with the same schemas the sync API uses
 * (`SCHEMAS`) after the sync metadata (`rev`, `serverUpdatedAt`, `pushedBy`,
 * `deviceId`) is taken off, and written with the API's own `saveRecord`.
 * `sync_seq` is assigned per company in (serverUpdatedAt, document ID) order,
 * the order the Firestore app pulled in, and `company_sync_state.seq` is set
 * to the highest value so new writes continue after it.
 */

const SYNC_META = ['rev', 'serverUpdatedAt', 'pushedBy', 'deviceId'] as const
/** Device-only Drift columns the app never uploads (removed if an old build did). */
const DEVICE_ONLY = ['syncStatus', 'startPhotoPath', 'endPhotoPath', 'receiptPhotoPath', 'pdfPath']

const K = {
  developerAdmins: 'developerAdmins',
  companies: 'companies',
  auditEvents: 'auditEvents',
  rateLimits: 'rateLimits',
  members: 'companies/*/companyUsers',
  licenses: 'companies/*/licenses',
  devices: 'companies/*/authorizedDevices',
  replacements: 'companies/*/deviceReplacementRequests',
  issued: 'companies/*/invoiceNumbers',
  counters: 'companies/*/counters',
} as const

const syncKind = (c: CollectionName) => `companies/*/${c}`
const COMPANY_KINDS = new Set<string>([K.members, K.licenses, K.devices, K.replacements, K.issued, K.counters, ...SYNC_ORDER.map(syncKind)])

// --- Schemas of the server-written documents (firebase/functions/src) --------

const ts = z.union([
  z.instanceof(FsTimestamp).transform((t) => t.toDate()),
  z.number().int().min(0).transform((n) => new Date(n)),
])
const optTs = ts.nullish()
const text = (max = 2000) => z.string().max(max)
const optText = (max = 2000) => text(max).nullish()
const ref = idSchema()

const authSchema = z.object({
  uid: z.string().optional(),
  email: z.string().nullish(),
  disabled: z.boolean().nullish(),
  createdAt: optTs,
  lastSignInAt: optTs,
})
const AUTH_FIELDS = ['uid', 'email', 'disabled', 'createdAt', 'lastSignInAt']
const AUTH_DROPPED = ['emailVerified', 'providerIds']

const adminSchema = z.object({
  role: z.string().nullish(),
  permissions: z.array(z.string()).nullish(),
  email: z.string().nullish(),
  createdAt: optTs,
  updatedAt: optTs,
})

const companySchema = z.object({
  id: z.string().optional(),
  name: text(500).min(1),
  contactPerson: text(500),
  phone: text(100),
  address: text(2000),
  invoicePrefix: text(40).min(1),
  email: optText(200),
  gstin: optText(40),
  currency: text(10).min(1).nullish(),
  status: z.enum(['pending', 'active', 'suspended']),
  ownerUid: ref,
  createdBy: optText(128),
  updatedBy: optText(128),
  createdAt: optTs,
  updatedAt: optTs,
})
const COMPANY_DROPPED = ['nameLower', 'schemaVersion']

const ROLES = ['owner', 'admin', 'manager', 'operator', 'accounts'] as const
const memberSchema = z.object({
  uid: z.string().optional(),
  companyId: z.string().optional(),
  email: z.unknown().optional(),
  role: z.enum(ROLES),
  status: z.enum(['active', 'disabled']),
  invitedBy: optText(128),
  createdAt: optTs,
  updatedAt: optTs,
})

const licenseSchema = z
  .object({
    licenseId: z.string().optional(),
    companyId: z.string().optional(),
    status: z.enum(['pending', 'active', 'suspended', 'expired', 'revoked']),
    validFrom: ts,
    validUntil: ts,
    maxDevices: z.number().int().min(1).max(100),
    activationCodeHash: text(200).min(1),
    lastValidatedAt: optTs,
    createdBy: optText(128),
    createdAt: optTs,
    updatedAt: optTs,
  })
  .refine((l) => l.validUntil > l.validFrom, { message: 'must be after validFrom', path: ['validUntil'] })
const LICENSE_DROPPED = ['companyName']

const deviceSchema = z.object({
  deviceId: z.string().optional(),
  companyId: z.string().optional(),
  licenseId: ref,
  userId: ref,
  deviceModel: optText(200),
  platform: text(40).nullish(),
  status: z.enum(['active', 'revoked']),
  activatedAt: optTs,
  lastSeenAt: optTs,
  revokedAt: optTs,
  revokedBy: optText(128),
  revokeReason: optText(),
  replacedBy: optText(128),
  replacementForDeviceId: optText(128),
})

const replacementSchema = z.object({
  requestId: z.string().optional(),
  companyId: z.string().optional(),
  licenseId: ref,
  newDeviceId: ref,
  newDeviceModel: optText(200),
  requestedBy: ref,
  reason: text(),
  status: z.enum(['pending', 'approved', 'rejected']),
  createdAt: optTs,
  reviewedBy: optText(128),
  reviewedAt: optTs,
  reviewReason: optText(),
  revokedDeviceId: optText(128),
})
const REPLACEMENT_DROPPED = ['companyName', 'requesterEmail']

const issuedSchema = z.object({
  invoiceNumber: text(60).min(1),
  financialYear: text(20).min(1),
  issuedBy: ref,
  issuedAt: optTs,
})

const counterSchema = z.object({ last: z.number().int().min(0).max(2_147_483_647), updatedAt: optTs })
const COUNTER_ID = /^invoices-(\d{4}-\d{2})$/

const syncMetaSchema = z.object({
  rev: z.number().int().min(1).max(2_147_483_647),
  serverUpdatedAt: z.instanceof(FsTimestamp, { message: 'must be a Firestore timestamp' }),
  pushedBy: ref,
  deviceId: z.string().min(1).max(128).nullish(),
})

const fieldsOf = (schema: z.ZodType) => Object.keys((schema as unknown as { shape: Record<string, unknown> }).shape ?? {})
const issues = (e: z.ZodError) =>
  e.issues
    .slice(0, 5)
    .map((i) => `${i.path.join('.') || 'document'}: ${i.message}`)
    .join('; ')

// --- Database helpers -------------------------------------------------------

type Attempt = { ok: true } | { ok: false; code: ProblemCode; message: string }

function classify(e: unknown): { code: ProblemCode; message: string } {
  const text = e instanceof Error ? e.message : String(e)
  const lines = text.split('\n').map((l) => l.trim()).filter(Boolean)
  const message = (lines.at(-1) ?? text).slice(0, 400)
  switch (prismaCode(e)) {
    case 'P2002':
      return { code: 'duplicate', message: `unique key already taken: ${message}` }
    case 'P2003':
      return { code: 'fk_violation', message: `reference refused by the database: ${message}` }
    default:
      return { code: 'db_constraint', message }
  }
}

/** Runs [fn] inside a savepoint; a database refusal rolls back only this record. */
async function attempt(tx: Tx, fn: () => Promise<unknown>): Promise<Attempt> {
  await tx.$executeRawUnsafe('SAVEPOINT import_record')
  try {
    await fn()
    await tx.$executeRawUnsafe('RELEASE SAVEPOINT import_record')
    return { ok: true }
  } catch (e) {
    await tx.$executeRawUnsafe('ROLLBACK TO SAVEPOINT import_record')
    return { ok: false, ...classify(e) }
  }
}

/** A Firestore value as plain JSON (for `audit_events.details`). */
function plainJson(v: unknown): unknown {
  if (v instanceof FsTimestamp) return v.toDate().toISOString()
  if (v instanceof FsTagged) return { __type: v.type, ...v.value }
  if (Array.isArray(v)) return v.map(plainJson)
  if (v && typeof v === 'object') return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, plainJson(x)]))
  return v
}

// --- Import state -------------------------------------------------------------

/** Keys written by one unit of work, merged into the run once it commits. */
class Written {
  readonly keys = new Map<string, Set<string>>()
  add(table: string, key: string) {
    const s = this.keys.get(table) ?? new Set<string>()
    s.add(key)
    this.keys.set(table, s)
  }
  has(table: string, key: string) {
    return this.keys.get(table)?.has(key) ?? false
  }
}

interface PlannedUser {
  id: string
  email: string
  status: 'active' | 'disabled'
  createdAt: Date
  lastLoginAt: Date | null
  /** The Auth export line, or null for a user known only from companyUsers/developerAdmins. */
  doc: SourceDoc | null
  from: string
}

interface Candidate {
  c: CollectionName
  doc: SourceDoc
  data: Json
  rev: number
  ts: FsTimestamp
  pushedBy: string
  deviceId: string | null
}

interface CompanyResult {
  written: Written
  totals: Totals
  imported: boolean
}

export class ImportRun {
  readonly written = new Written()
  readonly totals = new Map<string, Totals>()
  readonly importedCompanies = new Set<string>()
  readonly companyIds: string[]
  readonly exportedAt: Date

  private readonly companyDocs = new Map<string, SourceDoc>()
  private readonly byCompany = new Map<string, Map<string, SourceDoc[]>>()
  private readonly users = new Map<string, PlannedUser>()
  private readonly importedUsers = new Set<string>()
  private readonly unknownFields = new Map<string, { kind: string; field: string; count: number; sample: string }>()

  constructor(
    private readonly src: ExportData,
    readonly report: ImportReport,
    private readonly log: (m: string) => void,
  ) {
    this.exportedAt = src.exportedAt
    const ids = new Set<string>()
    for (const [kind, docs] of src.docs) {
      if (kind === K.companies) {
        for (const d of docs) {
          this.companyDocs.set(d.id, d)
          ids.add(d.id)
        }
      } else if (COMPANY_KINDS.has(kind)) {
        for (const d of docs) {
          const companyId = d.segments[1]
          ids.add(companyId)
          const group = this.byCompany.get(companyId) ?? new Map<string, SourceDoc[]>()
          group.set(kind, [...(group.get(kind) ?? []), d])
          this.byCompany.set(companyId, group)
        }
      } else if (kind === K.rateLimits) {
        for (const d of docs) report.settle(d, 'skipped')
        report.problem({
          severity: 'info',
          code: 'skipped_collection',
          kind,
          message: `${docs.length} rateLimits document(s) not migrated: abuse counters start empty in rate_limits.`,
        })
      } else if (kind !== AUTH_KIND && kind !== K.developerAdmins && kind !== K.auditEvents) {
        for (const d of docs) report.settle(d, 'skipped')
        report.problem({
          severity: 'warning',
          code: 'unmapped_collection',
          kind,
          message: `${docs.length} document(s) have no PostgreSQL table and were not imported (e.g. ${docs.slice(0, 3).map((d) => d.path).join(', ')}).`,
        })
      }
    }
    this.companyIds = [...ids].sort()
    this.rejectGlobalDuplicates(K.licenses, 'license')
    this.rejectGlobalDuplicates(K.replacements, 'replacement request')
    this.planUsers()
  }

  private docs(kind: string): SourceDoc[] {
    return this.src.docs.get(kind) ?? []
  }

  /** Licenses and replacement requests have a global primary key in PostgreSQL. */
  private rejectGlobalDuplicates(kind: string, what: string) {
    const first = new Map<string, SourceDoc>()
    for (const companyId of this.companyIds) {
      const group = this.byCompany.get(companyId)
      const list = group?.get(kind)
      if (!list) continue
      group!.set(
        kind,
        list.filter((d) => {
          const prior = first.get(d.id)
          if (!prior) {
            first.set(d.id, d)
            return true
          }
          this.report.reject(d, 'duplicate', `${what} ID ${d.id} is also used by ${prior.path}; IDs must be unique across companies.`, companyId)
          return false
        }),
      )
    }
  }

  private checkFields(doc: SourceDoc, known: string[], dropped: string[] = []) {
    for (const field of Object.keys(doc.data)) {
      if (dropped.includes(field)) {
        this.report.dropped(doc.kind, field)
      } else if (!known.includes(field)) {
        this.report.dropped(doc.kind, field)
        const key = `${doc.kind}\u0000${field}`
        const u = this.unknownFields.get(key) ?? { kind: doc.kind, field, count: 0, sample: doc.path }
        u.count++
        this.unknownFields.set(key, u)
      }
    }
  }

  private warn(doc: SourceDoc, code: ProblemCode, message: string) {
    this.report.problem({ severity: 'warning', code, kind: doc.kind, path: doc.path, companyId: doc.kind.startsWith('companies/') ? doc.segments[1] : undefined, message })
  }

  // --- Users --------------------------------------------------------------------

  private planUsers() {
    const r = this.report
    // Emails the app stored next to memberships / admin grants, by UID.
    const known = new Map<string, { email: string; doc: SourceDoc; createdAt: Date | null }[]>()
    for (const doc of [...this.docs(K.members), ...this.docs(K.developerAdmins)]) {
      if (doc.data.email == null) continue
      const e = emailSchema.safeParse(doc.data.email)
      if (!e.success) {
        this.warn(doc, 'invalid', `email ${JSON.stringify(doc.data.email)} is not a valid address; ignored.`)
        continue
      }
      const created = ts.safeParse(doc.data.createdAt)
      known.set(doc.id, [...(known.get(doc.id) ?? []), { email: e.data, doc, createdAt: created.success ? created.data : null }])
    }

    const authIds = new Set(this.docs(AUTH_KIND).map((d) => d.id))
    const emailOwner = new Map<string, string>()
    for (const doc of this.docs(AUTH_KIND)) {
      const p = authSchema.safeParse(doc.data)
      if (!p.success) {
        r.reject(doc, 'invalid', issues(p.error))
        continue
      }
      this.checkFields(doc, AUTH_FIELDS, AUTH_DROPPED)
      if (p.data.uid !== undefined && p.data.uid !== doc.id) this.warn(doc, 'id_mismatch', `uid field ${p.data.uid} differs from the line id; the id is used.`)
      const others = known.get(doc.id) ?? []
      let email: string | null = null
      if (p.data.email != null) {
        const e = emailSchema.safeParse(p.data.email)
        if (e.success) email = e.data
      }
      if (!email) {
        if (!others.length) {
          r.reject(doc, 'missing_email', 'Auth user has no usable email (and no companyUsers/developerAdmins email); a user row needs one.')
          continue
        }
        email = others[0].email
        this.warn(doc, 'missing_email', `Auth user has no usable email; using ${email} from ${others[0].doc.path}.`)
      } else {
        for (const o of others) {
          if (o.email !== email) this.warn(o.doc, 'email_mismatch', `email ${o.email} differs from the Auth email ${email}; the Auth email is used.`)
        }
      }
      const owner = emailOwner.get(email)
      if (owner) {
        r.reject(doc, 'duplicate', `email ${email} already belongs to Auth user ${owner}.`)
        continue
      }
      emailOwner.set(email, doc.id)
      this.users.set(doc.id, {
        id: doc.id,
        email,
        status: p.data.disabled ? 'disabled' : 'active',
        createdAt: p.data.createdAt ?? this.exportedAt,
        lastLoginAt: p.data.lastSignInAt ?? null,
        doc,
        from: doc.path,
      })
    }

    // Members (or admins) whose account is missing from the Auth export.
    for (const [uid, list] of [...known].sort(([a], [b]) => (a < b ? -1 : 1))) {
      if (authIds.has(uid)) continue
      const { email, doc } = list[0]
      for (const o of list.slice(1)) {
        if (o.email !== email) this.warn(o.doc, 'email_mismatch', `email ${o.email} differs from ${email} (${doc.path}); ${email} is used.`)
      }
      const owner = emailOwner.get(email)
      if (owner) {
        r.problem({ severity: 'error', code: 'duplicate', kind: doc.kind, path: doc.path, message: `cannot create user ${uid} (not in the Auth export): email ${email} belongs to user ${owner}.` })
        continue
      }
      emailOwner.set(email, uid)
      const created = list.map((l) => l.createdAt).filter((d): d is Date => d !== null)
      this.users.set(uid, {
        id: uid,
        email,
        status: 'active',
        createdAt: created.length ? new Date(Math.min(...created.map((d) => d.getTime()))) : this.exportedAt,
        lastLoginAt: null,
        doc: null,
        from: doc.path,
      })
      this.warn(doc, 'user_from_membership', `user ${uid} is not in the Auth export; created from this email (${email}) without a password.`)
    }
  }

  /** Users, then developer admins (one unit of work). */
  async importUsers(tx: Tx) {
    this.log(`users: ${this.users.size}`)
    const done = new Written()
    for (const u of [...this.users.values()].sort((a, b) => (a.id < b.id ? -1 : 1))) {
      const values = { email: u.email, status: u.status, createdAt: u.createdAt, updatedAt: this.exportedAt }
      // Unchanged since the last run: leave the row (and its updated_at) alone.
      const current = await tx.user.findUnique({ where: { id: u.id }, select: { email: true, status: true, createdAt: true } })
      if (current && current.email === u.email && current.status === u.status && current.createdAt.getTime() === u.createdAt.getTime()) {
        this.importedUsers.add(u.id)
        done.add('users', u.id)
        if (u.doc) this.report.settle(u.doc, 'imported')
        continue
      }
      const r = await attempt(tx, () =>
        tx.user.upsert({
          where: { id: u.id },
          // Never touches password_hash, token_version or sessions: a user who
          // already set a password keeps it when the import is rerun.
          create: { id: u.id, ...values, lastLoginAt: u.lastLoginAt },
          update: values,
        }),
      )
      if (r.ok) {
        this.importedUsers.add(u.id)
        done.add('users', u.id)
        if (u.doc) this.report.settle(u.doc, 'imported')
      } else if (u.doc) {
        this.report.reject(u.doc, r.code, r.message)
      } else {
        this.report.problem({ severity: 'error', code: r.code, path: u.from, message: `user ${u.id}: ${r.message}` })
      }
    }

    for (const doc of this.docs(K.developerAdmins)) {
      const p = adminSchema.safeParse(doc.data)
      if (!p.success) {
        this.report.reject(doc, 'invalid', issues(p.error))
        continue
      }
      this.checkFields(doc, fieldsOf(adminSchema))
      if (!this.importedUsers.has(doc.id)) {
        this.report.reject(doc, 'orphan', `user ${doc.id} was not imported (not in the Auth export and no usable email).`)
        continue
      }
      let role: AdminRole = 'support'
      if (p.data.role === 'super') role = 'super'
      else if (p.data.role != null && p.data.role !== 'support') this.warn(doc, 'invalid', `unknown role ${p.data.role}; imported as support (least privilege, as the Functions treated it).`)
      const permissions = p.data.permissions ?? []
      const unknown = permissions.filter((x) => !ADMIN_PERMISSIONS.includes(x as never))
      if (unknown.length) this.warn(doc, 'invalid', `unknown permission(s) ${unknown.join(', ')} kept but ignored by the API.`)
      const values = { role, permissions, createdAt: p.data.createdAt ?? this.exportedAt, updatedAt: p.data.updatedAt ?? p.data.createdAt ?? this.exportedAt }
      const r = await attempt(tx, () => tx.developerAdmin.upsert({ where: { userId: doc.id }, create: { userId: doc.id, ...values }, update: values }))
      if (r.ok) {
        this.report.settle(doc, 'imported')
        done.add('developer_admins', doc.id)
      } else {
        this.report.reject(doc, r.code, r.message)
      }
    }
    return done
  }

  commitWritten(done: Written) {
    for (const [table, keys] of done.keys) for (const k of keys) this.written.add(table, k)
  }

  // --- Companies ----------------------------------------------------------------

  private groupOf(companyId: string, kind: string): SourceDoc[] {
    return this.byCompany.get(companyId)?.get(kind) ?? []
  }

  private allDocsOf(companyId: string): SourceDoc[] {
    const docs = [...(this.byCompany.get(companyId)?.values() ?? [])].flat()
    const company = this.companyDocs.get(companyId)
    return company ? [company, ...docs] : docs
  }

  /** True when the company needs no transaction (its document is missing). */
  rejectIfMissing(companyId: string): boolean {
    if (this.companyDocs.has(companyId)) return false
    for (const d of this.allDocsOf(companyId)) {
      this.report.reject(d, 'company_missing', `company ${companyId} has no document in the export (subcollection of a deleted or never-created company).`, companyId)
    }
    return true
  }

  /** One company and everything under it. Runs inside the caller's transaction. */
  async importCompany(tx: Tx, companyId: string): Promise<CompanyResult> {
    const res: CompanyResult = { written: new Written(), totals: zeroTotals(), imported: false }
    const doc = this.companyDocs.get(companyId)!
    const rejectRest = (why: string) => {
      for (const d of this.allDocsOf(companyId)) if (d !== doc) this.report.reject(d, 'company_not_imported', why, companyId)
    }

    const p = companySchema.safeParse(doc.data)
    if (!p.success) {
      this.report.reject(doc, 'invalid', issues(p.error), companyId)
      rejectRest(`company ${companyId} was rejected (${issues(p.error)}).`)
      return res
    }
    const c = p.data
    this.checkFields(doc, fieldsOf(companySchema), COMPANY_DROPPED)
    if (c.id !== undefined && c.id !== companyId) this.warn(doc, 'id_mismatch', `id field ${c.id} differs from the document ID; the document ID is used.`)
    const profile = CompanyProfileInput.safeParse({ name: c.name, contactPerson: c.contactPerson, phone: c.phone, address: c.address, invoicePrefix: c.invoicePrefix, email: c.email ?? null, gstin: c.gstin ?? null })
    if (!profile.success) this.warn(doc, 'profile_invalid', `imported as is, but the profile fails today's validation (${issues(profile.error)}); the owner must fix it before the next profile edit.`)
    if (!this.importedUsers.has(c.ownerUid)) {
      this.report.reject(doc, 'orphan', `owner ${c.ownerUid} was not imported.`, companyId)
      rejectRest(`company ${companyId} was rejected (owner ${c.ownerUid} missing).`)
      return res
    }
    const values = {
      name: c.name,
      contactPerson: c.contactPerson,
      phone: c.phone,
      email: c.email ?? null,
      address: c.address,
      gstin: c.gstin ?? null,
      invoicePrefix: c.invoicePrefix,
      currency: c.currency ?? 'INR',
      status: c.status,
      ownerUserId: c.ownerUid,
      createdBy: c.createdBy ?? null,
      updatedBy: c.updatedBy ?? null,
      createdAt: c.createdAt ?? this.exportedAt,
      updatedAt: c.updatedAt ?? c.createdAt ?? this.exportedAt,
    }
    const r = await attempt(tx, () => tx.company.upsert({ where: { id: companyId }, create: { id: companyId, ...values }, update: values }))
    if (!r.ok) {
      this.report.reject(doc, r.code, r.message, companyId)
      rejectRest(`company ${companyId} was rejected (${r.message}).`)
      return res
    }
    this.report.settle(doc, 'imported')
    res.written.add('companies', companyId)
    res.imported = true

    await this.importMembers(tx, companyId, res)
    await this.importLicensing(tx, companyId, res)
    await this.importNumbering(tx, companyId, res)
    await this.importSynced(tx, companyId, res)
    return res
  }

  commitCompany(companyId: string, res: CompanyResult) {
    for (const [table, keys] of res.written.keys) for (const k of keys) this.written.add(table, k)
    if (res.imported) {
      this.importedCompanies.add(companyId)
      this.totals.set(companyId, res.totals)
    }
  }

  /** The company's transaction failed as a whole: nothing of it was written. */
  companyFailed(companyId: string, e: unknown) {
    const { message } = classify(e)
    this.report.problem({ severity: 'error', code: 'company_failed', kind: K.companies, companyId, message: `company ${companyId}: transaction rolled back (${message}); none of its documents were imported.` })
    for (const d of this.allDocsOf(companyId)) this.report.settle(d, 'rejected')
  }

  private async write(tx: Tx, doc: SourceDoc, companyId: string, table: string, key: string, res: CompanyResult, fn: () => Promise<unknown>) {
    const r = await attempt(tx, fn)
    if (r.ok) {
      this.report.settle(doc, 'imported')
      res.written.add(table, key)
      return true
    }
    this.report.reject(doc, r.code, r.message, companyId)
    return false
  }

  private async importMembers(tx: Tx, companyId: string, res: CompanyResult) {
    for (const doc of this.groupOf(companyId, K.members)) {
      const p = memberSchema.safeParse(doc.data)
      if (!p.success) {
        this.report.reject(doc, 'invalid', issues(p.error), companyId)
        continue
      }
      this.checkFields(doc, fieldsOf(memberSchema))
      const m = p.data
      if (m.uid !== undefined && m.uid !== doc.id) this.warn(doc, 'id_mismatch', `uid field ${m.uid} differs from the document ID; the document ID is used.`)
      if (m.companyId !== undefined && m.companyId !== companyId) this.warn(doc, 'id_mismatch', `companyId field ${m.companyId} differs from the path.`)
      if (!this.importedUsers.has(doc.id)) {
        this.report.reject(doc, 'orphan', `user ${doc.id} was not imported (not in the Auth export and no usable email).`, companyId)
        continue
      }
      const values = { role: m.role as CompanyRole, status: m.status, invitedBy: m.invitedBy ?? null, createdAt: m.createdAt ?? this.exportedAt, updatedAt: m.updatedAt ?? m.createdAt ?? this.exportedAt }
      await this.write(tx, doc, companyId, 'company_members', `${companyId}/${doc.id}`, res, () =>
        tx.companyMember.upsert({
          where: { companyId_userId: { companyId, userId: doc.id } },
          create: { companyId, userId: doc.id, ...values },
          update: values,
        }),
      )
    }
  }

  private async importLicensing(tx: Tx, companyId: string, res: CompanyResult) {
    for (const doc of this.groupOf(companyId, K.licenses)) {
      const p = licenseSchema.safeParse(doc.data)
      if (!p.success) {
        this.report.reject(doc, 'invalid', issues(p.error), companyId)
        continue
      }
      this.checkFields(doc, fieldsOf(licenseSchema), LICENSE_DROPPED)
      const l = p.data
      if (l.licenseId !== undefined && l.licenseId !== doc.id) this.warn(doc, 'id_mismatch', `licenseId field ${l.licenseId} differs from the document ID.`)
      const values = {
        status: l.status,
        validFrom: l.validFrom,
        validUntil: l.validUntil,
        maxDevices: l.maxDevices,
        activationCodeHash: l.activationCodeHash,
        lastValidatedAt: l.lastValidatedAt ?? null,
        createdBy: l.createdBy ?? null,
        createdAt: l.createdAt ?? this.exportedAt,
        updatedAt: l.updatedAt ?? l.createdAt ?? this.exportedAt,
      }
      await this.write(tx, doc, companyId, 'licenses', `${companyId}/${doc.id}`, res, () =>
        tx.license.upsert({ where: { id: doc.id }, create: { id: doc.id, companyId, ...values }, update: { companyId, ...values } }),
      )
    }
    const licensed = (doc: SourceDoc, licenseId: string) => {
      if (res.written.has('licenses', `${companyId}/${licenseId}`)) return true
      this.report.reject(doc, 'orphan', `license ${licenseId} is missing or was not imported.`, companyId)
      return false
    }

    for (const doc of this.groupOf(companyId, K.devices)) {
      const p = deviceSchema.safeParse(doc.data)
      if (!p.success) {
        this.report.reject(doc, 'invalid', issues(p.error), companyId)
        continue
      }
      this.checkFields(doc, fieldsOf(deviceSchema))
      const d = p.data
      if (d.deviceId !== undefined && d.deviceId !== doc.id) this.warn(doc, 'id_mismatch', `deviceId field ${d.deviceId} differs from the document ID.`)
      if (!licensed(doc, d.licenseId)) continue
      const values = {
        licenseId: d.licenseId,
        userId: d.userId,
        deviceModel: d.deviceModel ?? null,
        platform: d.platform ?? 'android',
        status: d.status,
        activatedAt: d.activatedAt ?? null,
        lastSeenAt: d.lastSeenAt ?? null,
        revokedAt: d.revokedAt ?? null,
        revokedBy: d.revokedBy ?? null,
        revokeReason: d.revokeReason ?? null,
        replacedBy: d.replacedBy ?? null,
        replacementForDeviceId: d.replacementForDeviceId ?? null,
      }
      await this.write(tx, doc, companyId, 'devices', `${companyId}/${doc.id}`, res, () =>
        tx.device.upsert({ where: { companyId_id: { companyId, id: doc.id } }, create: { companyId, id: doc.id, ...values }, update: values }),
      )
    }

    for (const doc of this.groupOf(companyId, K.replacements)) {
      const p = replacementSchema.safeParse(doc.data)
      if (!p.success) {
        this.report.reject(doc, 'invalid', issues(p.error), companyId)
        continue
      }
      this.checkFields(doc, fieldsOf(replacementSchema), REPLACEMENT_DROPPED)
      const q = p.data
      if (q.requestId !== undefined && q.requestId !== doc.id) this.warn(doc, 'id_mismatch', `requestId field ${q.requestId} differs from the document ID.`)
      if (!licensed(doc, q.licenseId)) continue
      const values = {
        companyId,
        licenseId: q.licenseId,
        newDeviceId: q.newDeviceId,
        newDeviceModel: q.newDeviceModel ?? null,
        requestedBy: q.requestedBy,
        reason: q.reason,
        status: q.status,
        createdAt: q.createdAt ?? this.exportedAt,
        reviewedBy: q.reviewedBy ?? null,
        reviewedAt: q.reviewedAt ?? null,
        reviewReason: q.reviewReason ?? null,
        revokedDeviceId: q.revokedDeviceId ?? null,
      }
      await this.write(tx, doc, companyId, 'device_replacement_requests', `${companyId}/${doc.id}`, res, () =>
        tx.deviceReplacementRequest.upsert({ where: { id: doc.id }, create: { id: doc.id, ...values }, update: values }),
      )
    }
  }

  private async importNumbering(tx: Tx, companyId: string, res: CompanyResult) {
    for (const doc of this.groupOf(companyId, K.issued)) {
      const p = issuedSchema.safeParse(doc.data)
      if (!p.success) {
        this.report.reject(doc, 'invalid', issues(p.error), companyId)
        continue
      }
      this.checkFields(doc, fieldsOf(issuedSchema))
      const n = p.data
      const values = { invoiceNumber: n.invoiceNumber, financialYear: n.financialYear, issuedBy: n.issuedBy, issuedAt: n.issuedAt ?? this.exportedAt }
      await this.write(tx, doc, companyId, 'issued_invoice_numbers', `${companyId}/${doc.id}`, res, () =>
        tx.issuedInvoiceNumber.upsert({
          where: { companyId_invoiceId: { companyId, invoiceId: doc.id } },
          create: { companyId, invoiceId: doc.id, ...values },
          update: values,
        }),
      )
    }

    for (const doc of this.groupOf(companyId, K.counters)) {
      const fy = COUNTER_ID.exec(doc.id)?.[1]
      if (!fy) {
        this.report.settle(doc, 'skipped')
        this.warn(doc, 'unmapped_collection', `counters/${doc.id} is not an invoice counter (invoices-YYYY-YY); not imported.`)
        continue
      }
      const p = counterSchema.safeParse(doc.data)
      if (!p.success) {
        this.report.reject(doc, 'invalid', issues(p.error), companyId)
        continue
      }
      this.checkFields(doc, fieldsOf(counterSchema))
      const values = { last: p.data.last, updatedAt: p.data.updatedAt ?? this.exportedAt }
      await this.write(tx, doc, companyId, 'invoice_number_counters', `${companyId}/${fy}`, res, () =>
        tx.invoiceNumberCounter.upsert({
          where: { companyId_financialYear: { companyId, financialYear: fy } },
          create: { companyId, financialYear: fy, ...values },
          update: values,
        }),
      )
    }
  }

  // --- Synced business data ---------------------------------------------------

  /** Business fields + sync metadata of one document, or null (reported) if it can't be imported. */
  private prepare(c: CollectionName, doc: SourceDoc, companyId: string): Candidate | null {
    const raw: Json = { ...doc.data }
    const meta = syncMetaSchema.safeParse({ rev: raw.rev, serverUpdatedAt: raw.serverUpdatedAt, pushedBy: raw.pushedBy, deviceId: raw.deviceId })
    for (const k of SYNC_META) delete raw[k]
    for (const k of DEVICE_ONLY) {
      if (k in raw) {
        delete raw[k]
        this.report.dropped(doc.kind, k)
      }
    }
    if (!meta.success) {
      this.report.reject(doc, 'invalid', `sync metadata: ${issues(meta.error)}`, companyId)
      return null
    }
    const parsed = SCHEMAS[c].safeParse(raw)
    if (!parsed.success) {
      this.report.reject(doc, 'invalid', issues(parsed.error), companyId)
      return null
    }
    const data = parsed.data as Json
    if (data.id !== doc.id || data.companyId !== companyId) {
      this.report.reject(doc, 'id_mismatch', `id/companyId fields (${String(data.id)}, ${String(data.companyId)}) do not match the path.`, companyId)
      return null
    }
    if (c === 'invoices' && (data.lines as Json[]).some((l) => l.companyId !== companyId || l.invoiceId !== doc.id)) {
      this.report.reject(doc, 'invalid', 'an invoice line belongs to another invoice or company.', companyId)
      return null
    }
    const m = meta.data
    return { c, doc, data, rev: m.rev, ts: m.serverUpdatedAt, pushedBy: m.pushedBy, deviceId: m.deviceId ?? null }
  }

  /** References that must exist (the composite foreign keys of the schema). */
  private missingRef(c: CollectionName, data: Json, has: (c: CollectionName, id: unknown) => boolean): string | null {
    const need = (col: CollectionName, field: string, id: unknown, optional = false) =>
      (optional && id == null) || has(col, id) ? null : `${field} ${String(id)} (${col}) is missing or was not imported`
    switch (c) {
      case 'sites':
        return need('clients', 'clientId', data.clientId)
      case 'workLogs':
        return (
          need('clients', 'clientId', data.clientId) ??
          need('sites', 'siteId', data.siteId) ??
          need('machines', 'machineId', data.machineId) ??
          need('operators', 'operatorId', data.operatorId, true)
        )
      case 'fuelEntries':
        return (
          need('machines', 'machineId', data.machineId) ??
          need('petrolPumps', 'pumpId', data.pumpId) ??
          need('clients', 'clientId', data.clientId, true) ??
          need('sites', 'siteId', data.siteId, true)
        )
      case 'invoices':
        return need('clients', 'clientId', data.clientId) ?? (data.lines as Json[]).map((l) => need('workLogs', `line ${String(l.id)} workLogId`, l.workLogId)).find(Boolean) ?? null
      case 'payments':
        return need('invoices', 'invoiceId', data.invoiceId)
      default:
        return null
    }
  }

  private async importSynced(tx: Tx, companyId: string, res: CompanyResult) {
    // 1. Validate, then check references in dependency order.
    const accepted = new Map<CollectionName, Set<string>>(SYNC_ORDER.map((c) => [c, new Set<string>()]))
    const candidates: Candidate[] = []
    for (const c of SYNC_ORDER) {
      for (const doc of this.groupOf(companyId, syncKind(c))) {
        const cand = this.prepare(c, doc, companyId)
        if (!cand) continue
        const missing = this.missingRef(c, cand.data, (col, id) => accepted.get(col)!.has(id as string))
        if (missing) {
          this.report.reject(doc, 'orphan', missing, companyId)
          continue
        }
        accepted.get(c)!.add(doc.id)
        candidates.push(cand)
      }
    }

    // 2. Change-feed order: serverUpdatedAt, then document ID.
    const order = [...candidates].sort(
      (a, b) => FsTimestamp.compare(a.ts, b.ts) || (a.doc.id < b.doc.id ? -1 : a.doc.id > b.doc.id ? 1 : 0) || SYNC_ORDER.indexOf(a.c) - SYNC_ORDER.indexOf(b.c),
    )
    const seqOf = new Map(order.map((cand, i) => [cand, BigInt(i + 1)]))

    // 3. Park existing rows of this company out of the way (a rerun reassigns the same values).
    for (const table of Object.values(SYNC_TABLES)) {
      await tx.$executeRawUnsafe(`UPDATE ${table} SET sync_seq = -sync_seq WHERE company_id = $1 AND sync_seq > 0`, companyId)
    }

    // 4. Write in dependency order; references are re-checked against what was written.
    const written = (col: CollectionName, id: unknown) => res.written.has(SYNC_TABLES[col], `${companyId}/${String(id)}`)
    for (const cand of candidates) {
      const missing = this.missingRef(cand.c, cand.data, written)
      if (missing) {
        this.report.reject(cand.doc, 'orphan', missing, companyId)
        continue
      }
      const ok = await this.write(tx, cand.doc, companyId, SYNC_TABLES[cand.c], `${companyId}/${cand.doc.id}`, res, () =>
        saveRecord(tx, cand.c, cand.data, {
          rev: cand.rev,
          syncSeq: seqOf.get(cand)!,
          serverUpdatedAt: cand.ts.toDate(),
          pushedBy: cand.pushedBy,
          deviceId: cand.deviceId,
        }),
      )
      if (ok) this.addTotals(res, cand)
    }

    // 5. Rows already in the target that this export does not contain keep
    //    their relative order after the imported ones.
    let max = order.length ? BigInt(order.length) : 0n
    const parked = await tx.$queryRawUnsafe<{ t: string; id: string; seq: bigint }[]>(
      Object.values(SYNC_TABLES)
        .map((t) => `SELECT '${t}' AS t, id, sync_seq AS seq FROM ${t} WHERE company_id = $1 AND sync_seq < 0`)
        .join(' UNION ALL ') + ' ORDER BY seq DESC',
      companyId,
    )
    for (const row of parked) {
      max++
      await tx.$executeRawUnsafe(`UPDATE ${row.t} SET sync_seq = $1 WHERE company_id = $2 AND id = $3`, max, companyId, row.id)
      this.report.problem({ severity: 'warning', code: 'target_only', companyId, kind: row.t, message: `${row.t} ${companyId}/${row.id} is in the database but not in the export; kept with sync_seq ${max}.` })
    }
    const used = await tx.$queryRawUnsafe<{ max: bigint | null }[]>(
      `SELECT max(m) AS max FROM (${Object.values(SYNC_TABLES).map((t) => `SELECT max(sync_seq) AS m FROM ${t} WHERE company_id = $1`).join(' UNION ALL ')}) x`,
      companyId,
    )
    const seq = used[0]?.max ?? 0n
    await tx.companySyncState.upsert({ where: { companyId }, create: { companyId, seq }, update: { seq } })
  }

  private addTotals(res: CompanyResult, cand: Candidate) {
    const t = res.totals
    const d = cand.doc.data
    const big = (v: unknown) => BigInt(v as number)
    switch (cand.c) {
      case 'invoices': {
        const lines = d.lines as Json[]
        t.invoices++
        t.invoiceTotalPaise += big(d.totalPaise)
        t.invoiceLines += BigInt(lines.length)
        for (const l of lines) t.invoiceLineAmountPaise += big(l.amountPaise)
        for (const l of lines) res.written.add('invoice_lines', `${cand.data.companyId as string}/${l.id as string}`)
        break
      }
      case 'payments':
        if (d.reversedAt == null) t.paymentsNotReversedPaise += big(d.amountPaise)
        break
      case 'fuelEntries':
        t.fuelTotalPaise += big(d.totalPaise)
        break
      case 'workLogs':
        t.workLogs++
        if (d.workingHours != null) t.workLogWorkingHours += big(d.workingHours)
        break
    }
  }

  // --- auditEvents ----------------------------------------------------------------

  async importAuditEvents(tx: Tx) {
    const done = new Written()
    const docs = this.docs(K.auditEvents)
    this.log(`auditEvents: ${docs.length}`)
    for (const doc of docs) {
      const { type, at, ...rest } = doc.data
      if (typeof type !== 'string' || !type || type.length > 200) {
        this.report.reject(doc, 'invalid', 'type: required text.')
        continue
      }
      const when = ts.safeParse(at)
      if (!when.success || at == null) {
        this.report.reject(doc, 'invalid', 'at: required Firestore timestamp.')
        continue
      }
      const cols: Record<'actorId' | 'companyId' | 'licenseId' | 'deviceId' | 'reason', string | null> = {
        actorId: null,
        companyId: null,
        licenseId: null,
        deviceId: null,
        reason: null,
      }
      const details: Record<string, unknown> = { ...rest }
      for (const k of Object.keys(cols) as (keyof typeof cols)[]) {
        const v = rest[k]
        if (typeof v === 'string') {
          cols[k] = v
          delete details[k]
        } else if (v == null) {
          delete details[k]
        } else {
          this.warn(doc, 'invalid', `${k} is not text; kept in details.`)
        }
      }
      // activateDevice/validate events recorded the caller as `uid`.
      if (cols.actorId == null && typeof rest.uid === 'string') cols.actorId = rest.uid
      const values = { type, ...cols, details: plainJson(details) as object, at: when.data }
      const r = await attempt(tx, () => tx.auditEvent.upsert({ where: { id: doc.id }, create: { id: doc.id, ...values }, update: values }))
      if (r.ok) {
        this.report.settle(doc, 'imported')
        done.add('audit_events', doc.id)
      } else {
        this.report.reject(doc, r.code, r.message)
      }
    }
    return done
  }

  /** Emits the aggregated unknown-field warnings (once, after all writes). */
  finish() {
    for (const u of this.unknownFields.values()) {
      this.report.problem({
        severity: 'warning',
        code: 'unmapped_field',
        kind: u.kind,
        message: `field ${u.field} has no column and was dropped (${u.count} document(s), e.g. ${u.sample}).`,
      })
    }
  }
}

// --- Entry point ------------------------------------------------------------------

export interface ImportOptions {
  /** Validate and reconcile inside one transaction that is rolled back. */
  dryRun?: boolean
  /** Refuse to run unless the target has no users, companies, admins or audit events. */
  fresh?: boolean
  /** Interactive-transaction timeout (per company; for the whole run in a dry run). */
  transactionTimeoutMs?: number
  /** Shown in the report (connection string without password). */
  target?: string
  log?: (message: string) => void
}

class DryRunRollback extends Error {}

async function assertEmpty(db: Db) {
  const [row] = await db.$queryRawUnsafe<{ users: bigint; companies: bigint; admins: bigint; events: bigint }[]>(
    `SELECT (SELECT count(*) FROM users) AS users, (SELECT count(*) FROM companies) AS companies,
            (SELECT count(*) FROM developer_admins) AS admins, (SELECT count(*) FROM audit_events) AS events`,
  )
  if (row.users + row.companies + row.admins + row.events > 0n) {
    throw new FatalImportError(
      `--fresh needs an empty target, but it has ${row.users} users, ${row.companies} companies, ${row.admins} developer admins and ${row.events} audit events. Use a new database, or drop --fresh to upsert.`,
    )
  }
}

export async function importFirestore(db: Db, dir: string, opts: ImportOptions = {}): Promise<ImportReport> {
  const report = new ImportReport()
  report.mode = opts.dryRun ? 'dry-run' : 'import'
  report.fresh = !!opts.fresh
  report.exportDir = dir
  report.target = opts.target ?? ''
  const log = opts.log ?? (() => {})
  const timeout = opts.transactionTimeoutMs ?? 10 * 60_000
  const txOptions = { timeout, maxWait: 30_000 }

  const src = await readExport(dir, report)
  report.setManifestCounts(src.manifest.counts)
  report.projectId = src.manifest.projectId
  report.exportedAt = src.manifest.exportedAt
  if (opts.fresh) await assertEmpty(db)

  const run = new ImportRun(src, report, log)

  if (opts.dryRun) {
    try {
      await db.$transaction(async (tx) => {
        run.commitWritten(await run.importUsers(tx))
        for (const companyId of run.companyIds) {
          if (run.rejectIfMissing(companyId)) continue
          log(`company ${companyId}`)
          await tx.$executeRawUnsafe('SAVEPOINT import_company')
          try {
            const res = await run.importCompany(tx, companyId)
            await tx.$executeRawUnsafe('RELEASE SAVEPOINT import_company')
            run.commitCompany(companyId, res)
          } catch (e) {
            await tx.$executeRawUnsafe('ROLLBACK TO SAVEPOINT import_company')
            run.companyFailed(companyId, e)
          }
        }
        run.commitWritten(await run.importAuditEvents(tx))
        run.finish()
        await reconcile(tx, run)
        throw new DryRunRollback()
      }, txOptions)
    } catch (e) {
      if (!(e instanceof DryRunRollback)) throw e
    }
  } else {
    run.commitWritten(await db.$transaction((tx) => run.importUsers(tx), txOptions))
    for (const companyId of run.companyIds) {
      if (run.rejectIfMissing(companyId)) continue
      log(`company ${companyId}`)
      try {
        const res = await db.$transaction((tx) => run.importCompany(tx, companyId), txOptions)
        run.commitCompany(companyId, res)
      } catch (e) {
        run.companyFailed(companyId, e)
      }
    }
    run.commitWritten(await db.$transaction((tx) => run.importAuditEvents(tx), txOptions))
    run.finish()
    await reconcile(db as unknown as Tx, run)
  }
  report.finishedAt = new Date()
  return report
}
