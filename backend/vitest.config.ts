import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'node',
    globalSetup: ['./tests/helpers/globalSetup.ts'],
    // All files share one PostgreSQL test database.
    fileParallelism: false,
    testTimeout: 20_000,
    hookTimeout: 60_000,
  },
})
