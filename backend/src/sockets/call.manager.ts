import { Server } from 'socket.io';
import { prisma } from '../config/prisma';
import { logger } from '../config/logger';
import { ActiveCall, CallType, CallStatus } from './call.types';

export class CallManager {
  public isDbLoggingEnabled = true;
  private activeCalls = new Map<string, ActiveCall>();
  private userToCallMap = new Map<string, string>(); // userId -> callId

  public readonly RING_TIMEOUT_MS = 30000; // 30 seconds ring timeout

  /**
   * Check if user is currently participating in an active call
   */
  isUserInCall(userId: string): boolean {
    return this.userToCallMap.has(userId);
  }

  /**
   * Get an active call by callId
   */
  getCall(callId: string): ActiveCall | undefined {
    return this.activeCalls.get(callId);
  }

  /**
   * Get an active call for a user
   */
  getUserCall(userId: string): ActiveCall | undefined {
    const callId = this.userToCallMap.get(userId);
    return callId ? this.activeCalls.get(callId) : undefined;
  }

  /**
   * Initiate a new call, start 30s ring timeout, and log to call_logs table
   */
  async startCall(
    callId: string,
    caller: {
      userId: string;
      username: string;
      displayName: string;
      avatarUrl: string | null;
    },
    calleeId: string,
    callType: CallType,
    io: Server
  ): Promise<ActiveCall> {
    // 1. Setup 30-second ring timeout
    const ringTimer = setTimeout(() => {
      this.handleRingTimeout(callId, io).catch((err) => {
        logger.error({ err, callId }, 'Error handling ring timeout');
      });
    }, this.RING_TIMEOUT_MS);

    const call: ActiveCall = {
      callId,
      callerId: caller.userId,
      callerUsername: caller.username,
      callerDisplayName: caller.displayName,
      callerAvatarUrl: caller.avatarUrl,
      calleeId,
      callType,
      status: 'INITIATED',
      ringTimer,
    };

    // 2. Track in memory
    this.activeCalls.set(callId, call);
    this.userToCallMap.set(caller.userId, callId);
    this.userToCallMap.set(calleeId, callId);

    // 3. Persist initial log in database
    if (this.isDbLoggingEnabled) {
      try {
        await prisma.callLog.create({
          data: {
            id: callId,
            callerId: caller.userId,
            calleeId,
            callType,
            status: 'INITIATED',
          },
        });
      } catch (err) {
        logger.debug({ err, callId }, 'Failed to persist initial call log');
      }
    }

    return call;
  }

  /**
   * Callee accepts the call: clears 30s ring timer and marks startedAt
   */
  async acceptCall(callId: string): Promise<ActiveCall | undefined> {
    const call = this.activeCalls.get(callId);
    if (!call) return undefined;

    if (call.ringTimer) {
      clearTimeout(call.ringTimer);
      call.ringTimer = undefined;
    }

    call.status = 'ACCEPTED';
    call.startedAt = new Date();

    if (this.isDbLoggingEnabled) {
      try {
        await prisma.callLog.update({
          where: { id: callId },
          data: {
            status: 'ACCEPTED',
            startedAt: call.startedAt,
          },
        });
      } catch (err) {
        logger.debug({ err, callId }, 'Failed to update accepted call log');
      }
    }

    return call;
  }

  /**
   * Callee rejects the call
   */
  async rejectCall(callId: string, reason?: string): Promise<ActiveCall | undefined> {
    const call = this.activeCalls.get(callId);
    if (!call) return undefined;

    if (call.ringTimer) {
      clearTimeout(call.ringTimer);
      call.ringTimer = undefined;
    }

    call.status = 'REJECTED';
    const endedAt = new Date();

    if (this.isDbLoggingEnabled) {
      try {
        await prisma.callLog.update({
          where: { id: callId },
          data: {
            status: 'REJECTED',
            endedAt,
            duration: 0,
          },
        });
      } catch (err) {
        logger.debug({ err, callId }, 'Failed to update rejected call log');
      }
    }

    this.cleanupCall(callId);
    logger.info({ callId, reason }, 'Call rejected and logged');
    return call;
  }

