import { describe, it, expect } from 'vitest';
import { updateMeSchema, searchUsersSchema } from '../users.schema';

describe('Users Zod Validation Schemas', () => {
  it('should validate valid updateMe with displayName only', () => {
    const input = { displayName: 'Dr. Jane Smith' };
    const parsed = updateMeSchema.parse(input);
    expect(parsed.displayName).toBe('Dr. Jane Smith');
    expect(parsed.avatarUrl).toBeUndefined();
  });

  it('should validate valid updateMe with avatarUrl only', () => {
    const input = { avatarUrl: 'https://example.com/avatar.jpg' };
    const parsed = updateMeSchema.parse(input);
    expect(parsed.avatarUrl).toBe('https://example.com/avatar.jpg');
    expect(parsed.displayName).toBeUndefined();
  });

  it('should validate valid updateMe with both fields', () => {
    const input = {
      displayName: 'Dr. Jane Smith',
      avatarUrl: 'https://example.com/avatar.png',
    };
    const parsed = updateMeSchema.parse(input);
    expect(parsed.displayName).toBe('Dr. Jane Smith');
    expect(parsed.avatarUrl).toBe('https://example.com/avatar.png');
  });

  it('should reject empty updateMe payload (neither displayName nor avatarUrl)', () => {
    expect(() => updateMeSchema.parse({})).toThrow();
  });

  it('should reject invalid avatarUrl', () => {
    expect(() => updateMeSchema.parse({ avatarUrl: 'not-a-valid-url' })).toThrow();
  });

  it('should validate valid search query with default limit', () => {
    const parsed = searchUsersSchema.parse({ q: 'olivia' });
    expect(parsed.q).toBe('olivia');
    expect(parsed.limit).toBe(20);
  });

  it('should validate search query with custom limit', () => {
    const parsed = searchUsersSchema.parse({ q: 'doc', limit: '10' });
    expect(parsed.q).toBe('doc');
    expect(parsed.limit).toBe(10);
  });

  it('should reject empty search query', () => {
    expect(() => searchUsersSchema.parse({ q: '' })).toThrow();
  });
});
