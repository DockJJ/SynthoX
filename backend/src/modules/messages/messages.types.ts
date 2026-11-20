import { UserSummary } from '../users/users.types';

export interface MessageResponse {
  id: string;
  conversationId: string;
  senderId: string;
  sender: UserSummary;
  content: string;
  createdAt: string;
  deliveredAt: string | null;
  readAt: string | null;
}

export interface PaginatedMessagesResponse {
  messages: MessageResponse[];
  nextCursor: string | null;
  hasMore: boolean;
}
