import { describe, it, expect } from 'vitest';
import {
  getConversationMessagesQuerySchema,
  conversationParamSchema,
} from '../messages.schema';

describe('Messages Zod Validation Schemas', () => {
  it('should validate query with default limit and no cursor', () => {
    const parsed = getConversationMessagesQuerySchema.parse({});
    expect(parsed.limit).toBe(20);
    expect(parsed.cursor).toBeUndefined();
  });

  it('should validate query with cursor and custom limit', () => {
    const parsed = getConversationMessagesQuerySchema.parse({
      cursor: 'msg-uuid-999',
      limit: '35',
    });
    expect(parsed.cursor).toBe('msg-uuid-999');
    expect(parsed.limit).toBe(35);
  });

  it('should reject limit greater than max allowed (50)', () => {
    expect(() => getConversationMessagesQuerySchema.parse({ limit: '100' })).toThrow();
  });

  it('should reject limit less than min (1)', () => {
    expect(() => getConversationMessagesQuerySchema.parse({ limit: '0' })).toThrow();
  });

  it('should validate conversation parameter', () => {
    const parsed = conversationParamSchema.parse({ id: 'conv-id-789' });
    expect(parsed.id).toBe('conv-id-789');
  });
});
