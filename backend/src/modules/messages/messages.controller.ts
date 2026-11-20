import { Request, Response, NextFunction } from 'express';
import { messagesService } from './messages.service';
import { getConversationMessagesQuerySchema, conversationParamSchema } from './messages.schema';
import { sendSuccess } from '../../utils/response';
import { UnauthorizedError } from '../../utils/errors';

export class MessagesController {
  /**
   * GET /conversations/:id/messages
   */
  async getConversationMessages(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.user) throw new UnauthorizedError();
      const { id: conversationId } = conversationParamSchema.parse(req.params);
      const query = getConversationMessagesQuerySchema.parse(req.query);

      const result = await messagesService.getConversationMessages(
        req.user.userId,
        conversationId,
        query
      );

      sendSuccess(res, result, 200);
    } catch (err) {
      next(err);
    }
  }
}

export const messagesController = new MessagesController();
