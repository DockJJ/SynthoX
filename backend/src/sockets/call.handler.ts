import { Server } from 'socket.io';
import crypto from 'crypto';
import { AuthenticatedSocket } from './socket.types';
import {
  callInviteSchema,
  callAcceptSchema,
  callRejectSchema,
  callOfferSchema,
  callAnswerSchema,
  callIceCandidateSchema,
  callHangupSchema,
} from './call.schema';
import { callManager } from './call.manager';
import { presenceService } from './presence.service';
import { prisma } from '../config/prisma';
import { logger } from '../config/logger';
import { CallType } from './call.types';

export const registerCallHandlers = (io: Server, socket: AuthenticatedSocket): void => {
  const user = socket.data.user;

  // 1. call:invite
  socket.on('call:invite' as any, async (rawPayload: unknown, callback?: (res: any) => void) => {
    try {
      const data = callInviteSchema.parse(rawPayload);
      const callType: CallType = data.callType.toUpperCase() as CallType;

      // Edge case: Cannot call self
      if (data.calleeId === user.userId) {
        if (callback) callback({ success: false, error: 'Cannot call yourself' });
        return;
      }

      // Edge case: Caller is already in another call
      if (callManager.isUserInCall(user.userId)) {
        if (callback) {
          callback({ success: false, error: 'You are already in an active call' });
        }
        return;
      }

      // Edge case: Callee is busy in another call
      if (callManager.isUserInCall(data.calleeId)) {
        await callManager.logBusy(user.userId, data.calleeId, callType);

        socket.emit('call:busy' as any, {
          calleeId: data.calleeId,
          reason: 'User is currently on another call',
        });

        if (callback) {
          callback({ success: false, reason: 'callee_busy' });
        }
        return;
      }

      // Edge case: Callee is offline
      const isOnline = await presenceService.isUserOnline(data.calleeId);
      if (!isOnline) {
        await callManager.logOffline(user.userId, data.calleeId, callType);

        socket.emit('call:reject' as any, {
          calleeId: data.calleeId,
          reason: 'User is offline',
        });

        if (callback) {
          callback({ success: false, reason: 'callee_offline' });
        }
        return;
      }

      // Fetch caller display name and avatar
      let displayName = user.username;
      let avatarUrl: string | null = null;

      try {
        const callerRecord = await prisma.user.findUnique({
          where: { id: user.userId },
          select: { displayName: true, avatarUrl: true },
        });
        if (callerRecord) {
          displayName = callerRecord.displayName;
          avatarUrl = callerRecord.avatarUrl;
        }
      } catch {
        // use fallback username
      }

      const callId = crypto.randomUUID();

      await callManager.startCall(
        callId,
        {
          userId: user.userId,
          username: user.username,
          displayName,
          avatarUrl,
        },
        data.calleeId,
        callType,
        io
      );

      // Relay call invite to callee's personal room
      io.to(`user:${data.calleeId}`).emit('call:invite' as any, {
        callId,
        callerId: user.userId,
        callerUsername: user.username,
        callerDisplayName: displayName,
        callerAvatarUrl: avatarUrl,
        callType: data.callType,
      });

      if (callback) {
        callback({
          success: true,
          data: {
            callId,
            status: 'ringing',
          },
        });
      }

      logger.info(
        { callId, callerId: user.userId, calleeId: data.calleeId, callType },
        'Call invitation dispatched'
      );
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to initiate call';
      logger.warn({ error: errorMsg, userId: user.userId }, 'call:invite error');
      if (callback) callback({ success: false, error: errorMsg });
    }
  });

  // 2. call:accept
  socket.on('call:accept' as any, async (rawPayload: unknown, callback?: (res: any) => void) => {
    try {
      const data = callAcceptSchema.parse(rawPayload);
      const call = callManager.getCall(data.callId);

      if (!call || call.calleeId !== user.userId) {
        if (callback) callback({ success: false, error: 'Call not found or unauthorized' });
        return;
      }

      await callManager.acceptCall(data.callId);

      // Relay acceptance to the caller
      io.to(`user:${call.callerId}`).emit('call:accept' as any, {
        callId: data.callId,
        calleeId: user.userId,
      });

      if (callback) {
        callback({ success: true, data: { callId: data.callId, status: 'connected' } });
      }

      logger.info({ callId: data.callId, calleeId: user.userId }, 'Call accepted');
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to accept call';
      if (callback) callback({ success: false, error: errorMsg });
    }
  });

  // 3. call:reject
  socket.on('call:reject' as any, async (rawPayload: unknown, callback?: (res: any) => void) => {
    try {
      const data = callRejectSchema.parse(rawPayload);
      const call = callManager.getCall(data.callId);

      if (!call || call.calleeId !== user.userId) {
        if (callback) callback({ success: false, error: 'Call not found or unauthorized' });
        return;
      }

      await callManager.rejectCall(data.callId, data.reason);

      // Relay rejection to the caller
      io.to(`user:${call.callerId}`).emit('call:reject' as any, {
        callId: data.callId,
        calleeId: user.userId,
        reason: data.reason,
      });

      if (callback) {
        callback({ success: true, data: { callId: data.callId, status: 'rejected' } });
      }

      logger.info({ callId: data.callId, calleeId: user.userId, reason: data.reason }, 'Call rejected');
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to reject call';
      if (callback) callback({ success: false, error: errorMsg });
    }
  });

  // 4. call:offer (WebRTC SDP Offer)
  socket.on('call:offer' as any, (rawPayload: unknown, callback?: (res: any) => void) => {
    try {
      const data = callOfferSchema.parse(rawPayload);
      const call = callManager.getCall(data.callId);

      if (!call) {
        if (callback) callback({ success: false, error: 'Active call not found' });
        return;
      }

      const targetId = call.callerId === user.userId ? call.calleeId : call.callerId;

      io.to(`user:${targetId}`).emit('call:offer' as any, {
        callId: data.callId,
        sdp: data.sdp,
        senderId: user.userId,
      });

      if (callback) callback({ success: true });
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to relay offer';
      if (callback) callback({ success: false, error: errorMsg });
    }
  });

  // 5. call:answer (WebRTC SDP Answer)
  socket.on('call:answer' as any, (rawPayload: unknown, callback?: (res: any) => void) => {
    try {
      const data = callAnswerSchema.parse(rawPayload);
      const call = callManager.getCall(data.callId);

      if (!call) {
        if (callback) callback({ success: false, error: 'Active call not found' });
        return;
      }

      const targetId = call.callerId === user.userId ? call.calleeId : call.callerId;

      io.to(`user:${targetId}`).emit('call:answer' as any, {
        callId: data.callId,
        sdp: data.sdp,
        senderId: user.userId,
      });

      if (callback) callback({ success: true });
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to relay answer';
      if (callback) callback({ success: false, error: errorMsg });
    }
  });

  // 6. call:ice-candidate (WebRTC ICE Candidate)
  socket.on('call:ice-candidate' as any, (rawPayload: unknown, callback?: (res: any) => void) => {
    try {
      const data = callIceCandidateSchema.parse(rawPayload);
      const call = callManager.getCall(data.callId);

      if (!call) {
        if (callback) callback({ success: false, error: 'Active call not found' });
        return;
      }

      const targetId = call.callerId === user.userId ? call.calleeId : call.callerId;

      io.to(`user:${targetId}`).emit('call:ice-candidate' as any, {
        callId: data.callId,
        candidate: data.candidate,
        senderId: user.userId,
      });

      if (callback) callback({ success: true });
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to relay ICE candidate';
      if (callback) callback({ success: false, error: errorMsg });
    }
  });

  // 7. call:hangup
  socket.on('call:hangup' as any, async (rawPayload: unknown, callback?: (res: any) => void) => {
    try {
      const data = callHangupSchema.parse(rawPayload);
      const call = callManager.getCall(data.callId);

      if (!call) {
        if (callback) callback({ success: true, message: 'Call already ended' });
        return;
      }

      const partnerId = call.callerId === user.userId ? call.calleeId : call.callerId;

      // Relay hangup to partner
      io.to(`user:${partnerId}`).emit('call:hangup' as any, {
        callId: data.callId,
        reason: data.reason,
        endedBy: user.userId,
      });

      await callManager.hangupCall(data.callId, data.reason);

      if (callback) callback({ success: true, message: 'Call ended' });
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to hangup call';
      if (callback) callback({ success: false, error: errorMsg });
    }
  });
};
