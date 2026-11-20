import { describe, it, expect } from 'vitest';
import {
  hashPassword,
  verifyPassword,
  hashToken,
  generateAuthTokens,
  verifyAccessToken,
} from '../auth.utils';
import {
  signupSchema,
  loginSchema,
  refreshSchema,
} from '../auth.schema';
import { UnauthorizedError } from '../../../utils/errors';

describe('Auth Utilities & Hashing', () => {
  it('should hash password with argon2id and verify correctly', async () => {
    const password = 'SuperSecurePassword123!';
    const hash = await hashPassword(password);

    expect(hash.startsWith('$argon2id$')).toBe(true);

    const isValid = await verifyPassword(hash, password);
    expect(isValid).toBe(true);

    const isInvalid = await verifyPassword(hash, 'WrongPassword456!');
    expect(isInvalid).toBe(false);
  });

  it('should deterministically hash tokens with SHA-256', () => {
    const rawToken = 'my_test_refresh_token_12345';
    const hash1 = hashToken(rawToken);
    const hash2 = hashToken(rawToken);

    expect(hash1).toBe(hash2);
    expect(hash1).toHaveLength(64);

    const differentHash = hashToken('different_token_67890');
    expect(hash1).not.toBe(differentHash);
  });

  it('should generate and verify JWT access tokens', () => {
    const payload = {
      userId: 'user-uuid-12345',
      email: 'doctor@synthox.health',
      username: 'dr_olivia',
    };

    const tokens = generateAuthTokens(payload);

    expect(tokens.accessToken).toBeTruthy();
    expect(tokens.refreshToken).toBeTruthy();
    expect(tokens.tokenType).toBe('Bearer');
    expect(tokens.expiresIn).toBe(900); // 15 minutes

    const verified = verifyAccessToken(tokens.accessToken);
    expect(verified.userId).toBe(payload.userId);
    expect(verified.email).toBe(payload.email);
    expect(verified.username).toBe(payload.username);
  });

  it('should reject invalid or tampered access tokens', () => {
    expect(() => verifyAccessToken('tampered.invalid.jwt')).toThrow(UnauthorizedError);
    expect(() => verifyAccessToken('tampered.invalid.jwt')).toThrow('Invalid access token');
  });
});

describe('Auth Zod Validation Schemas', () => {
  it('should validate valid signup input', () => {
    const input = {
      email: 'John.Doe@example.com',
      username: 'johndoe_99',
      displayName: 'John Doe',
      password: 'password123',
    };

    const parsed = signupSchema.parse(input);
    expect(parsed.email).toBe('john.doe@example.com');
    expect(parsed.username).toBe('johndoe_99');
  });

  it('should reject invalid signup email', () => {
    expect(() => {
      signupSchema.parse({
        email: 'not-an-email',
        username: 'validuser',
        displayName: 'Valid Name',
        password: 'password123',
      });
    }).toThrow();
  });

  it('should reject weak signup password (< 8 chars or no numbers)', () => {
    // Too short
    expect(() => {
      signupSchema.parse({
        email: 'test@example.com',
        username: 'validuser',
        displayName: 'Valid Name',
        password: 'pass1',
      });
    }).toThrow();

    // No numbers
    expect(() => {
      signupSchema.parse({
        email: 'test@example.com',
        username: 'validuser',
        displayName: 'Valid Name',
        password: 'passwordonly',
      });
    }).toThrow();
  });

  it('should validate valid login input with email or username', () => {
    const emailLogin = loginSchema.parse({
      login: 'user@example.com',
      password: 'mypassword1',
    });
    expect(emailLogin.login).toBe('user@example.com');

    const usernameLogin = loginSchema.parse({
      login: 'cool_username',
      password: 'mypassword1',
    });
    expect(usernameLogin.login).toBe('cool_username');
  });

  it('should reject empty login password', () => {
    expect(() => {
      loginSchema.parse({
        login: 'validuser',
        password: '',
      });
    }).toThrow();
  });

  it('should validate refresh input', () => {
    const parsed = refreshSchema.parse({
      refreshToken: 'valid-refresh-token-string',
    });
    expect(parsed.refreshToken).toBe('valid-refresh-token-string');

    expect(() => {
      refreshSchema.parse({
        refreshToken: '',
      });
    }).toThrow();
  });
});
