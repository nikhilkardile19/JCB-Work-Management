/**
 * Structural equality for JSON values: object keys in any order, arrays in
 * order, numbers by value. Used to compare a pushed record with the stored
 * one (the rules' `onlyChanged`).
 */
export function deepEqual(a: unknown, b: unknown): boolean {
  if (a === b) return true
  if (a == null || b == null) return a == b
  if (Array.isArray(a) || Array.isArray(b)) {
    return Array.isArray(a) && Array.isArray(b) && a.length === b.length && a.every((v, i) => deepEqual(v, b[i]))
  }
  if (typeof a === 'object' && typeof b === 'object') {
    const ka = Object.keys(a as object)
    const kb = Object.keys(b as object)
    const keys = new Set([...ka, ...kb])
    for (const k of keys) {
      if (!deepEqual((a as Record<string, unknown>)[k], (b as Record<string, unknown>)[k])) return false
    }
    return true
  }
  return false
}
