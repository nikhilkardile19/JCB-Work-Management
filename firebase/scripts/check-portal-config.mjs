// Hosting predeploy check: the portal must know its API, and the CSP must
// allow the browser to call it. Refuses to publish an unconfigured portal.
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const firebaseDir = join(dirname(fileURLToPath(import.meta.url)), '..')
const fail = (message) => {
  console.error(`Portal deploy refused: ${message}`)
  process.exit(1)
}

let env = ''
try {
  env = readFileSync(join(firebaseDir, '..', 'admin', '.env.local'), 'utf8')
} catch {
  fail('admin/.env.local is missing (see admin/.env.example).')
}
const apiUrl = /^VITE_API_BASE_URL=(.+)$/m.exec(env)?.[1]?.trim()
if (!apiUrl) fail('admin/.env.local has no VITE_API_BASE_URL.')
let origin
try {
  origin = new URL(apiUrl).origin
} catch {
  fail(`VITE_API_BASE_URL is not a URL: ${apiUrl}`)
}
if (!origin.startsWith('https://')) fail(`the API must be served over HTTPS (got ${origin}).`)

const config = JSON.parse(readFileSync(join(firebaseDir, 'firebase.json'), 'utf8'))
const csp = config.hosting.headers
  .flatMap((h) => h.headers)
  .find((h) => h.key === 'Content-Security-Policy')?.value ?? ''
const connectSrc = /connect-src([^;]*)/.exec(csp)?.[1].trim().split(/\s+/) ?? []
if (!connectSrc.includes(origin)) {
  fail(`add ${origin} to connect-src of the Content-Security-Policy in firebase/firebase.json.`)
}
console.log(`Portal config OK: API ${origin}`)
