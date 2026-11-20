import Redis from 'ioredis';
import { config } from './env';
import { logger } from './logger';

export const createRedisClient = (name: string): Redis => {
  const client = new Redis(config.REDIS_URL, {
    lazyConnect: true,
    maxRetriesPerRequest: 1,
    enableReadyCheck: false,
    retryStrategy: (times) => {
      if (process.env.NODE_ENV === 'test' || times > 1) {
        return null; // Stop retrying immediately if Redis is unreachable
      }
      return 200;
    },
  });

  client.on('connect', () => {
    logger.info({ name }, 'Redis connection established');
  });

  client.on('error', (err) => {
    logger.warn({ name, err: err.message }, 'Redis connection unavailable');
  });

  return client;
};

// Singleton Redis instance for caching / presence
export const redisClient = createRedisClient('default-redis');
