import http from 'http';
import { createApp } from './app';
import { config } from './config/env';
import { logger } from './config/logger';
import { redisClient } from './config/redis';
import { prisma } from './config/prisma';
import { initSocketServer } from './sockets';

const startServer = async () => {
  const app = createApp();
  const server = http.createServer(app);

  // Initialize Socket.IO
  const { cleanup: cleanupSockets } = await initSocketServer(server);

  server.listen(config.PORT, config.HOST, () => {
    logger.info(
      {
        host: config.HOST,
        port: config.PORT,
        env: config.NODE_ENV,
        health: `http://${config.HOST === '0.0.0.0' ? 'localhost' : config.HOST}:${config.PORT}/health`,
      },
      '🚀 SynthoX Server listening'
    );
  });

  // Graceful shutdown handling
  let isShuttingDown = false;

  const gracefulShutdown = async (signal: string) => {
    if (isShuttingDown) return;
    isShuttingDown = true;

    logger.info({ signal }, 'Graceful shutdown initiated. Closing services...');

    // Immediately stop accepting new connections and kill keep-alive sockets
    server.closeAllConnections();

    // Stop accepting new HTTP requests
    server.close(async (err) => {
      if (err) {
        logger.error({ err }, 'Error closing HTTP server');
        process.exit(1);
      }

      try {
        // 1. Close all Socket.IO connections and their Redis pub/sub clients
        await cleanupSockets();

        // 2. Disconnect the main Redis client
        await redisClient.quit().catch(() => {});

        // 3. Disconnect Prisma from PostgreSQL
        await prisma.$disconnect().catch(() => {});

        logger.info('All resources released cleanly. Exiting.');
        process.exit(0);
      } catch (cleanupErr) {
        logger.error({ cleanupErr }, 'Error during shutdown cleanup');
        process.exit(1);
      }
    });

    // Force shutdown if cleanup takes too long (10 seconds)
    setTimeout(() => {
      logger.error('Forced shutdown due to timeout');
      process.exit(1);
    }, 10000).unref();
  };

  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));

  process.on('unhandledRejection', (reason) => {
    logger.fatal({ reason }, 'Unhandled Promise Rejection');
  });

  process.on('uncaughtException', (error) => {
    logger.fatal({ err: error }, 'Uncaught Exception');
    process.exit(1);
  });
};

startServer().catch((err) => {
  logger.fatal({ err }, 'Failed to start SynthoX server');
  process.exit(1);
});
