export type CallType = 'AUDIO' | 'VIDEO';

export type CallStatus =
  | 'INITIATED'
  | 'ACCEPTED'
  | 'REJECTED'
  | 'BUSY'
  | 'MISSED'
  | 'ENDED';

export interface ActiveCall {
  callId: string;
  callerId: string;
  callerUsername: string;
  callerDisplayName: string;
  callerAvatarUrl: string | null;
  calleeId: string;
  callType: CallType;
  status: CallStatus;
  startedAt?: Date;
  ringTimer?: NodeJS.Timeout;
}

// Client -> Server Call Event Payloads
export interface CallInvitePayload {
  calleeId: string;
  callType?: 'audio' | 'video';
}

export interface CallAcceptPayload {
  callId: string;
}

export interface CallRejectPayload {
  callId: string;
  reason?: string;
}

export interface CallOfferPayload {
  callId: string;
  sdp: Record<string, unknown> | string;
}

export interface CallAnswerPayload {
  callId: string;
  sdp: Record<string, unknown> | string;
}

export interface CallIceCandidatePayload {
  callId: string;
  candidate: Record<string, unknown> | string;
}

export interface CallHangupPayload {
  callId: string;
  reason?: string;
}
