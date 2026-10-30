import { createHash } from 'node:crypto'
import { createReadStream } from 'node:fs'
import { readdir, readFile } from 'node:fs/promises'
import { join } from 'node:path'
import { createInterface } from 'node:readline'
import type { ImportReport } from './report.js'

/**
 * Reader for the backup written by `tools/firestore-export` (format 1).
 *
 *   manifest.json            { format, formatVersion, projectId, exportedAt, counts, files }
 *   <kind>.ndjson            one document per line: {"path", "id", "data"}
 *   auth-users.ndjson        Firebase Auth users, kind `__auth__`, path `__auth__/{uid}`
 *
 * A kind is the document path with the IDs replaced by `*`, e.g.
 * `companies/*\/workLogs`. Values Firestore has but JSON hasn't are tagged:
 *   {"__type":"timestamp","ms":<epoch ms>,"ns":<extra nanoseconds 0–999999, optional>}
 *   {"__type":"geopoint","lat","lng"}  {"__type":"reference","path"}
 *   {"__type":"bytes","base64"}  {"__type":"vector","values"}
 *   {"__type":"int64","value":"<digits>"}  (integers beyond ±2^53)
 *   {"__type":"double","value":"NaN"|"Infinity"|"-Infinity"}
 *   {"__type":"map","value":{…}}  (a real map that has a `__type` key)
 */
export const AUTH_KIND = '__auth__'
export const EXPORT_FORMAT = 'jcb-firestore-export'

/** A Firestore Timestamp: epoch milliseconds plus the sub-millisecond nanoseconds. */
export class FsTimestamp {
  constructor(
    readonly ms: number,
    readonly ns = 0,
  ) {}

  toDate(): Date {
    return new Date(this.ms)
  }

  static compare(a: FsTimestamp, b: FsTimestamp): number {
    return a.ms - b.ms || a.ns - b.ns
  }
}

/** Any other tagged Firestore value (geopoint, reference, bytes, vector, int64, double). */
export class FsTagged {
  constructor(
    readonly type: string,
    readonly value: Record<string, unknown>,
  ) {}
}

export interface SourceDoc {
  kind: string
  path: string
  id: string
  /** Path segments: collection, id, collection, id, … */
  segments: string[]
  data: Record<string, unknown>
  file: string
  line: number
}

export interface Manifest {
  format: string
  formatVersion: number
  projectId: string | null
  exportedAt: string
  counts: Record<string, number>
  files?: Record<string, { file: string; count: number; sha256?: string }>
}

export interface ExportData {
  dir: string
  manifest: Manifest
  exportedAt: Date
  /** Parsed documents by kind, in file order, without duplicate paths. */
  docs: Map<string, SourceDoc[]>
}

export class FatalImportError extends Error {}

export const kindOf = (segments: string[]) => segments.filter((_, i) => i % 2 === 0).join('/*/')

class DecodeError extends Error {}

export function decodeValue(v: unknown): unknown {
  if (Array.isArray(v)) return v.map(decodeValue)
  if (v === null || typeof v !== 'object') return v
  const o = v as Record<string, unknown>
  if (typeof o.__type !== 'string') return Object.fromEntries(Object.entries(o).map(([k, x]) => [k, decodeValue(x)]))
  switch (o.__type) {
    case 'timestamp': {
      const ns = o.ns ?? 0
      if (!Number.isSafeInteger(o.ms) || !Number.isInteger(ns) || (ns as number) < 0 || (ns as number) > 999_999) {
        throw new DecodeError('bad timestamp')
      }
      return new FsTimestamp(o.ms as number, ns as number)
    }
    case 'map':
      if (!o.value || typeof o.value !== 'object' || Array.isArray(o.value)) throw new DecodeError('bad map')
      return Object.fromEntries(Object.entries(o.value).map(([k, x]) => [k, decodeValue(x)]))
    case 'geopoint':
    case 'reference':
    case 'bytes':
    case 'vector':
    case 'int64':
    case 'double': {
      const { __type, ...rest } = o
      return new FsTagged(__type as string, rest)
    }
    default:
      throw new DecodeError(`unknown __type ${String(o.__type)}`)
  }
}

function validPath(segments: string[]) {
  return segments.length >= 2 && segments.length % 2 === 0 && segments.every((s) => s.length > 0)
}

