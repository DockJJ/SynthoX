import { prisma } from '../../config/prisma';
import { UserProfile, UserSummary } from './users.types';
import { UpdateMeInput, SearchUsersInput } from './users.schema';
import { NotFoundError } from '../../utils/errors';

export class UsersService {
  /**
   * Fetch current user profile
   */
  async getMe(userId: string): Promise<UserProfile> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundError('User not found');
    }

    return this.formatProfile(user);
  }

  /**
   * Update current user profile
   */
  async updateMe(userId: string, input: UpdateMeInput): Promise<UserProfile> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundError('User not found');
    }

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(input.displayName !== undefined ? { displayName: input.displayName } : {}),
        ...(input.avatarUrl !== undefined ? { avatarUrl: input.avatarUrl } : {}),
      },
    });

    return this.formatProfile(updatedUser);
  }

  /**
   * Search users by username, display name, or email
   */
  async searchUsers(currentUserId: string, input: SearchUsersInput): Promise<UserSummary[]> {
    const query = input.q.toLowerCase();

    const users = await prisma.user.findMany({
      where: {
        id: { not: currentUserId },
        OR: [
          { username: { contains: query, mode: 'insensitive' } },
          { displayName: { contains: query, mode: 'insensitive' } },
          { email: { contains: query, mode: 'insensitive' } },
        ],
      },
      take: input.limit,
      orderBy: { username: 'asc' },
      select: {
        id: true,
        username: true,
        displayName: true,
        avatarUrl: true,
      },
    });

    return users;
  }

  /**
   * Helper to format User model into UserProfile
   */
  private formatProfile(user: {
    id: string;
    email: string;
    username: string;
    displayName: string;
    avatarUrl: string | null;
    createdAt: Date;
    updatedAt: Date;
  }): UserProfile {
    return {
      id: user.id,
      email: user.email,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt.toISOString(),
      updatedAt: user.updatedAt.toISOString(),
    };
  }
}

export const usersService = new UsersService();
