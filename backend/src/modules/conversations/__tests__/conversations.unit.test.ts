import { describe, it, expect } from 'vitest';
import {
  createConversationSchema,
  conversationIdParamSchema,
} from '../conversations.schema';

describe('Conversations Zod Validation Schemas', () => {
  it('should validate valid createConversation input', () => {
    const input = { recipientId: 'user-recipient-uuid-123' };
    const parsed = createConversationSchema.parse(input);
    expect(parsed.recipientId).toBe('user-recipient-uuid-123');
  });

  it('should reject empty recipientId', () => {
    expect(() => createConversationSchema.parse({ recipientId: '' })).toThrow();
    expect(() => createConversationSchema.parse({})).toThrow();
  });

  it('should validate conversationId parameter', () => {
    const parsed = conversationIdParamSchema.parse({ id: 'conv-uuid-456' });
    expect(parsed.id).toBe('conv-uuid-456');
  });

  it('should reject missing or empty conversationId parameter', () => {
    expect(() => conversationIdParamSchema.parse({ id: '' })).toThrow();
  });
});
