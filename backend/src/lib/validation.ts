import { z, type ZodType } from 'zod'
import { extendZodWithOpenApi } from '@asteasolutions/zod-to-openapi'
import { invalid } from './errors.js'

extendZodWithOpenApi(z)

export { z }

/** Parses [value] or throws `invalid_argument` with per-field messages. */
export function parse<T>(schema: ZodType<T>, value: unknown, what = 'request'): T {
  const r = schema.safeParse(value)
  if (r.success) return r.data
  const fields: Record<string, string> = {}
  for (const issue of r.error.issues) {
    const key = issue.path.join('.') || what
    fields[key] ??= issue.message
  }
  const first = Object.entries(fields)[0]
  throw invalid(first ? `Check ${first[0]}: ${first[1]}` : `Invalid ${what}.`, fields)
}

/** Path/ID segment: non-empty, bounded, no slashes (as the Functions checked). */
export const idSchema = (max = 128) =>
  z.string().min(1).max(max).regex(/^[^/\s]+$/, 'must not contain slashes or spaces')

export const reasonSchema = z
  .string()
  .trim()
  .min(3, 'A reason (3–500 characters) is required.')
  .max(500, 'A reason (3–500 characters) is required.')

export const emailSchema = z
  .string()
  .trim()
  .max(200)
  .regex(/^[^@\s]+@[^@\s]+\.[^@\s]+$/, 'must be a valid email address')
  .transform((v) => v.toLowerCase())
