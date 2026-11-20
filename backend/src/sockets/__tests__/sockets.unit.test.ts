import { describe, it, expect } from 'vitest';
import {
  sendMessageSchema,
  messageDeliveredSchema,
  messageReadSchema,
  typingSchema,
  presenceGetSchema,
} from '../socket.schema';
import { PresenceService } from '../presence.service';
import { socketAuthMiddleware } from '../socket.auth';
import { generateAuthTokens } from '../../modules/auth/auth.utils';
import { Socket } from 'socket.io';

describe('Socket Zod Validation Schemas', () => {
  it('should validate valid sendMessage payload', () => {
    const input = {
      conversationId: 'conv-12345',
      content: 'Hello doctor, I am ready for consultation.',
      tempId: 'temp-abc',
    };
    const parsed = sendMessageSchema.parse(input);
    expect(parsed.conversationId).toBe('conv-12345');
    expect(parsed.content).toBe('Hello doctor, I am ready for consultation.');
    expect(parsed.tempId).toBe('temp-abc');
  });

  it('should reject empty message content', () => {
    expect(() => sendMessageSchema.parse({ conversationId: 'conv-12345', content: '' })).toThrow();
  });

  it('should reject message content exceeding 10000 characters', () => {
    expect(() =>
      sendMessageSchema.parse({ conversationId: 'conv-12345', content: 'a'.repeat(10001) })
    ).toThrow();
  });

  it('should validate messageDelivered schema', () => {
    const parsed = messageDeliveredSchema.parse({
      messageId: 'msg-123',
      conversationId: 'conv-123',
    });
    expect(parsed.messageId).toBe('msg-123');
    expect(parsed.conversationId).toBe('conv-123');
  });

  it('should validate messageRead schema', () => {
    const parsed = messageReadSchema.parse({ conversationId: 'conv-123' });
    expect(parsed.conversationId).toBe('conv-123');
  });

  it('should validate typing schema', () => {
    const parsed = typingSchema.parse({ conversationId: 'conv-123' });
    expect(parsed.conversationId).toBe('conv-123');
  });

  it('should validate presenceGet schema', () => {
    const parsed = presenceGetSchema.parse({ userIds: ['user-1', 'user-2'] });
    expect(parsed.userIds).toHaveLength(2);
  });
});

describe('PresenceService Logic', () => {
  it('should track user multi-socket connections and offline transitions', async () => {
    const presence = new PresenceService();
    const testUserId = 'test-presence-user-1';

    // 1. First connection -> should return true (transitioned to online)
    const firstConn = await presence.userConnected(testUserId, 'socket-1');
    expect(firstConn).toBe(true);

    const isOnline1 = await presence.isUserOnline(testUserId);
    expect(isOnline1).toBe(true);

    // 2. Second connection from another tab/device -> should return false (already online)
    const secondConn = await presence.userConnected(testUserId, 'socket-2');
    expect(secondConn).toBe(false);

    // 3. Disconnect first socket -> user is still online on second socket
    const firstDisconn = await presence.userDisconnected(testUserId, 'socket-1');
    expect(firstDisconn).toBe(false);

    const isOnline2 = await presence.isUserOnline(testUserId);
    expect(isOnline2).toBe(true);

    // 4. Disconnect second socket -> user is now completely offline
    const lastDisconn = await presence.userDisconnected(testUserId, 'socket-2');
    expect(lastDisconn).toBe(true);

    const isOnline3 = await presence.isUserOnline(testUserId);
    expect(isOnline3).toBe(false);
  });

  it('should batch query presence for multiple users', async () => {
    const presence = new PresenceService();
    const u1 = 'batch-user-1';
    const u2 = 'batch-user-2';

    await presence.userConnected(u1, 'sock-u1');

    const statuses = await presence.getMultiplePresence([u1, u2]);
    expect(statuses[u1]).toBe('online');
    expect(statuses[u2]).toBe('offline');

    await presence.userDisconnected(u1, 'sock-u1');
  });
});

describe('Socket Handshake Authentication Middleware', () => {
  it('should authenticate socket via handshake auth.token', () => {
    return new Promise<void>((resolve, reject) => {
      const tokens = generateAuthTokens({
        userId: 'test-socket-user-1',
        email: 'socket@synthox.health',
        username: 'socket_user',
      });

      const mockSocket = {
        id: 'mock-socket-1',
        handshake: {
          auth: { token: tokens.accessToken },
          headers: {},
        },
        data: {},
      } as unknown as Socket;

      socketAuthMiddleware(mockSocket, (err) => {
        try {
          expect(err).toBeUndefined();
          expect(mockSocket.data.user).toBeTruthy();
          expect(mockSocket.data.user.userId).toBe('test-socket-user-1');
          expect(mockSocket.data.user.username).toBe('socket_user');
          resolve();
        } catch (e) {
          reject(e);
        }
      });
    });
  });

  it('should authenticate socket via handshake authorization header', () => {
    return new Promise<void>((resolve, reject) => {
      const tokens = generateAuthTokens({
        userId: 'test-socket-user-2',
        email: 'socket2@synthox.health',
        username: 'socket_user_2',
      });

      const mockSocket = {
        id: 'mock-socket-2',
        handshake: {
          auth: {},
          headers: { authorization: `Bearer ${tokens.accessToken}` },
        },
        data: {},
      } as unknown as Socket;

      socketAuthMiddleware(mockSocket, (err) => {
        try {
          expect(err).toBeUndefined();
          expect(mockSocket.data.user).toBeTruthy();
          expect(mockSocket.data.user.userId).toBe('test-socket-user-2');
          resolve();
        } catch (e) {
          reject(e);
        }
      });
    });
  });

  it('should reject connection when token is missing', () => {
    return new Promise<void>((resolve, reject) => {
      const mockSocket = {
        id: 'mock-socket-3',
        handshake: { auth: {}, headers: {} },
        data: {},
      } as unknown as Socket;

      socketAuthMiddleware(mockSocket, (err) => {
        try {
          expect(err).toBeInstanceOf(Error);
          expect(err!.message).toContain('Missing access token');
          resolve();
        } catch (e) {
          reject(e);
        }
      });
    });
  });

  it('should reject connection when token is invalid or tampered', () => {
    return new Promise<void>((resolve, reject) => {
      const mockSocket = {
        id: 'mock-socket-4',
        handshake: {
          auth: { token: 'invalid.tampered.token' },
          headers: {},
        },
        data: {},
      } as unknown as Socket;

      socketAuthMiddleware(mockSocket, (err) => {
        try {
          expect(err).toBeInstanceOf(Error);
          expect(err!.message).toContain('Authentication error');
          resolve();
        } catch (e) {
          reject(e);
        }
      });
    });
  });
});
