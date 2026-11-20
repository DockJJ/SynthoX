import crypto from 'crypto';
import { config } from '../../config/env';
import { IceServersResponse } from './calls.types';

export class CallsService {
  /**
   * Generate ephemeral STUN & TURN credentials using coturn's shared-secret REST API method
   */
  getIceServers(userId: string): IceServersResponse {
    const ttl = config.TURN_TTL_SECONDS;
    const expiryTimestamp = Math.floor(Date.now() / 1000) + ttl;

    // Coturn REST API username format: <timestamp>:<username>
    const turnUsername = `${expiryTimestamp}:${userId}`;

    // HMAC-SHA1 signature of username with shared TURN secret
    const hmac = crypto.createHmac('sha1', config.TURN_SECRET);
    hmac.update(turnUsername);
    const turnCredential = hmac.digest('base64');

    const turnBase = config.TURN_URL.replace(/^turn:/i, '');

    return {
      realm: config.TURN_REALM,
      ttl,
      iceServers: [
        {
          urls: config.STUN_URL,
        },
        {
          urls: [
            `turn:${turnBase}?transport=udp`,
            `turn:${turnBase}?transport=tcp`,
          ],
          username: turnUsername,
          credential: turnCredential,
        },
      ],
    };
  }
}

export const callsService = new CallsService();
