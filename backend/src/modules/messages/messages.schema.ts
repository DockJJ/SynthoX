import { z } from 'zod';

export const getConversationMessagesQuerySchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().min(1).max(50).default(20),
});

export const conversationParamSchema = z.object({
  id: z.string({ required_error: 'Conversation ID is required' }).min(1),
});

export type GetConversationMessagesQuery = z.infer<typeof getConversationMessagesQuerySchema>;
