import { createHash, randomInt } from 'node:crypto'

/** Unambiguous alphabet (no I, O, 0, 1) for codes read over the phone. */
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
const CODE_PREFIX = 'JCBW'

/** Random activation code like `JCBW-7KQ2-M9XD-PA4H` (60 bits of entropy). */
export function generateActivationCode(): string {
  const groups = Array.from({ length: 3 }, () =>
    Array.from({ length: 4 }, () => ALPHABET[randomInt(ALPHABET.length)]).join(''),
  )
  return [CODE_PREFIX, ...groups].join('-')
}

/** Upper-case, drop spaces/dashes and the optional prefix. */
export function normalizeCode(code: string): string {
  const s = code.toUpperCase().replace(/[\s-]/g, '')
  return s.startsWith(CODE_PREFIX) ? s.slice(CODE_PREFIX.length) : s
}

/** Same hash as the Cloud Functions, so migrated licenses keep their codes. */
export function hashCode(code: string): string {
  return createHash('sha256').update(normalizeCode(code)).digest('hex')
}
