import { Request, Response, NextFunction } from 'express';
import { conversationsService } from './conversations.service';
import { createConversationSchema, conversationIdParamSchema } from './conversations.schema';
import { sendSuccess } from '../../utils/response';
import { UnauthorizedError } from '../../utils/errors';

export class ConversationsController {
  /**
   * POST /conversations
   */
  async createDirectConversation(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const input = createConversationSchema.parse(req.body);
      const conversation = await conversationsService.createDirectConversation(
        req.user.userId,
        input.recipientId
      );
      sendSuccess(res, { conversation }, 201);
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /conversations
   */
  async listConversations(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const conversations = await conversationsService.listUserConversations(req.user.userId);
      sendSuccess(res, { conversations, count: conversations.length }, 200);
    } catch (err) {
      next(err);
    }
  }

  /**
   * GET /conversations/:id
   */
  async getConversation(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const { id } = conversationIdParamSchema.parse(req.params);
      const conversation = await conversationsService.getConversationById(req.user.userId, id);
      sendSuccess(res, { conversation }, 200);
    } catch (err) {
      next(err);
    }
  }
}

export const conversationsController = new ConversationsController();
