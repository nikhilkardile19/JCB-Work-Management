import { invalid } from './errors.js'
import { z } from './validation.js'

export const PAGE_SIZE = 25

/** `?cursor=&limit=` for admin lists. The cursor is opaque to clients. */
export const PageQuery = z.object({
  cursor: z.string().max(500).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(PAGE_SIZE),
})

export const encodeCursor = (key: object) => Buffer.from(JSON.stringify(key)).toString('base64url')

export function decodeCursor<T>(cursor: string | undefined): T | undefined {
  if (!cursor) return undefined
  try {
    return JSON.parse(Buffer.from(cursor, 'base64url').toString('utf8')) as T
  } catch {
    throw invalid('The cursor is not valid.')
  }
}

/**
 * Keyset page via Prisma's cursor pagination: fetches one extra row to know
 * whether another page exists. [key] picks the unique key of a row.
 */
export async function page<Row, Key extends object, Out>(
  fetch: (args: { take: number; skip?: number; cursor?: Key }) => Promise<Row[]>,
  key: (row: Row) => Key,
  map: (row: Row) => Out,
  q: { cursor?: string; limit: number },
): Promise<{ items: Out[]; next: string | null }> {
  const cursor = decodeCursor<Key>(q.cursor)
  const rows = await fetch({ take: q.limit + 1, ...(cursor ? { cursor, skip: 1 } : {}) })
  const items = rows.slice(0, q.limit)
  return { items: items.map(map), next: rows.length > q.limit ? encodeCursor(key(items[items.length - 1])) : null }
}
