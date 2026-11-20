import { prisma } from '../../config/prisma';
import { ConversationResponse } from './conversations.types';
import { BadRequestError, NotFoundError, ForbiddenError } from '../../utils/errors';

export class ConversationsService {
  /**
   * Create or retrieve an existing 1:1 conversation
   */
  async createDirectConversation(
    currentUserId: string,
    recipientId: string
  ): Promise<ConversationResponse> {
    if (currentUserId === recipientId) {
      throw new BadRequestError('Cannot start a conversation with yourself');
    }

    // Verify recipient exists
    const recipient = await prisma.user.findUnique({
      where: { id: recipientId },
    });
    if (!recipient) {
      throw new NotFoundError('Recipient user not found');
    }

    // Check if a direct (1:1) conversation already exists
    const existingConversation = await prisma.conversation.findFirst({
      where: {
        isGroup: false,
        AND: [
          { members: { some: { userId: currentUserId } } },
          { members: { some: { userId: recipientId } } },
        ],
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                displayName: true,
                avatarUrl: true,
              },
            },
          },
        },
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (existingConversation) {
      return this.formatConversation(existingConversation, currentUserId);
    }

    // Create new conversation with members in a transaction
    const newConversation = await prisma.conversation.create({
      data: {
        isGroup: false,
        members: {
          create: [
            { userId: currentUserId },
            { userId: recipientId },
          ],
        },
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                displayName: true,
                avatarUrl: true,
              },
            },
          },
        },
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    return this.formatConversation(newConversation, currentUserId);
  }

  /**
   * List all conversations for the current user
   */
  async listUserConversations(currentUserId: string): Promise<ConversationResponse[]> {
    const conversations = await prisma.conversation.findMany({
      where: {
        members: {
          some: { userId: currentUserId },
        },
      },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                displayName: true,
                avatarUrl: true,
              },
            },
          },
        },
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    return Promise.all(
      conversations.map((conv) => this.formatConversation(conv, currentUserId))
    );
  }

  /**
   * Get single conversation details by ID
   */
  async getConversationById(
    currentUserId: string,
    conversationId: string
  ): Promise<ConversationResponse> {
    const conversation = await prisma.conversation.findUnique({
      where: { id: conversationId },
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                displayName: true,
                avatarUrl: true,
              },
            },
          },
        },
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!conversation) {
      throw new NotFoundError('Conversation not found');
    }

    const isMember = conversation.members.some((m) => m.userId === currentUserId);
    if (!isMember) {
      throw new ForbiddenError('You are not a member of this conversation');
    }

    return this.formatConversation(conversation, currentUserId);
  }

  /**
   * Helper to format conversation model into ConversationResponse
   */
  private async formatConversation(
    conv: {
      id: string;
      isGroup: boolean;
      createdAt: Date;
      updatedAt: Date;
      members: Array<{
        userId: string;
        lastReadAt: Date | null;
        user: {
          id: string;
          username: string;
          displayName: string;
          avatarUrl: string | null;
        };
      }>;
      messages: Array<{
        id: string;
        senderId: string;
        content: string;
        createdAt: Date;
        deliveredAt: Date | null;
        readAt: Date | null;
      }>;
    },
    currentUserId: string
  ): Promise<ConversationResponse> {
    const currentMember = conv.members.find((m) => m.userId === currentUserId);
    const lastRead = currentMember?.lastReadAt;

    // Calculate unread count (messages sent by others after user's lastReadAt)
    const unreadCount = await prisma.message.count({
      where: {
        conversationId: conv.id,
        senderId: { not: currentUserId },
        ...(lastRead ? { createdAt: { gt: lastRead } } : { readAt: null }),
      },
    });

    const lastMsg = conv.messages[0] || null;

    return {
      id: conv.id,
      isGroup: conv.isGroup,
      createdAt: conv.createdAt.toISOString(),
      updatedAt: conv.updatedAt.toISOString(),
      members: conv.members.map((m) => ({
        id: m.user.id,
        username: m.user.username,
        displayName: m.user.displayName,
        avatarUrl: m.user.avatarUrl,
      })),
      lastMessage: lastMsg
        ? {
            id: lastMsg.id,
            senderId: lastMsg.senderId,
            content: lastMsg.content,
            createdAt: lastMsg.createdAt.toISOString(),
            deliveredAt: lastMsg.deliveredAt ? lastMsg.deliveredAt.toISOString() : null,
            readAt: lastMsg.readAt ? lastMsg.readAt.toISOString() : null,
          }
        : null,
      unreadCount,
    };
  }
}

export const conversationsService = new ConversationsService();
