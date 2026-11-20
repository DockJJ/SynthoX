import { Server } from 'socket.io';
import { AuthenticatedSocket } from './socket.types';
import {
  sendMessageSchema,
  messageDeliveredSchema,
  messageReadSchema,
  typingSchema,
  presenceGetSchema,
} from './socket.schema';
import { prisma } from '../config/prisma';
import { logger } from '../config/logger';
import { presenceService } from './presence.service';
import { MessageResponse } from '../modules/messages/messages.types';

export const registerChatHandlers = (io: Server, socket: AuthenticatedSocket): void => {
  const user = socket.data.user;

  // 1. message:send
  socket.on('message:send', async (rawPayload, callback) => {
    try {
      const data = sendMessageSchema.parse(rawPayload);

      // Verify sender is a member of the conversation
      const membership = await prisma.conversationMember.findUnique({
        where: {
          conversationId_userId: {
            conversationId: data.conversationId,
            userId: user.userId,
          },
        },
      });

      if (!membership) {
        if (callback) {
          callback({ success: false, error: 'You are not a member of this conversation' });
        }
        return;
      }

      // Persist message to database
      const [savedMessage] = await prisma.$transaction([
        prisma.message.create({
          data: {
            conversationId: data.conversationId,
            senderId: user.userId,
            content: data.content,
          },
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
        }),
        prisma.conversation.update({
          where: { id: data.conversationId },
          data: { updatedAt: new Date() },
        }),
      ]);

      const formattedMessage: MessageResponse = {
        id: savedMessage.id,
        conversationId: savedMessage.conversationId,
        senderId: savedMessage.senderId,
        sender: {
          id: savedMessage.sender.id,
          username: savedMessage.sender.username,
          displayName: savedMessage.sender.displayName,
          avatarUrl: savedMessage.sender.avatarUrl,
        },
        content: savedMessage.content,
        createdAt: savedMessage.createdAt.toISOString(),
        deliveredAt: savedMessage.deliveredAt ? savedMessage.deliveredAt.toISOString() : null,
        readAt: savedMessage.readAt ? savedMessage.readAt.toISOString() : null,
      };

      // Acknowledge the sender immediately
      if (callback) {
        callback({ success: true, data: formattedMessage });
      }

      // Broadcast to other conversation members
      const members = await prisma.conversationMember.findMany({
        where: { conversationId: data.conversationId },
        select: { userId: true },
      });

      for (const m of members) {
        if (m.userId !== user.userId) {
          io.to(`user:${m.userId}`).emit('message:new', { message: formattedMessage });
        }
      }

      logger.debug(
        { messageId: savedMessage.id, conversationId: data.conversationId, senderId: user.userId },
        'Real-time message saved and broadcasted'
      );
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to send message';
      logger.warn({ error: errorMsg, userId: user.userId }, 'message:send error');
      if (callback) {
        callback({ success: false, error: errorMsg });
      }
    }
  });

  // 2. message:delivered
  socket.on('message:delivered', async (rawPayload, callback) => {
    try {
      const data = messageDeliveredSchema.parse(rawPayload);

      const message = await prisma.message.findUnique({
        where: { id: data.messageId },
        select: { id: true, senderId: true, deliveredAt: true },
      });

      if (!message) {
        if (callback) callback({ success: false, error: 'Message not found' });
        return;
      }

      const deliveredAt = message.deliveredAt || new Date();

      if (!message.deliveredAt) {
        await prisma.message.update({
          where: { id: data.messageId },
          data: { deliveredAt },
        });
      }

      // Notify the sender that message was delivered
      if (message.senderId !== user.userId) {
        io.to(`user:${message.senderId}`).emit('message:delivered', {
          messageId: data.messageId,
          conversationId: data.conversationId,
          deliveredAt: deliveredAt.toISOString(),
          recipientId: user.userId,
        });
      }

      if (callback) {
        callback({ success: true, data: { messageId: data.messageId } });
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to mark delivered';
      if (callback) callback({ success: false, error: errorMsg });
    }
  });

  // 3. message:read
  socket.on('message:read', async (rawPayload, callback) => {
    try {
      const data = messageReadSchema.parse(rawPayload);
      const readAt = new Date();

      // Update membership lastReadAt
      await prisma.conversationMember.updateMany({
        where: {
          conversationId: data.conversationId,
          userId: user.userId,
        },
        data: { lastReadAt: readAt },
      });

      // Update all unread messages in this conversation sent by other users
      await prisma.message.updateMany({
        where: {
          conversationId: data.conversationId,
          senderId: { not: user.userId },
          readAt: null,
        },
        data: {
          readAt,
          deliveredAt: readAt,
        },
      });

      // Notify other members
      const members = await prisma.conversationMember.findMany({
        where: { conversationId: data.conversationId },
        select: { userId: true },
      });

      for (const m of members) {
        if (m.userId !== user.userId) {
          io.to(`user:${m.userId}`).emit('message:read', {
            conversationId: data.conversationId,
            readerId: user.userId,
            readAt: readAt.toISOString(),
          });
        }
      }

      if (callback) {
        callback({ success: true, data: { conversationId: data.conversationId } });
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to mark read';
      if (callback) callback({ success: false, error: errorMsg });
    }
  });

  // 4. typing:start
  socket.on('typing:start', async (rawPayload) => {
    try {
      const data = typingSchema.parse(rawPayload);

      const members = await prisma.conversationMember.findMany({
        where: { conversationId: data.conversationId },
        select: { userId: true },
      });

      for (const m of members) {
        if (m.userId !== user.userId) {
          io.to(`user:${m.userId}`).emit('typing:start', {
            conversationId: data.conversationId,
            userId: user.userId,
            username: user.username,
          });
        }
      }
    } catch {
      // Ignored for typing indicators
    }
  });

  // 5. typing:stop
  socket.on('typing:stop', async (rawPayload) => {
    try {
      const data = typingSchema.parse(rawPayload);

      const members = await prisma.conversationMember.findMany({
        where: { conversationId: data.conversationId },
        select: { userId: true },
      });

      for (const m of members) {
        if (m.userId !== user.userId) {
          io.to(`user:${m.userId}`).emit('typing:stop', {
            conversationId: data.conversationId,
            userId: user.userId,
          });
        }
      }
    } catch {
      // Ignored for typing indicators
    }
  });

  // 6. presence:get
  socket.on('presence:get', async (rawPayload, callback) => {
    try {
      const data = presenceGetSchema.parse(rawPayload);
      const presenceMap = await presenceService.getMultiplePresence(data.userIds);

      if (callback) {
        callback({ success: true, data: presenceMap });
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to query presence';
      if (callback) callback({ success: false, error: errorMsg });
    }
  });
};
