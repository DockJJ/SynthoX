import { Router } from 'express';
import { authController } from './auth.controller';
import { authRateLimiter } from '../../middleware/rateLimit.middleware';

export const authRouter = Router();

authRouter.post('/signup', authRateLimiter, (req, res, next) =>
  authController.signup(req, res, next)
);

authRouter.post('/login', authRateLimiter, (req, res, next) =>
  authController.login(req, res, next)
);

authRouter.post('/refresh', (req, res, next) =>
  authController.refresh(req, res, next)
);

authRouter.post('/logout', (req, res, next) =>
  authController.logout(req, res, next)
);
