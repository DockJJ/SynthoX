import { Request, Response, NextFunction } from 'express';
import { callsService } from './calls.service';
import { sendSuccess } from '../../utils/response';
import { UnauthorizedError } from '../../utils/errors';

export class CallsController {
  /**
   * GET /calls/ice-servers
   */
  getIceServers(req: Request, res: Response, next: NextFunction): void {
    try {
      if (!req.user) throw new UnauthorizedError();
      const iceServers = callsService.getIceServers(req.user.userId);
      sendSuccess(res, iceServers, 200);
    } catch (err) {
      next(err);
    }
  }
}

export const callsController = new CallsController();
