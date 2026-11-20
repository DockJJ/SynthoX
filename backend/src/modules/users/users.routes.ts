import { Router } from 'express';
import { usersController } from './users.controller';
import { authenticate } from '../../middleware/auth.middleware';

export const usersRouter = Router();

// All users routes require authentication
usersRouter.use(authenticate);

usersRouter.get('/me', (req, res, next) => usersController.getMe(req, res, next));
usersRouter.patch('/me', (req, res, next) => usersController.updateMe(req, res, next));
usersRouter.get('/search', (req, res, next) => usersController.searchUsers(req, res, next));
