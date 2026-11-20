import { Router } from 'express';
import { callsController } from './calls.controller';
import { authenticate } from '../../middleware/auth.middleware';

export const callsRouter = Router();

// All calls routes require authentication
callsRouter.use(authenticate);

callsRouter.get('/ice-servers', (req, res, next) =>
  callsController.getIceServers(req, res, next)
);