  /**
   * End or hang up an active call
   */
  async hangupCall(
    callId: string,
    reason = 'Call ended'
  ): Promise<{ call: ActiveCall; partnerId: string; finalStatus: CallStatus } | undefined> {
    const call = this.activeCalls.get(callId);
    if (!call) return undefined;

    if (call.ringTimer) {
      clearTimeout(call.ringTimer);
      call.ringTimer = undefined;
    }

    const endedAt = new Date();
    let duration = 0;
    let finalStatus: CallStatus = 'ENDED';

    if (call.status === 'ACCEPTED' && call.startedAt) {
      duration = Math.max(0, Math.floor((endedAt.getTime() - call.startedAt.getTime()) / 1000));
      finalStatus = 'ENDED';
    } else {
      finalStatus = 'MISSED';
    }

    call.status = finalStatus;

    if (this.isDbLoggingEnabled) {
      try {
        await prisma.callLog.update({
          where: { id: callId },
          data: {
            status: finalStatus,
            endedAt,
            duration,
          },
        });
      } catch (err) {
        logger.debug({ err, callId }, 'Failed to update ended call log');
      }
    }

    this.cleanupCall(callId);
    logger.info({ callId, reason, duration, finalStatus }, 'Call ended and logged');

    return {
      call,
      partnerId: call.callerId,
      finalStatus,
    };
  }

  /**
   * Log busy attempt without initiating a call
   */
  async logBusy(callerId: string, calleeId: string, callType: CallType): Promise<void> {
    if (this.isDbLoggingEnabled) {
      try {
        await prisma.callLog.create({
          data: {
            callerId,
            calleeId,
            callType,
            status: 'BUSY',
            endedAt: new Date(),
            duration: 0,
          },
        });
      } catch (err) {
        logger.debug({ err, callerId, calleeId }, 'Failed to log busy call');
      }
    }
  }

  /**
   * Log offline / missed call attempt without initiating
   */
  async logOffline(callerId: string, calleeId: string, callType: CallType): Promise<void> {
    if (this.isDbLoggingEnabled) {
      try {
        await prisma.callLog.create({
          data: {
            callerId,
            calleeId,
            callType,
            status: 'MISSED',
            endedAt: new Date(),
            duration: 0,
          },
        });
      } catch (err) {
        logger.debug({ err, callerId, calleeId }, 'Failed to log offline call');
      }
    }
  }

  /**
   * Handle unexpected user disconnection mid-call
   */
  async handleUserDisconnect(userId: string, io: Server): Promise<void> {
    const callId = this.userToCallMap.get(userId);
    if (!callId) return;

    const call = this.activeCalls.get(callId);
    if (!call) {
      this.userToCallMap.delete(userId);
      return;
    }

    const partnerId = call.callerId === userId ? call.calleeId : call.callerId;

    logger.warn({ callId, disconnectedUserId: userId, partnerId }, 'User disconnected mid-call');

    // Notify the other user
    io.to(`user:${partnerId}`).emit('call:hangup' as any, {
      callId,
      reason: 'Partner disconnected',
    });

    await this.hangupCall(callId, 'Partner disconnected');
  }

  /**
   * 30-second ring timeout handler
   */
  private async handleRingTimeout(callId: string, io: Server): Promise<void> {
    const call = this.activeCalls.get(callId);
    if (!call || call.status !== 'INITIATED') return;

    logger.info({ callId, callerId: call.callerId, calleeId: call.calleeId }, 'Call timed out (30s)');

    // Notify caller that call was unanswered / timed out
    io.to(`user:${call.callerId}`).emit('call:hangup' as any, {
      callId,
      reason: 'Ring timeout: Callee did not answer',
    });

    // Notify callee that they missed the call
    io.to(`user:${call.calleeId}`).emit('call:hangup' as any, {
      callId,
      reason: 'Ring timeout: Call missed',
    });

    if (this.isDbLoggingEnabled) {
      try {
        await prisma.callLog.update({
          where: { id: callId },
          data: {
            status: 'MISSED',
            endedAt: new Date(),
            duration: 0,
          },
        });
      } catch (err) {
        logger.debug({ err, callId }, 'Failed to update timed out call log');
      }
    }

    this.cleanupCall(callId);
  }

  /**
   * Remove call from active in-memory maps
   */
  private cleanupCall(callId: string): void {
    const call = this.activeCalls.get(callId);
    if (call) {
      if (call.ringTimer) {
        clearTimeout(call.ringTimer);
      }
      this.userToCallMap.delete(call.callerId);
      this.userToCallMap.delete(call.calleeId);
      this.activeCalls.delete(callId);
    }
  }
}

export const callManager = new CallManager();
