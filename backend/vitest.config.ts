import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Use the default pool (threads via tinypool)
    globals: true,
    environment: 'node',
    include: ['src/**/__tests__/**/*.test.ts'],
    testTimeout: 15000,
    hookTimeout: 15000,
    // Load .env for test environment
    env: {
      NODE_ENV: 'test',
    },
  },
});
