import argon2 from 'argon2'

/** OWASP-recommended minimum for Argon2id (19 MiB, 2 iterations). */
const OPTIONS = { type: argon2.argon2id, memoryCost: 19_456, timeCost: 2, parallelism: 1 } as const

export const MIN_PASSWORD_LENGTH = 8
export const MAX_PASSWORD_LENGTH = 200

export const hashPassword = (password: string) => argon2.hash(password, OPTIONS)

export async function verifyPassword(hash: string, password: string): Promise<boolean> {
  try {
    return await argon2.verify(hash, password)
  } catch {
    return false
  }
}

export const needsRehash = (hash: string) => argon2.needsRehash(hash, OPTIONS)

let dummy: Promise<string> | null = null

/**
 * Spends the same time as a real check when the account does not exist or
 * has no password, so response times don't reveal which emails exist.
 */
export async function burnVerifyTime(password: string) {
  dummy ??= hashPassword('not-a-real-password')
  await verifyPassword(await dummy, password)
}
