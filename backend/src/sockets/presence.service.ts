import { Server } from 'socket.io';
import { redisClient } from '../config/redis';
import { prisma } from '../config/prisma';
import { logger } from '../config/logger';

export class PresenceService {
  // Flag to enable/disable DB lookup during presence broadcasts (useful for offline test runs)
  public isBroadcastEnabled = true;

  // In-memory fallback tracking in case Redis is not connected
  private memoryConnections = new Map<string, Set<string>>();

  private isRedisReady(): boolean {
    return redisClient.status === 'ready' || redisClient.status === 'connect';
  }

  /**
   * Register a user socket connection.
   * Returns true if user just transitioned from offline to online.
   */
  async userConnected(userId: string, socketId: string): Promise<boolean> {
    let isFirstConnection = false;

    if (this.isRedisReady()) {
      try {
        const key = `presence:connections:${userId}`;
        const prevCount = await redisClient.scard(key);
        await redisClient.sadd(key, socketId);
        await redisClient.set(`presence:status:${userId}`, 'online');

        isFirstConnection = prevCount === 0;
        return isFirstConnection;
      } catch (err) {
        logger.warn({ err }, 'Redis presence write failed, falling back to memory');
      }
    }

    // In-memory fallback
    let sockets = this.memoryConnections.get(userId);
    if (!sockets) {
      sockets = new Set();
      this.memoryConnections.set(userId, sockets);
      isFirstConnection = true;
    }
    sockets.add(socketId);

    return isFirstConnection;
  }

  /**
   * Unregister a user socket connection.
   * Returns true if user just transitioned from online to offline.
   */
  async userDisconnected(userId: string, socketId: string): Promise<boolean> {
    let isLastConnection = false;

    if (this.isRedisReady()) {
      try {
        const key = `presence:connections:${userId}`;
        await redisClient.srem(key, socketId);
        const remaining = await redisClient.scard(key);

        if (remaining === 0) {
          await redisClient.del(`presence:status:${userId}`);
          isLastConnection = true;
        }
        return isLastConnection;
      } catch (err) {
        logger.warn({ err }, 'Redis presence remove failed, falling back to memory');
      }
    }

    // In-memory fallback
    const sockets = this.memoryConnections.get(userId);
    if (sockets) {
      sockets.delete(socketId);
      if (sockets.size === 0) {
        this.memoryConnections.delete(userId);
        isLastConnection = true;
      }
    }

    return isLastConnection;
  }

  /**
   * Check if a specific user is currently online
   */
  async isUserOnline(userId: string): Promise<boolean> {
    if (this.isRedisReady()) {
      try {
        const status = await redisClient.get(`presence:status:${userId}`);
        return status === 'online';
      } catch {
        // fallback
      }
    }

    const sockets = this.memoryConnections.get(userId);
    return !!sockets && sockets.size > 0;
  }

  /**
   * Query online status for multiple user IDs
   */
  async getMultiplePresence(userIds: string[]): Promise<Record<string, 'online' | 'offline'>> {
    const result: Record<string, 'online' | 'offline'> = {};

    if (userIds.length === 0) return result;

    if (this.isRedisReady()) {
      try {
        const pipeline = redisClient.pipeline();
        for (const uid of userIds) {
          pipeline.get(`presence:status:${uid}`);
        }
        const responses = await pipeline.exec();

        userIds.forEach((uid, index) => {
          const val = responses?.[index]?.[1];
          result[uid] = val === 'online' ? 'online' : 'offline';
        });

        return result;
      } catch {
        // fallback
      }
    }

    // In-memory fallback
    for (const uid of userIds) {
      result[uid] = this.memoryConnections.has(uid) ? 'online' : 'offline';
    }

    return result;
  }

  /**
   * Broadcast presence status update to all users that share a conversation with this user
   */
  async broadcastPresence(
    io: Server,
    userId: string,
    status: 'online' | 'offline'
  ): Promise<void> {
    if (!this.isBroadcastEnabled) {
      return;
    }

    try {
      const userConversations = await prisma.conversationMember.findMany({
        where: { userId },
        select: { conversationId: true },
      });

      if (!userConversations || userConversations.length === 0) return;

      const convIds = userConversations.map((c) => c.conversationId);

      const contacts = await prisma.conversationMember.findMany({
        where: {
          conversationId: { in: convIds },
          userId: { not: userId },
        },
        select: { userId: true },
        distinct: ['userId'],
      });

      const payload = {
        userId,
        status,
        lastSeen: new Date().toISOString(),
      };

      for (const contact of contacts) {
        io.to(`user:${contact.userId}`).emit('presence:update', payload);
      }

      logger.debug(
        { userId, status, contactCount: contacts.length },
        'Presence update broadcasted'
      );
    } catch (err) {
      logger.debug({ err: err instanceof Error ? err.message : err, userId }, 'Skipping presence broadcast');
    }
  }
}

export const presenceService = new PresenceService();
