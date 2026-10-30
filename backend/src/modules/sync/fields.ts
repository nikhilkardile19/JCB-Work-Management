import { z } from '../../lib/validation.js'

/**
 * One column of a synced record: how it is validated in the app's JSON, and
 * how it converts to and from the Prisma value. JSON keys equal the Drift
 * column getters (and the Prisma field names), e.g. `startReading`.
 */
export interface Field {
  schema: z.ZodType
  toDb: (v: unknown) => unknown
  fromDb: (v: unknown) => unknown
}

const INT4 = { min: -2_147_483_648, max: 2_147_483_647 }
const same = (v: unknown) => v
const nullable = (f: Field): Field => ({
  schema: f.schema.nullable(),
  toDb: (v) => (v == null ? null : f.toDb(v)),
  fromDb: (v) => (v == null ? null : f.fromDb(v)),
})

const DATE = /^\d{4}-\d{2}-\d{2}$/
const isCalendarDate = (s: string) => DATE.test(s) && new Date(`${s}T00:00:00Z`).toISOString().startsWith(s)

export const t = {
  /** Text up to [max] characters. */
  text: (max = 500, min = 0): Field => ({ schema: z.string().min(min).max(max), toDb: same, fromDb: same }),
  /** Record IDs and references. */
  id: (): Field => ({ schema: z.string().min(1).max(128).regex(/^[^/\s]+$/), toDb: same, fromDb: same }),
  /** INTEGER column (readings, hours, litres, counts). */
  int: (): Field => ({ schema: z.number().int().min(INT4.min).max(INT4.max), toDb: same, fromDb: same }),
  /** BIGINT money column (paise); JSON numbers stay within the safe range. */
  money: (): Field => ({
    schema: z.number().int().min(Number.MIN_SAFE_INTEGER).max(Number.MAX_SAFE_INTEGER),
    toDb: (v) => BigInt(v as number),
    fromDb: (v) => Number(v as bigint),
  }),
  bool: (): Field => ({ schema: z.boolean(), toDb: same, fromDb: same }),
  real: (): Field => ({ schema: z.number().finite(), toDb: same, fromDb: same }),
  /** Epoch milliseconds ⇄ timestamptz. */
  ts: (): Field => ({
    schema: z.number().int().min(0).max(8_640_000_000_000_000),
    toDb: (v) => new Date(v as number),
    fromDb: (v) => (v as Date).getTime(),
  }),
  /** `yyyy-MM-dd` ⇄ date. */
  date: (): Field => ({
    schema: z.string().refine(isCalendarDate, 'must be a date like 2026-10-30'),
    toDb: (v) => new Date(`${v as string}T00:00:00Z`),
    fromDb: (v) => (v as Date).toISOString().slice(0, 10),
  }),
  enum: <T extends string>(values: readonly [T, ...T[]]): Field => ({ schema: z.enum(values), toDb: same, fromDb: same }),
  nullable,
}

export type Fields = Record<string, Field>
type Json = Record<string, unknown>

export function objectSchema(fields: Fields) {
  return z.object(Object.fromEntries(Object.entries(fields).map(([k, f]) => [k, f.schema]))).strict()
}

export function toDb(fields: Fields, data: Json): Json {
  return Object.fromEntries(Object.entries(fields).map(([k, f]) => [k, f.toDb(data[k])]))
}

export function fromDb(fields: Fields, row: Json): Json {
  return Object.fromEntries(Object.entries(fields).map(([k, f]) => [k, f.fromDb(row[k])]))
}
