import { Router } from 'express';
import { conversationsController } from './conversations.controller';
import { messagesController } from '../messages/messages.controller';
import { authenticate } from '../../middleware/auth.middleware';

export const conversationsRouter = Router();

// All conversations routes require authentication
conversationsRouter.use(authenticate);

conversationsRouter.post('/', (req, res, next) =>
  conversationsController.createDirectConversation(req, res, next)
);

conversationsRouter.get('/', (req, res, next) =>
  conversationsController.listConversations(req, res, next)
);

conversationsRouter.get('/:id', (req, res, next) =>
  conversationsController.getConversation(req, res, next)
);

// GET /conversations/:id/messages with cursor pagination
conversationsRouter.get('/:id/messages', (req, res, next) =>
  messagesController.getConversationMessages(req, res, next)
);
