import { Server as HttpServer } from 'http';
import { Server, ServerOptions } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { config } from '../config/env';
import { logger } from '../config/logger';
import { createRedisClient } from '../config/redis';
import { socketAuthMiddleware } from './socket.auth';
import { registerChatHandlers } from './chat.handler';
import { registerCallHandlers } from './call.handler';
import { presenceService } from './presence.service';
import { callManager } from './call.manager';
import { socketRateLimitMiddleware, socketRateLimiter } from './socket.limiter';
import { AuthenticatedSocket } from './socket.types';

export interface SocketServerInstance {
  io: Server;
  cleanup: () => Promise<void>;
}

export interface InitSocketOptions {
  useRedisAdapter?: boolean;
}

export const initSocketServer = async (
  httpServer: HttpServer,
  options: InitSocketOptions = {}
): Promise<SocketServerInstance> => {
  const serverOptions: Partial<ServerOptions> = {
    cors: {
      origin: config.CORS_ORIGIN === '*' ? '*' : config.CORS_ORIGIN.split(',').map((o) => o.trim()),
      methods: ['GET', 'POST'],
      credentials: true,
    },
    pingInterval: 10000,
    pingTimeout: 5000,
    maxHttpBufferSize: 1e5, // 100 KB — reject oversized socket payloads
  };

  const io = new Server(httpServer, serverOptions);

  let pubClient: ReturnType<typeof createRedisClient> | null = null;
  let subClient: ReturnType<typeof createRedisClient> | null = null;

  const shouldAttachRedis =
    options.useRedisAdapter !== false && config.NODE_ENV !== 'test';

  if (shouldAttachRedis) {
    try {
      pubClient = createRedisClient('socketio-pub');
      subClient = createRedisClient('socketio-sub');

      // Handle connection errors gracefully without crashing the process
      pubClient.on('error', (err) => {
        logger.debug({ err: err.message }, 'Socket.IO Redis pubClient error');
      });
      subClient.on('error', (err) => {
        logger.debug({ err: err.message }, 'Socket.IO Redis subClient error');
      });

      io.adapter(createAdapter(pubClient, subClient));
      logger.info('Socket.IO configured with Redis adapter');
    } catch (err) {
      logger.warn({ err }, 'Failed to initialize Redis adapter for Socket.IO. Falling back to in-memory adapter');
    }
  }

  // 1. Handshake Authentication Middleware
  io.use(socketAuthMiddleware);

  // 2. Connection Lifecycle
  io.on('connection', async (rawSocket) => {
    const socket = rawSocket as AuthenticatedSocket;
    const user = socket.data.user;

    // Apply per-socket packet rate limiting
    socketRateLimitMiddleware(socket, (err) => {
      if (err) {
        logger.warn({ socketId: socket.id, userId: user.userId }, 'Socket rate limit middleware error');
      }
    });

    logger.info(
      { socketId: socket.id, userId: user.userId, username: user.username },
      'User connected to socket'
    );

    // Join personal user room: user:<id>
    const userRoom = `user:${user.userId}`;
    socket.join(userRoom);

    // Track presence in Redis / memory
    try {
      const isFirstConnection = await presenceService.userConnected(user.userId, socket.id);
      if (isFirstConnection) {
        await presenceService.broadcastPresence(io, user.userId, 'online');
      }
    } catch (err) {
      logger.error({ err, userId: user.userId }, 'Failed to update presence on connect');
    }

    // Register Chat Handlers (message:send, message:delivered, message:read, typing:*, presence:get)
    registerChatHandlers(io, socket);

    // Register WebRTC Call Signaling Handlers (call:invite, call:accept, call:reject, call:offer, etc.)
    registerCallHandlers(io, socket);

    // Disconnect handler
    socket.on('disconnect', async (reason) => {
      logger.info(
        { socketId: socket.id, userId: user.userId, reason },
        'User disconnected from socket'
      );

      // Clean up rate limiter tracking for this socket
      socketRateLimiter.cleanup(socket.id);

      // Handle mid-call disconnect: notify partner and log call end
      try {
        await callManager.handleUserDisconnect(user.userId, io);
      } catch (err) {
        logger.error({ err, userId: user.userId }, 'Error handling call disconnect');
      }

      // Update presence
      try {
        const isLastConnection = await presenceService.userDisconnected(user.userId, socket.id);
        if (isLastConnection) {
          await presenceService.broadcastPresence(io, user.userId, 'offline');
        }
      } catch (err) {
        logger.error({ err, userId: user.userId }, 'Failed to update presence on disconnect');
      }
    });
  });

  const cleanup = async (): Promise<void> => {
    logger.info('Closing Socket.IO connections...');
    io.disconnectSockets(true);
    io.close();
    if (pubClient) {
      pubClient.disconnect();
    }
    if (subClient) {
      subClient.disconnect();
    }
  };

  return { io, cleanup };
};
