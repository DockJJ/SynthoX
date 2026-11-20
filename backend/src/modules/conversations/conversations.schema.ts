import { z } from 'zod';

export const createConversationSchema = z.object({
  recipientId: z
    .string({ required_error: 'recipientId is required' })
    .min(1, 'recipientId cannot be empty')
    .trim(),
});

export const conversationIdParamSchema = z.object({
  id: z
    .string({ required_error: 'Conversation ID is required' })
    .min(1, 'Conversation ID cannot be empty')
    .trim(),
});

export type CreateConversationInput = z.infer<typeof createConversationSchema>;
