import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../utils/errors';
import { logger } from '../config/logger';
import { config } from '../config/env';
import { sendError } from '../utils/response';

export const errorHandler = (
  err: Error,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction
): void => {
  // 1. Zod Validation Errors
  if (err instanceof ZodError) {
    const formattedErrors = err.errors.map((issue) => ({
      path: issue.path.join('.'),
      message: issue.message,
    }));

    logger.warn({ path: req.path, errors: formattedErrors }, 'Validation error');
    sendError(res, 'Validation failed', 400, formattedErrors);
    return;
  }

  // 2. Payload Too Large (exceeds the 100 KB body limit)
  if ('type' in err && (err as { type: string }).type === 'entity.too.large') {
    logger.warn({ path: req.path, error: err.message }, 'Request payload too large');
    sendError(res, 'Request payload too large. Maximum body size is 100 KB.', 413);
    return;
  }

  // 3. Syntax Errors (e.g. malformed JSON request body)
  if ('type' in err && (err as { type: string }).type === 'entity.parse.failed') {
    logger.warn({ path: req.path, error: err.message }, 'Malformed JSON body');
    sendError(res, 'Malformed JSON in request body', 400);
    return;
  }

  // 3. Known Operational AppErrors
  if (err instanceof AppError) {
    if (err.statusCode >= 500) {
      logger.error({ err, path: req.path }, err.message);
    } else {
      logger.warn({ path: req.path, statusCode: err.statusCode }, err.message);
    }

    sendError(res, err.message, err.statusCode, err.details);
    return;
  }

  // 4. Unhandled / Unexpected Errors
  logger.error(
    {
      err: {
        name: err.name,
        message: err.message,
        stack: err.stack,
      },
      path: req.path,
      method: req.method,
    },
    'Unhandled server exception'
  );

  const message = config.NODE_ENV === 'production'
    ? 'Internal server error'
    : err.message || 'Internal server error';

  const details = config.NODE_ENV === 'production' ? undefined : { stack: err.stack };

  sendError(res, message, 500, details);
};
