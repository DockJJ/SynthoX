import rateLimit from 'express-rate-limit';
import { Request, Response } from 'express';
import { sendError } from '../utils/response';

/**
 * Auth rate limiter: 10 requests per 15-minute window per IP.
 * Applied to POST /auth/signup, /auth/login.
 */
export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req: Request, res: Response) => {
    sendError(res, 'Too many authentication attempts. Please try again after 15 minutes.', 429);
  },
});

/**
 * Global API rate limiter: 300 requests per 15-minute window per IP.
 * Applied to all /api routes as a baseline protection.
 */
export const globalApiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req: Request, res: Response) => {
    sendError(res, 'Too many requests. Please try again later.', 429);
  },
});

/**
 * Search rate limiter: 60 requests per 1-minute window per IP.
 * Applied to GET /users/search to prevent abuse of search queries.
 */
export const searchRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req: Request, res: Response) => {
    sendError(res, 'Too many search requests. Please try again in a minute.', 429);
  },
});
