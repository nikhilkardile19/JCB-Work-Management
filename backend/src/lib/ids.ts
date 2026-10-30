import { createHash, randomBytes, randomUUID } from 'node:crypto'

export const newId = (): string => randomUUID()

/** URL-safe random secret (refresh and reset tokens). */
export const randomToken = (bytes = 32): string => randomBytes(bytes).toString('base64url')

export const sha256 = (value: string): string => createHash('sha256').update(value).digest('hex')
