import { describe, it, expect, afterAll } from 'vitest';
import http from 'http';
import { io as Client } from 'socket.io-client';
import { createApp } from '../../app';
import { initSocketServer } from '../index';
import { generateAuthTokens } from '../../modules/auth/auth.utils';
import { presenceService } from '../presence.service';

describe('Socket.IO Live Integration Flows', () => {
  let server: http.Server;
  let cleanupFn: () => Promise<void>;
  let port: number;

  afterAll(async () => {
    if (cleanupFn) await cleanupFn();
    if (server) {
      server.closeAllConnections();
      await new Promise<void>((resolve) => server.close(() => resolve()));
    }
  });

  it('should reject unauthenticated socket connection and succeed with valid JWT', async () => {
    // Disable DB presence broadcasting during isolated live socket test
    presenceService.isBroadcastEnabled = false;

    const app = createApp();
    server = http.createServer(app);
    const { cleanup } = await initSocketServer(server, { useRedisAdapter: false });
    cleanupFn = cleanup;

    await new Promise<void>((resolve) => server.listen(0, resolve));
    port = (server.address() as { port: number }).port;
    const serverUrl = `http://localhost:${port}`;

    // 1. Attempt connection without token -> expect error
    await new Promise<void>((resolve, reject) => {
      const socketNoAuth = Client(serverUrl, {
        reconnection: false,
        timeout: 2000,
        transports: ['websocket'],
      });

      socketNoAuth.on('connect_error', (err) => {
        try {
          expect(err.message).toContain('Authentication error');
          socketNoAuth.disconnect();
          resolve();
        } catch (assertionErr) {
          socketNoAuth.disconnect();
          reject(assertionErr);
        }
      });

      socketNoAuth.on('connect', () => {
        socketNoAuth.disconnect();
        reject(new Error('Unauthenticated socket should not have connected'));
      });
    });

    // 2. Connect with valid access token
    const testUser = {
      userId: 'test-socket-integration-user-1',
      email: 'integration@synthox.health',
      username: 'integ_user',
    };
    const tokens = generateAuthTokens(testUser);

    await new Promise<void>((resolve, reject) => {
      const socketAuth = Client(serverUrl, {
        auth: { token: tokens.accessToken },
        reconnection: false,
        timeout: 2000,
        transports: ['websocket'],
      });

      socketAuth.on('connect_error', (err) => {
        socketAuth.disconnect();
        reject(err);
      });

      socketAuth.on('connect', () => {
        socketAuth.emit('presence:get', { userIds: [testUser.userId, 'other-user'] }, (ack: any) => {
          try {
            expect(ack.success).toBe(true);
            expect(ack.data).toBeTruthy();
            expect(ack.data[testUser.userId]).toBe('online');
            expect(ack.data['other-user']).toBe('offline');

            socketAuth.disconnect();
            resolve();
          } catch (ackErr) {
            socketAuth.disconnect();
            reject(ackErr);
          }
        });
      });
    });

    // Reset flag
    presenceService.isBroadcastEnabled = true;
  });
});
