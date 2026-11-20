import { Request, Response, NextFunction } from 'express';
import { authService } from './auth.service';
import {
  signupSchema,
  loginSchema,
  refreshSchema,
  logoutSchema,
} from './auth.schema';
import { sendSuccess } from '../../utils/response';

export class AuthController {
  /**
   * POST /auth/signup
   */
  async signup(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const input = signupSchema.parse(req.body);
      const result = await authService.signup(input);
      sendSuccess(res, result, 201);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /auth/login
   */
  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const input = loginSchema.parse(req.body);
      const result = await authService.login(input);
      sendSuccess(res, result, 200);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /auth/refresh
   */
  async refresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const input = refreshSchema.parse(req.body);
      const tokens = await authService.refresh(input.refreshToken);
      sendSuccess(res, { tokens }, 200);
    } catch (err) {
      next(err);
    }
  }

  /**
   * POST /auth/logout
   */
  async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const input = logoutSchema.parse(req.body);
      const userId = req.user?.userId;
      await authService.logout(input.refreshToken, userId);
      sendSuccess(res, { message: 'Logged out successfully' }, 200);
    } catch (err) {
      next(err);
    }
  }
}

export const authController = new AuthController();
