import { Socket } from 'socket.io';
import { logger } from '../config/logger';

interface RateLimitEntry {
  count: number;
  resetAt: number;
}

export class SocketRateLimiter {
  private windows = new Map<string, RateLimitEntry>();
  private readonly maxEvents: number;
  private readonly windowMs: number;

  constructor(maxEvents = 30, windowMs = 5000) {
    this.maxEvents = maxEvents;
    this.windowMs = windowMs;
  }

  /**
   * Check if an incoming socket event exceeds rate limits
   * Returns true if allowed, false if rate limited
   */
  isAllowed(socketId: string): boolean {
    const now = Date.now();
    let entry = this.windows.get(socketId);

    if (!entry || now > entry.resetAt) {
      entry = {
        count: 1,
        resetAt: now + this.windowMs,
      };
      this.windows.set(socketId, entry);
      return true;
    }

    entry.count += 1;

    if (entry.count > this.maxEvents) {
      logger.warn({ socketId, count: entry.count }, 'Socket event rate limit exceeded');
      return false;
    }

    return true;
  }

  /**
   * Remove socket from tracking on disconnect
   */
  cleanup(socketId: string): void {
    this.windows.delete(socketId);
  }
}

export const socketRateLimiter = new SocketRateLimiter(30, 5000);

/**
 * Socket.IO middleware to rate limit incoming client packets
 */
export const socketRateLimitMiddleware = (socket: Socket, next: (err?: Error) => void): void => {
  // Intercept incoming packets on the socket
  socket.use((_packet, nextPacket) => {
    if (!socketRateLimiter.isAllowed(socket.id)) {
      socket.emit('error:rate-limit', {
        message: 'Rate limit exceeded. Please slow down your requests.',
      });
      return nextPacket(new Error('Rate limit exceeded'));
    }
    nextPacket();
  });

  next();
};
