import { Request, Response, NextFunction } from 'express';
import { usersService } from './users.service';
import { updateMeSchema, searchUsersSchema } from './users.schema';
import { sendSuccess } from '../../utils/response';
import { UnauthorizedError } from '../../utils/errors';

export class UsersController {
  /**
   * GET /users/me
   */
  async getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const profile = await usersService.getMe(req.user.userId);
      sendSuccess(res, { user: profile }, 200);
    } catch (err) {
      next(err);
    }
  }

  /**
   * PATCH /users/me
   */
  async updateMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const input = updateMeSchema.parse(req.body);
      const updated = await usersService.updateMe(req.user.userId, input);
      sendSuccess(res, { user: updated }, 200);
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /users/search?q=
   */
  async searchUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const input = searchUsersSchema.parse(req.query);
      const results = await usersService.searchUsers(req.user.userId, input);
      sendSuccess(res, { users: results, count: results.length }, 200);
    } catch (err) {
      next(err);
    }
  }
}

export const usersController = new UsersController();