async function readManifest(dir: string): Promise<Manifest> {
  let raw: string
  try {
    raw = await readFile(join(dir, 'manifest.json'), 'utf8')
  } catch {
    throw new FatalImportError(`${dir} has no manifest.json — is it a complete export from tools/firestore-export?`)
  }
  const m = JSON.parse(raw) as Manifest
  if (m.format !== EXPORT_FORMAT || m.formatVersion !== 1) {
    throw new FatalImportError(`Unsupported export format ${String(m.format)} v${String(m.formatVersion)} (expected ${EXPORT_FORMAT} v1).`)
  }
  if (!m.counts || typeof m.counts !== 'object' || Number.isNaN(Date.parse(m.exportedAt))) {
    throw new FatalImportError('manifest.json is missing counts or exportedAt.')
  }
  return m
}

/**
 * Reads every NDJSON file of the export. Never throws for one bad line: a
 * line that is not valid JSON, has a bad path or an undecodable value is
 * reported as `malformed`; a path seen twice is reported as `duplicate`
 * (the first copy is kept).
 */
export async function readExport(dir: string, report: ImportReport): Promise<ExportData> {
  const manifest = await readManifest(dir)
  const files = (await readdir(dir)).filter((f) => f.endsWith('.ndjson')).sort()
  const listed = new Set(Object.values(manifest.files ?? {}).map((f) => f.file))
  for (const f of listed) {
    if (!files.includes(f)) report.problem({ severity: 'error', code: 'malformed', message: `File ${f} listed in manifest.json is missing.` })
  }
  // The exporter records a checksum per file; a mismatch means the backup changed after export.
  for (const [kind, f] of Object.entries(manifest.files ?? {})) {
    if (!f.sha256 || !files.includes(f.file)) continue
    const actual = createHash('sha256').update(await readFile(join(dir, f.file))).digest('hex')
    if (actual !== f.sha256) report.fail(`${f.file} (${kind}): SHA-256 differs from manifest.json — the file changed after the export.`)
  }

  const docs = new Map<string, SourceDoc[]>()
  const seen = new Set<string>()
  for (const file of files) {
    const fileKind = Object.entries(manifest.files ?? {}).find(([, f]) => f.file === file)?.[0] ?? null
    const lines = createInterface({ input: createReadStream(join(dir, file), 'utf8'), crlfDelay: Infinity })
    let n = 0
    for await (const text of lines) {
      n++
      if (!text.trim()) continue
      const where = `${file}:${n}`
      let parsed: { path?: unknown; id?: unknown; data?: unknown }
      try {
        parsed = JSON.parse(text)
      } catch {
        report.lineRead(fileKind ?? `?${file}`, 'malformed')
        report.problem({ severity: 'error', code: 'malformed', kind: fileKind ?? undefined, message: `${where}: not valid JSON.` })
        continue
      }
      const path = typeof parsed?.path === 'string' ? parsed.path : null
      const segments = path?.split('/') ?? []
      if (!path || !validPath(segments) || parsed.id !== segments.at(-1) || !parsed.data || typeof parsed.data !== 'object' || Array.isArray(parsed.data)) {
        report.lineRead(fileKind ?? `?${file}`, 'malformed')
        report.problem({ severity: 'error', code: 'malformed', kind: fileKind ?? undefined, path: path ?? undefined, message: `${where}: expected {"path","id","data"} with a document path ending in the id.` })
        continue
      }
      const kind = kindOf(segments)
      if (fileKind && kind !== fileKind) {
        report.lineRead(fileKind, 'malformed')
        report.problem({ severity: 'error', code: 'malformed', kind: fileKind, path, message: `${where}: a ${kind} document in the ${fileKind} file.` })
        continue
      }
      let data: Record<string, unknown>
      try {
        data = decodeValue(parsed.data) as Record<string, unknown>
      } catch (e) {
        report.lineRead(kind, 'malformed')
        report.problem({ severity: 'error', code: 'malformed', kind, path, message: `${where}: ${(e as Error).message}.` })
        continue
      }
      if (seen.has(path)) {
        report.lineRead(kind, 'duplicate')
        report.problem({ severity: 'error', code: 'duplicate', kind, path, message: `${where}: ${path} appears more than once; the first copy is used.` })
        continue
      }
      seen.add(path)
      report.lineRead(kind, 'read')
      const list = docs.get(kind) ?? []
      list.push({ kind, path, id: segments.at(-1)!, segments, data, file, line: n })
      docs.set(kind, list)
    }
  }
  for (const list of docs.values()) list.sort((a, b) => (a.path < b.path ? -1 : a.path > b.path ? 1 : 0))
  return { dir, manifest, exportedAt: new Date(manifest.exportedAt), docs }
}
