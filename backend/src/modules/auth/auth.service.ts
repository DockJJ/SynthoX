import { prisma } from '../../config/prisma';
import {
  hashPassword,
  verifyPassword,
  generateAuthTokens,
  hashToken,
} from './auth.utils';
import {
  AuthResponse,
  AuthTokens,
  UserResponse,
} from './auth.types';
import {
  SignupInput,
  LoginInput,
} from './auth.schema';
import {
  ConflictError,
  UnauthorizedError,
  NotFoundError,
} from '../../utils/errors';
import { logger } from '../../config/logger';

const REFRESH_TOKEN_DAYS = 30;

export class AuthService {
  /**
   * Register a new user account
   */
  async signup(input: SignupInput): Promise<AuthResponse> {
    const existingEmail = await prisma.user.findUnique({
      where: { email: input.email },
    });
    if (existingEmail) {
      throw new ConflictError('An account with this email already exists');
    }

    const existingUsername = await prisma.user.findUnique({
      where: { username: input.username },
    });
    if (existingUsername) {
      throw new ConflictError('Username is already taken');
    }

    const passwordHash = await hashPassword(input.password);

    const user = await prisma.user.create({
      data: {
        email: input.email,
        username: input.username,
        displayName: input.displayName,
        passwordHash,
        avatarUrl: input.avatarUrl || null,
      },
    });

    logger.info({ userId: user.id, email: user.email }, 'User registered successfully');

    const tokens = generateAuthTokens({
      userId: user.id,
      email: user.email,
      username: user.username,
    });

    // Store hashed refresh token in database
    await this.storeRefreshToken(user.id, tokens.refreshToken);

    return {
      user: this.formatUser(user),
      tokens,
    };
  }

  /**
   * Authenticate user with credentials
   */
  async login(input: LoginInput): Promise<AuthResponse> {
    const isEmail = input.login.includes('@');
    const user = await prisma.user.findFirst({
      where: isEmail
        ? { email: input.login.toLowerCase() }
        : { username: input.login.toLowerCase() },
    });

    if (!user) {
      throw new UnauthorizedError('Invalid credentials');
    }

    const isPasswordValid = await verifyPassword(user.passwordHash, input.password);
    if (!isPasswordValid) {
      throw new UnauthorizedError('Invalid credentials');
    }

    logger.info({ userId: user.id }, 'User logged in successfully');

    const tokens = generateAuthTokens({
      userId: user.id,
      email: user.email,
      username: user.username,
    });

    // Store hashed refresh token in database
    await this.storeRefreshToken(user.id, tokens.refreshToken);

    return {
      user: this.formatUser(user),
      tokens,
    };
  }

  /**
   * Rotate refresh token and issue new token pair
   */
  async refresh(refreshTokenRaw: string): Promise<AuthTokens> {
    const hashed = hashToken(refreshTokenRaw);

    const storedToken = await prisma.refreshToken.findUnique({
      where: { tokenHash: hashed },
      include: { user: true },
    });

    // Reject if token is missing, revoked, or expired
    if (!storedToken || storedToken.revoked || storedToken.expiresAt < new Date()) {
      throw new UnauthorizedError('Invalid, expired, or revoked refresh token');
    }

    const user = storedToken.user;
    if (!user) {
      throw new NotFoundError('Associated user no longer exists');
    }

    // 1. Rotate token: Revoke the old token immediately
    await prisma.refreshToken.update({
      where: { id: storedToken.id },
      data: { revoked: true },
    });

    // 2. Issue new token pair
    const newTokens = generateAuthTokens({
      userId: user.id,
      email: user.email,
      username: user.username,
    });

    // 3. Store new hashed refresh token
    await this.storeRefreshToken(user.id, newTokens.refreshToken);

    logger.debug({ userId: user.id }, 'Token rotated successfully');

    return newTokens;
  }

  /**
   * Revoke refresh token on logout
   */
  async logout(refreshTokenRaw?: string, userId?: string): Promise<void> {
    if (refreshTokenRaw) {
      const hashed = hashToken(refreshTokenRaw);
      await prisma.refreshToken.updateMany({
        where: { tokenHash: hashed },
        data: { revoked: true },
      });
    }

    if (userId && !refreshTokenRaw) {
      await prisma.refreshToken.updateMany({
        where: { userId, revoked: false },
        data: { revoked: true },
      });
    }

    logger.info({ userId }, 'User logged out; refresh tokens revoked');
  }

  /**
   * Helper to store hashed refresh token with expiry
   */
  private async storeRefreshToken(userId: string, rawToken: string): Promise<void> {
    const hashed = hashToken(rawToken);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + REFRESH_TOKEN_DAYS);

    await prisma.refreshToken.create({
      data: {
        tokenHash: hashed,
        userId,
        expiresAt,
        revoked: false,
      },
    });
  }

  /**
   * Helper to sanitize and format user object for responses
   */
  private formatUser(user: {
    id: string;
    email: string;
    username: string;
    displayName: string;
    avatarUrl: string | null;
    createdAt: Date;
  }): UserResponse {
    return {
      id: user.id,
      email: user.email,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt.toISOString(),
    };
  }
}

export const authService = new AuthService();
