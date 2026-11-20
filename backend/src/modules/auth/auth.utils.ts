import argon2 from 'argon2';
import jwt, { SignOptions } from 'jsonwebtoken';
import crypto from 'crypto';
import { config } from '../../config/env';
import { AuthUserPayload, AuthTokens } from './auth.types';
import { UnauthorizedError } from '../../utils/errors';

/**
 * Hash plain text password using argon2id
 */
export const hashPassword = async (password: string): Promise<string> => {
  return argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: 2 ** 16, // 64 MB
    timeCost: 3,
    parallelism: 1,
  });
};

/**
 * Verify plain text password against argon2 hash
 */
export const verifyPassword = async (hash: string, password: string): Promise<boolean> => {
  try {
    return await argon2.verify(hash, password);
  } catch {
    return false;
  }
};

/**
 * Hash an opaque refresh token with SHA-256 for secure DB storage & lookup
 */
export const hashToken = (token: string): string => {
  return crypto.createHash('sha256').update(token).digest('hex');
};

/**
 * Generate cryptographically secure random token string
 */
export const generateOpaqueToken = (): string => {
  return crypto.randomBytes(48).toString('base64url');
};

/**
 * Issue new access and refresh tokens
 */
export const generateAuthTokens = (payload: AuthUserPayload): AuthTokens => {
  // 15 minutes access token = 900 seconds
  const accessExpiresSeconds = 15 * 60;

  const signOptions: SignOptions = {
    expiresIn: (config.JWT_ACCESS_EXPIRES_IN as unknown) as SignOptions['expiresIn'],
    algorithm: 'HS256',
  };

  const accessToken = jwt.sign(
    {
      userId: payload.userId,
      email: payload.email,
      username: payload.username,
    },
    config.JWT_ACCESS_SECRET,
    signOptions
  );

  // Generate a high-entropy random refresh token
  const refreshToken = generateOpaqueToken();

  return {
    accessToken,
    refreshToken,
    expiresIn: accessExpiresSeconds,
    tokenType: 'Bearer',
  };
};

/**
 * Verify and decode access token
 */
export const verifyAccessToken = (token: string): AuthUserPayload => {
  try {
    const decoded = jwt.verify(token, config.JWT_ACCESS_SECRET, {
      algorithms: ['HS256'],
    }) as AuthUserPayload;

    return {
      userId: decoded.userId,
      email: decoded.email,
      username: decoded.username,
    };
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      throw new UnauthorizedError('Access token has expired');
    }
    throw new UnauthorizedError('Invalid access token');
  }
};
