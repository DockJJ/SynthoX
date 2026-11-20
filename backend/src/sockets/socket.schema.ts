import { z } from 'zod';

export const sendMessageSchema = z.object({
  conversationId: z
    .string({ required_error: 'conversationId is required' })
    .min(1, 'conversationId cannot be empty')
    .trim(),
  content: z
    .string({ required_error: 'content is required' })
    .min(1, 'Message content cannot be empty')
    .max(10000, 'Message content cannot exceed 10000 characters')
    .trim(),
  tempId: z.string().optional(),
});

export const messageDeliveredSchema = z.object({
  messageId: z
    .string({ required_error: 'messageId is required' })
    .min(1, 'messageId cannot be empty')
    .trim(),
  conversationId: z
    .string({ required_error: 'conversationId is required' })
    .min(1, 'conversationId cannot be empty')
    .trim(),
});

export const messageReadSchema = z.object({
  conversationId: z
    .string({ required_error: 'conversationId is required' })
    .min(1, 'conversationId cannot be empty')
    .trim(),
});

export const typingSchema = z.object({
  conversationId: z
    .string({ required_error: 'conversationId is required' })
    .min(1, 'conversationId cannot be empty')
    .trim(),
});

export const presenceGetSchema = z.object({
  userIds: z
    .array(z.string().min(1))
    .max(100, 'Cannot query presence for more than 100 users at once'),
});
