import dotenv from 'dotenv';
import { z } from 'zod';

// Load environment variables from .env file
dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(5000),
  HOST: z.string().default('0.0.0.0'),
  CORS_ORIGIN: z.string().default('*'),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),

  // Database
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),

  // Redis
  REDIS_URL: z.string().default('redis://localhost:6379'),

  // JWT
  JWT_ACCESS_SECRET: z.string().min(32, 'JWT_ACCESS_SECRET must be at least 32 characters'),
  JWT_REFRESH_SECRET: z.string().min(32, 'JWT_REFRESH_SECRET must be at least 32 characters'),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('30d'),

  // WebRTC STUN/TURN
  TURN_SECRET: z.string().min(16, 'TURN_SECRET is required and must be secure'),
  TURN_REALM: z.string().default('synthox.local'),
  STUN_URL: z.string().default('stun:localhost:3478'),
  TURN_URL: z.string().default('turn:localhost:3478'),
  TURN_TTL_SECONDS: z.coerce.number().default(86400),
});

const parseEnv = () => {
  const result = envSchema.safeParse(process.env);

  if (!result.success) {
    const errorDetails = result.error.errors.map(
      (err) => `  - ${err.path.join('.')}: ${err.message}`
    ).join('\n');
    console.error(`\n❌ Invalid environment configuration:\n${errorDetails}\n`);
    process.exit(1);
  }

  return result.data;
};

export const config = parseEnv();
export type Config = typeof config;
