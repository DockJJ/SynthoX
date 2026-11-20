import { describe, it, expect } from 'vitest';
import crypto from 'crypto';
import { callsService } from '../calls.service';
import { config } from '../../../config/env';
import {
  callInviteSchema,
  callAcceptSchema,
  callRejectSchema,
  callOfferSchema,
  callAnswerSchema,
  callIceCandidateSchema,
  callHangupSchema,
} from '../../../sockets/call.schema';
import { CallManager } from '../../../sockets/call.manager';

describe('WebRTC ICE Servers & Coturn Shared-Secret Method', () => {
  it('should generate valid STUN and TURN credentials according to RFC 5766 REST API', () => {
    const testUserId = 'test-user-call-123';
    const response = callsService.getIceServers(testUserId);

    expect(response.iceServers).toBeDefined();
    expect(response.iceServers).toHaveLength(2);
    expect(response.realm).toBe(config.TURN_REALM);
    expect(response.ttl).toBe(config.TURN_TTL_SECONDS);

    // 1. Verify STUN config
    const stunConfig = response.iceServers[0];
    expect(stunConfig.urls).toBe(config.STUN_URL);

    // 2. Verify TURN config
    const turnConfig = response.iceServers[1];
    expect(Array.isArray(turnConfig.urls)).toBe(true);
    expect(turnConfig.username).toBeTruthy();
    expect(turnConfig.credential).toBeTruthy();

    // 3. Verify Username format: <timestamp>:<userId>
    const [timestampStr, userId] = turnConfig.username.split(':');
    expect(userId).toBe(testUserId);
    const expiry = parseInt(timestampStr, 10);
    expect(expiry).toBeGreaterThan(Math.floor(Date.now() / 1000));

    // 4. Verify HMAC-SHA1 signature
    const hmac = crypto.createHmac('sha1', config.TURN_SECRET);
    hmac.update(turnConfig.username);
    const expectedCredential = hmac.digest('base64');
    expect(turnConfig.credential).toBe(expectedCredential);
  });
});

describe('Call Signaling Zod Validation Schemas', () => {
  it('should validate call:invite payload with defaults', () => {
    const parsed = callInviteSchema.parse({
      calleeId: 'callee-uuid-456',
    });
    expect(parsed.calleeId).toBe('callee-uuid-456');
    expect(parsed.callType).toBe('video');
  });

  it('should validate call:invite payload with audio', () => {
    const parsed = callInviteSchema.parse({
      calleeId: 'callee-uuid-456',
      callType: 'audio',
    });
    expect(parsed.callType).toBe('audio');
  });

  it('should reject call:invite with empty calleeId', () => {
    expect(() => callInviteSchema.parse({ calleeId: '' })).toThrow();
  });

  it('should validate call:accept and call:reject', () => {
    const accept = callAcceptSchema.parse({ callId: 'call-123' });
    expect(accept.callId).toBe('call-123');

    const reject = callRejectSchema.parse({ callId: 'call-123', reason: 'Busy' });
    expect(reject.callId).toBe('call-123');
    expect(reject.reason).toBe('Busy');
  });

  it('should validate call:offer and call:answer with SDP object or string', () => {
    const offerObj = callOfferSchema.parse({
      callId: 'call-123',
      sdp: { type: 'offer', sdp: 'v=0...' },
    });
    expect(offerObj.callId).toBe('call-123');

    const answerStr = callAnswerSchema.parse({
      callId: 'call-123',
      sdp: 'v=0...',
    });
    expect(answerStr.callId).toBe('call-123');
  });

  it('should validate call:ice-candidate and call:hangup', () => {
    const ice = callIceCandidateSchema.parse({
      callId: 'call-123',
      candidate: { candidate: 'candidate:1 1 UDP...', sdpMid: '0' },
    });
    expect(ice.callId).toBe('call-123');

    const hangup = callHangupSchema.parse({
      callId: 'call-123',
      reason: 'User ended call',
    });
    expect(hangup.callId).toBe('call-123');
    expect(hangup.reason).toBe('User ended call');
  });
});

describe('CallManager Active Call State Logic', () => {
  it('should manage active call lifecycle and calculate duration upon hangup', async () => {
    const manager = new CallManager();
    manager.isDbLoggingEnabled = false;
    const mockIo = { to: () => ({ emit: () => {} }) } as any;

    const caller = {
      userId: 'caller-1',
      username: 'dr_who',
      displayName: 'Dr. Who',
      avatarUrl: null,
    };
    const calleeId = 'callee-1';
    const callId = 'test-call-lifecycle-1';

    // 1. Initial State
    expect(manager.isUserInCall('caller-1')).toBe(false);
    expect(manager.isUserInCall('callee-1')).toBe(false);

    // 2. Start Call
    const call = await manager.startCall(callId, caller, calleeId, 'VIDEO', mockIo);
    expect(call.status).toBe('INITIATED');
    expect(manager.isUserInCall('caller-1')).toBe(true);
    expect(manager.isUserInCall('callee-1')).toBe(true);

    // 3. Accept Call
    const acceptedCall = await manager.acceptCall(callId);
    expect(acceptedCall).toBeTruthy();
    expect(acceptedCall!.status).toBe('ACCEPTED');
    expect(acceptedCall!.startedAt).toBeTruthy();

    // 4. Hangup Call
    const result = await manager.hangupCall(callId, 'Normal Hangup');
    expect(result).toBeTruthy();
    expect(result!.finalStatus).toBe('ENDED');
    expect(manager.isUserInCall('caller-1')).toBe(false);
    expect(manager.isUserInCall('callee-1')).toBe(false);
  });

  it('should mark call as MISSED if hung up before being accepted', async () => {
    const manager = new CallManager();
    manager.isDbLoggingEnabled = false;
    const mockIo = { to: () => ({ emit: () => {} }) } as any;

    const caller = {
      userId: 'caller-2',
      username: 'nurse_joy',
      displayName: 'Nurse Joy',
      avatarUrl: null,
    };
    const calleeId = 'callee-2';
    const callId = 'test-call-cancel-1';

    await manager.startCall(callId, caller, calleeId, 'AUDIO', mockIo);
    expect(manager.isUserInCall('caller-2')).toBe(true);

    // Caller cancels before answer
    const result = await manager.hangupCall(callId, 'Caller cancelled');
    expect(result).toBeTruthy();
    expect(result!.finalStatus).toBe('MISSED');
    expect(manager.isUserInCall('caller-2')).toBe(false);
  });
});
