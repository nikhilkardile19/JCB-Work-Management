import { DocumentReference, GeoPoint, Timestamp } from 'firebase-admin/firestore'

/**
 * Firestore value → JSON, losslessly. Plain JSON values pass through; the
 * rest are tagged objects the importer (backend/src/scripts/firestore-import)
 * decodes:
 *
 *   Timestamp      {"__type":"timestamp","ms":<epoch ms>,"ns":<extra ns, 1–999999, omitted when 0>}
 *   GeoPoint       {"__type":"geopoint","lat":…,"lng":…}
 *   reference      {"__type":"reference","path":"companies/…"}
 *   bytes          {"__type":"bytes","base64":"…"}
 *   vector         {"__type":"vector","values":[…]}
 *   int64          {"__type":"int64","value":"<digits>"}       (beyond ±2^53 only)
 *   NaN/±Infinity  {"__type":"double","value":"NaN"}
 *   a map that itself has a "__type" key: {"__type":"map","value":{…}}
 *
 * The Firestore client must run with `useBigInt: true` so 64-bit integers
 * arrive intact.
 */
const MIN_SAFE = BigInt(Number.MIN_SAFE_INTEGER)
const MAX_SAFE = BigInt(Number.MAX_SAFE_INTEGER)

export function encodeTimestamp(t: Timestamp) {
  const ms = t.seconds * 1000 + Math.floor(t.nanoseconds / 1_000_000)
  const ns = t.nanoseconds % 1_000_000
  return ns ? { __type: 'timestamp', ms, ns } : { __type: 'timestamp', ms }
}

/** Epoch milliseconds (e.g. Auth metadata) in the timestamp encoding. */
export const encodeMillis = (ms: number) => ({ __type: 'timestamp', ms })

export function encodeValue(v: unknown): unknown {
  if (v === null || typeof v === 'string' || typeof v === 'boolean') return v
  if (typeof v === 'bigint') return v >= MIN_SAFE && v <= MAX_SAFE ? Number(v) : { __type: 'int64', value: v.toString() }
  if (typeof v === 'number') return Number.isFinite(v) ? v : { __type: 'double', value: String(v) }
  if (v instanceof Timestamp) return encodeTimestamp(v)
  if (v instanceof GeoPoint) return { __type: 'geopoint', lat: v.latitude, lng: v.longitude }
  if (v instanceof DocumentReference) return { __type: 'reference', path: v.path }
  if (v instanceof Uint8Array) return { __type: 'bytes', base64: Buffer.from(v).toString('base64') }
  if (Array.isArray(v)) return v.map(encodeValue)
  if (typeof v === 'object') {
    const ctor = (v as object).constructor?.name
    if (ctor === 'VectorValue' && typeof (v as { toArray?: unknown }).toArray === 'function') {
      return { __type: 'vector', values: (v as { toArray(): number[] }).toArray() }
    }
    if (ctor !== 'Object' && ctor !== undefined) throw new Error(`Unsupported Firestore value of type ${ctor}`)
    const out = Object.fromEntries(Object.entries(v).map(([k, x]) => [k, encodeValue(x)]))
    return '__type' in out ? { __type: 'map', value: out } : out
  }
  throw new Error(`Unsupported Firestore value of type ${typeof v}`)
}

/** `companies/c1/workLogs/w1` → `companies/*\/workLogs`. */
export const kindOf = (path: string) =>
  path
    .split('/')
    .filter((_, i) => i % 2 === 0)
    .join('/*/')

/** Reserved kind for Firebase Auth users (Firestore reserves IDs like `__x__`). */
export const AUTH_KIND = '__auth__'

/** NDJSON file name of a kind: `companies/*\/workLogs` → `companies.workLogs.ndjson`. */
export const fileOf = (kind: string) => (kind === AUTH_KIND ? 'auth-users.ndjson' : `${kind.split('/*/').map(encodeURIComponent).join('.')}.ndjson`)
