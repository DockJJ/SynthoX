import { Router } from 'express';
import { messagesController } from './messages.controller';
import { authenticate } from '../../middleware/auth.middleware';

export const messagesRouter = Router();

// Authenticated route
messagesRouter.use(authenticate);

messagesRouter.get('/:id/messages', (req, res, next) =>
  messagesController.getConversationMessages(req, res, next)
);
