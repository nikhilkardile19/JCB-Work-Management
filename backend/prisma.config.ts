import { defineConfig } from 'prisma/config'

// Prisma 7 no longer reads .env by itself. Load it when present; hosts and CI
// provide DATABASE_URL in the environment instead.
try {
  process.loadEnvFile('.env')
} catch {
  // no .env file
}

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'tsx prisma/seed.ts',
  },
  datasource: {
    url: process.env.DATABASE_URL ?? '',
  },
})
