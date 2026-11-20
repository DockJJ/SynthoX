import { Socket } from 'socket.io';
import { ExtendedError } from 'socket.io/dist/namespace';
import { verifyAccessToken } from '../modules/auth/auth.utils';
import { logger } from '../config/logger';

export const socketAuthMiddleware = (
  socket: Socket,
  next: (err?: ExtendedError) => void
): void => {
  try {
    // 1. Extract token from auth payload or authorization header
    const token =
      socket.handshake.auth?.token ||
      (typeof socket.handshake.headers?.authorization === 'string'
        ? socket.handshake.headers.authorization.replace(/^Bearer\s+/i, '').trim()
        : null);

    if (!token) {
      logger.warn({ socketId: socket.id }, 'Socket connection rejected: No token provided');
      return next(new Error('Authentication error: Missing access token'));
    }

    // 2. Verify JWT access token
    const userPayload = verifyAccessToken(token);

    // 3. Attach authenticated user payload to socket data
    socket.data.user = userPayload;

    logger.debug(
      { socketId: socket.id, userId: userPayload.userId, username: userPayload.username },
      'Socket authenticated successfully'
    );

    next();
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Invalid token';
    logger.warn({ socketId: socket.id, error: message }, 'Socket authentication failed');
    next(new Error(`Authentication error: ${message}`));
  }
};
