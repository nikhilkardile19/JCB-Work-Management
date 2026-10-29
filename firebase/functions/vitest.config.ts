import { defineConfig } from 'vitest/config'

// Test files share one Firestore emulator and clear it between tests.
export default defineConfig({ test: { fileParallelism: false, testTimeout: 30000 } })
