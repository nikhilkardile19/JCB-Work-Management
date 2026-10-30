import { execFileSync } from 'node:child_process'

try {
  process.loadEnvFile('.env')
} catch {
  // CI provides TEST_DATABASE_URL directly.
}

export const TEST_DATABASE_URL =
  process.env.TEST_DATABASE_URL ?? 'postgresql://postgres:postgres@localhost:5432/jcb_test'

/** Applies all migrations to the test database once per run. */
export default function setup() {
  execFileSync('npx', ['prisma', 'migrate', 'deploy'], {
    env: { ...process.env, DATABASE_URL: TEST_DATABASE_URL },
    stdio: 'pipe',
  })
}
