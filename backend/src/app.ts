import express, { Application, Request, Response } from 'express';
import cors, { CorsOptions } from 'cors';
import helmet from 'helmet';
import { config } from './config/env';
import { requestLogger } from './middleware/requestLogger.middleware';
import { notFoundHandler } from './middleware/notFound.middleware';
import { errorHandler } from './middleware/error.middleware';
import { sendSuccess } from './utils/response';
import { authRouter } from './modules/auth';
import { usersRouter } from './modules/users';
import { conversationsRouter } from './modules/conversations';
import { callsRouter } from './modules/calls';
import { authenticate } from './middleware/auth.middleware';
import { globalApiLimiter, searchRateLimiter } from './middleware/rateLimit.middleware';

export const createApp = (): Application => {
  const app = express();

  // 1. Security Headers — strict hardened Helmet configuration
  app.use(
    helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          scriptSrc: ["'self'"],
          styleSrc: ["'self'"],
          imgSrc: ["'self'", 'data:', 'https:'],
          connectSrc: ["'self'"],
          fontSrc: ["'self'"],
          objectSrc: ["'none'"],
          frameSrc: ["'none'"],
        },
      },
      crossOriginEmbedderPolicy: true,
      crossOriginOpenerPolicy: { policy: 'same-origin' },
      crossOriginResourcePolicy: { policy: 'same-origin' },
      dnsPrefetchControl: { allow: false },
      frameguard: { action: 'deny' },
      hidePoweredBy: true,
      hsts: { maxAge: 31536000, includeSubDomains: true, preload: true },
      ieNoOpen: true,
      noSniff: true,
      referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
      xssFilter: true,
    })
  );

  // 2. CORS Configuration
  const corsOptions: CorsOptions = {
    origin: config.CORS_ORIGIN === '*' ? '*' : config.CORS_ORIGIN.split(',').map((o) => o.trim()),
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    credentials: true,
  };
  app.use(cors(corsOptions));

  // 3. Body Parsing — reject oversized payloads (100 KB)
  app.use(express.json({ limit: '100kb' }));
  app.use(express.urlencoded({ extended: true, limit: '100kb' }));

  // 4. Request Logging
  app.use(requestLogger);

  // 5. Health Check Endpoint
  app.get('/health', (_req: Request, res: Response) => {
    sendSuccess(res, {
      status: 'healthy',
      uptimeSeconds: Math.floor(process.uptime()),
      timestamp: new Date().toISOString(),
      environment: config.NODE_ENV,
      version: '1.0.0',
    });
  });

  // Root welcome & API info
  app.get('/', (_req: Request, res: Response) => {
    sendSuccess(res, {
      name: 'SynthoX Backend API',
      description: 'Telehealth, Real-time Chat & WebRTC Signaling Gateway',
      version: '1.0.0',
      docs: '/api/docs',
      health: '/health',
    });
  });

  // 6. Global API rate limiter — baseline protection for all /api routes
  app.use('/api', globalApiLimiter);

  // 7. Search rate limiter — tighter limit on search queries
  app.use('/users/search', searchRateLimiter);
  app.use('/api/users/search', searchRateLimiter);

  // 8. Mount Feature Routers (supporting both root and /api prefixes)
  // Auth
  app.use('/auth', authRouter);
  app.use('/api/auth', authRouter);

  // Users
  app.use('/users', usersRouter);
  app.use('/api/users', usersRouter);

  // Conversations & Messages
  app.use('/conversations', conversationsRouter);
  app.use('/api/conversations', conversationsRouter);

  // WebRTC Calls & ICE Servers
  app.use('/calls', callsRouter);
  app.use('/api/calls', callsRouter);

  // Protected verification probe
  app.get('/auth/verify', authenticate, (req: Request, res: Response) => {
    sendSuccess(res, {
      message: 'Token authenticated successfully',
      user: req.user,
    });
  });

  // 7. 404 Handler
  app.use(notFoundHandler);

  // 8. Centralized Error Handler
  app.use(errorHandler);

  return app;
};
