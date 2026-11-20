import { UserSummary } from '../users/users.types';

export interface LastMessageSummary {
  id: string;
  senderId: string;
  content: string;
  createdAt: string;
  deliveredAt: string | null;
  readAt: string | null;
}

export interface ConversationResponse {
  id: string;
  isGroup: boolean;
  createdAt: string;
  updatedAt: string;
  members: UserSummary[];
  lastMessage: LastMessageSummary | null;
  unreadCount: number;
}
