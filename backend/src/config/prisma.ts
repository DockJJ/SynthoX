import { PrismaClient } from '@prisma/client';
import { logger } from './logger';
import { config } from './env';

declare global {
  // eslint-disable-next-line no-var
  var __prisma: PrismaClient | undefined;
}

export const prisma =
  global.__prisma ||
  new PrismaClient({
    log:
      config.NODE_ENV === 'development'
        ? [
            { emit: 'event', level: 'query' },
            { emit: 'event', level: 'error' },
            { emit: 'event', level: 'info' },
            { emit: 'event', level: 'warn' },
          ]
        : [{ emit: 'event', level: 'error' }],
  });

if (config.NODE_ENV === 'development') {
  global.__prisma = prisma;
}

// Log queries in development
if (config.NODE_ENV === 'development') {
  // @ts-expect-error Prisma event typing
  prisma.$on('query', (e: { query: string; params: string; duration: number }) => {
    logger.trace({ query: e.query, params: e.params, durationMs: e.duration }, 'Prisma Query');
  });
}

// @ts-expect-error Prisma event typing
prisma.$on('error', (e: { message: string }) => {
  logger.error({ message: e.message }, 'Prisma Error');
});
