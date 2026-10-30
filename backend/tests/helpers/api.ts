import type { DeveloperAdmin } from '../../src/generated/prisma/client.js'
import { createUser, tokens } from './factories.js'
import type { TestEnv } from './testApp.js'

type Method = 'get' | 'post' | 'put' | 'patch' | 'delete'

/** Authenticated JSON calls as a given user (tokens cached per test file). */
export function apiAs(env: TestEnv) {
  const token = tokens(env)
  return async (uid: string, method: Method, path: string, body?: object, headers: Record<string, string> = {}) => {
    const auth = `Bearer ${await token(uid)}`
    let req = env.request[method](`/api/v1${path}`).set('Authorization', auth)
    for (const [k, v] of Object.entries(headers)) req = req.set(k, v)
    return body === undefined ? req : req.send(body)
  }
}

export async function createAdmin(env: TestEnv, uid: string, role: DeveloperAdmin['role'] = 'super', permissions: string[] = []) {
  if (!(await env.db.user.findUnique({ where: { id: uid } }))) await createUser(env.db, uid)
  await env.db.developerAdmin.create({ data: { userId: uid, role, permissions } })
}
