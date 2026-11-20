import { prisma } from '../../config/prisma';
import { PaginatedMessagesResponse, MessageResponse } from './messages.types';
import { GetConversationMessagesQuery } from './messages.schema';
import { NotFoundError, ForbiddenError, BadRequestError } from '../../utils/errors';

export class MessagesService {
  /**
   * Get messages for a conversation with cursor-based pagination
   */
  async getConversationMessages(
    currentUserId: string,
    conversationId: string,
    query: GetConversationMessagesQuery
  ): Promise<PaginatedMessagesResponse> {
    const limit = query.limit;

    // 1. Verify user is a member of the conversation
    const member = await prisma.conversationMember.findUnique({
      where: {
        conversationId_userId: {
          conversationId,
          userId: currentUserId,
        },
      },
    });

    if (!member) {
      // Check if conversation exists at all to return 404 vs 403
      const conversationExists = await prisma.conversation.findUnique({
        where: { id: conversationId },
        select: { id: true },
      });

      if (!conversationExists) {
        throw new NotFoundError('Conversation not found');
      }
      throw new ForbiddenError('You are not a member of this conversation');
    }

    // 2. Resolve cursor condition
    let cursorFilter = {};
    if (query.cursor) {
      const cursorMessage = await prisma.message.findUnique({
        where: { id: query.cursor },
        select: { id: true, createdAt: true, conversationId: true },
      });

      if (!cursorMessage || cursorMessage.conversationId !== conversationId) {
        throw new BadRequestError('Invalid cursor message ID for this conversation');
      }

      cursorFilter = {
        createdAt: {
          lt: cursorMessage.createdAt,
        },
      };
    }

    // 3. Query messages: take limit + 1 to determine hasMore
    const rawMessages = await prisma.message.findMany({
      where: {
        conversationId,
        ...cursorFilter,
      },
      take: limit + 1,
      orderBy: { createdAt: 'desc' },
      include: {
        sender: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
      },
    });

    const hasMore = rawMessages.length > limit;
    const pageMessages = hasMore ? rawMessages.slice(0, limit) : rawMessages;
    const nextCursor = hasMore && pageMessages.length > 0 ? pageMessages[pageMessages.length - 1].id : null;

    const messages: MessageResponse[] = pageMessages.map((msg) => ({
      id: msg.id,
      conversationId: msg.conversationId,
      senderId: msg.senderId,
      sender: {
        id: msg.sender.id,
        username: msg.sender.username,
        displayName: msg.sender.displayName,
        avatarUrl: msg.sender.avatarUrl,
      },
      content: msg.content,
      createdAt: msg.createdAt.toISOString(),
      deliveredAt: msg.deliveredAt ? msg.deliveredAt.toISOString() : null,
      readAt: msg.readAt ? msg.readAt.toISOString() : null,
    }));

    return {
      messages,
      nextCursor,
      hasMore,
    };
  }
}

export const messagesService = new MessagesService();
