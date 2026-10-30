import { PrismaPg } from '@prisma/adapter-pg'
import { Prisma, PrismaClient } from '../generated/prisma/client.js'

export { Prisma }
export type Db = PrismaClient
export type Tx = Prisma.TransactionClient

export function createPrisma(connectionString: string, max = 10): Db {
  return new PrismaClient({ adapter: new PrismaPg({ connectionString, max }) })
}

/** Prisma error code, if [e] is a known request error (P2002 unique, P2003 FK, …). */
export function prismaCode(e: unknown): string | null {
  return e instanceof Prisma.PrismaClientKnownRequestError ? e.code : null
}
