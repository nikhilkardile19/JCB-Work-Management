/**
 * Guards "read-only by construction": only src/firebaseSource.ts may open
 * Firebase (codec.ts may import its value classes), and neither may call a
 * Firestore or Auth write API. Run by `npm run check`.
 */
import { readdir, readFile } from 'node:fs/promises'
import { join } from 'node:path'

const SRC = new URL('../src/', import.meta.url).pathname
const MAY_IMPORT_FIREBASE = new Set(['firebaseSource.ts', 'codec.ts'])
const MAY_OPEN_FIREBASE = new Set(['firebaseSource.ts'])
const WRITE_API =
  /\.\s*(set|update|delete|create|add|commit|batch|bulkWriter|runTransaction|recursiveDelete|createUser|updateUser|deleteUsers?|importUsers|setCustomUserClaims|revokeRefreshTokens|createCustomToken|createSessionCookie|generate\w*Link|\w*ProviderConfig|\w*Tenant)\s*\(/g

const problems: string[] = []
for (const file of (await readdir(SRC)).filter((f) => f.endsWith('.ts'))) {
  const text = await readFile(join(SRC, file), 'utf8')
  const code = text.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/.*$/gm, '')
  if (/from\s+['"]firebase-admin/.test(code) && !MAY_IMPORT_FIREBASE.has(file)) problems.push(`${file} imports firebase-admin`)
  if (/\b(getFirestore|getAuth|initializeApp)\s*\(/.test(code) && !MAY_OPEN_FIREBASE.has(file)) problems.push(`${file} opens Firebase`)
  if (MAY_IMPORT_FIREBASE.has(file)) {
    for (const m of code.matchAll(WRITE_API)) problems.push(`${file}: write API ${m[0].trim()}`)
  }
}
if (problems.length) {
  console.error(`Read-only check failed:\n  ${problems.join('\n  ')}`)
  process.exit(1)
}
console.log('Read-only check passed: Firebase is opened only in src/firebaseSource.ts, which calls no write API.')
