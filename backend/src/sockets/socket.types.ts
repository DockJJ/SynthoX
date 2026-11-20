import { Socket } from 'socket.io';
import { AuthUserPayload } from '../modules/auth/auth.types';
import { MessageResponse } from '../modules/messages/messages.types';

export interface AuthenticatedSocketData {
  user: AuthUserPayload;
}

export type AuthenticatedSocket = Socket<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  AuthenticatedSocketData
>;

// Client -> Server Events
export interface ClientToServerEvents {
  'message:send': (
    payload: SendMessagePayload,
    callback?: (response: SocketAck<MessageResponse>) => void
  ) => void;

  'message:delivered': (
    payload: MessageDeliveredPayload,
    callback?: (response: SocketAck<{ messageId: string }>) => void
  ) => void;

  'message:read': (
    payload: MessageReadPayload,
    callback?: (response: SocketAck<{ conversationId: string }>) => void
  ) => void;

  'typing:start': (payload: TypingPayload) => void;
  'typing:stop': (payload: TypingPayload) => void;

  'presence:get': (
    payload: { userIds: string[] },
    callback?: (response: SocketAck<Record<string, 'online' | 'offline'>>) => void
  ) => void;
}

// Server -> Client Events
export interface ServerToClientEvents {
  'message:new': (payload: { message: MessageResponse }) => void;
  'message:delivered': (payload: {
    messageId: string;
    conversationId: string;
    deliveredAt: string;
    recipientId: string;
  }) => void;
  'message:read': (payload: {
    conversationId: string;
    readerId: string;
    readAt: string;
  }) => void;

  'typing:start': (payload: {
    conversationId: string;
    userId: string;
    username: string;
  }) => void;
  'typing:stop': (payload: {
    conversationId: string;
    userId: string;
  }) => void;

  'presence:update': (payload: {
    userId: string;
    status: 'online' | 'offline';
    lastSeen?: string;
  }) => void;
}

// Inter-server Events (used by Redis adapter if fanning out across nodes)
export interface InterServerEvents {
  ping: () => void;
}

// Standard Socket Acknowledgment Envelope
export interface SocketAck<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
}

// Event Payloads
export interface SendMessagePayload {
  conversationId: string;
  content: string;
  tempId?: string;
}

export interface MessageDeliveredPayload {
  messageId: string;
  conversationId: string;
}

export interface MessageReadPayload {
  conversationId: string;
}

export interface TypingPayload {
  conversationId: string;
}
