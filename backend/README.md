# SynthoX Backend

Production-grade backend for the **SynthoX** telehealth mobile app — real-time chat, WebRTC peer-to-peer audio/video calling, and user account management.

Built with **Node.js 20 + TypeScript + Express + Socket.IO + PostgreSQL (Prisma) + Redis + coturn**.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Requirements](#requirements)
3. [Quick Start](#quick-start)
4. [Environment Variables](#environment-variables)
5. [Database Setup](#database-setup)
6. [Running the Server](#running-the-server)
7. [Running Tests](#running-tests)
8. [Project Structure](#project-structure)
9. [API Reference](#api-reference)

---

## Architecture Overview

```
Flutter Client
     │
     ├── HTTP (REST)        → Express REST API
     │                            ├── /auth    (signup, login, refresh, logout)
     │                            ├── /users   (profile, search)
     │                            ├── /conversations (1:1 chat rooms)
     │                            └── /calls   (ICE servers / TURN credentials)
     │
     └── WebSocket          → Socket.IO Server
                                  ├── Chat   (message:send/new/delivered/read, typing)
                                  ├── Presence (online/offline via Redis)
                                  └── WebRTC Signaling (call:invite/accept/offer/answer/…)

Infrastructure (Docker):
  ├── PostgreSQL 16   — persistent storage (users, messages, call logs)
  ├── Redis 7         — presence tracking + Socket.IO horizontal scaling adapter
  └── coturn          — STUN/TURN relay server for WebRTC NAT traversal
```

**Key design decisions:**

| Concern | Solution |
|---------|----------|
| Auth | Short-lived JWT access tokens (15 min) + long-lived opaque refresh tokens (30 days) stored hashed in DB; rotated on every refresh |
| Passwords | argon2id hashing |
| Input validation | Zod on every REST route and every Socket.IO event |
| Payload limits | 100 KB on REST (`express.json`) and 100 KB on Socket.IO (`maxHttpBufferSize`) |
| Presence | Redis Set per user, with in-memory fallback when Redis is unavailable |
| TURN credentials | RFC 5766 shared-secret HMAC-SHA1 method (no TURN REST API process required) |
| Scaling | `@socket.io/redis-adapter` — multiple server instances share socket rooms via Redis pub/sub |

---

## Requirements

| Tool | Version |
|------|---------|
| Node.js | ≥ 20.0.0 |
| npm | ≥ 10 |
| Docker Desktop | ≥ 24 |
| Docker Compose | V2 (bundled with Docker Desktop) |

---

## Quick Start

```bash
# 1. Clone / navigate to the backend directory
cd C:\dev\synthox\backend

# 2. Install dependencies
npm install

# 3. Copy the example environment file and fill in secrets
copy .env.example .env
# → Edit .env and set strong JWT and TURN secrets before running in any real environment

# 4. Start PostgreSQL, Redis, and coturn via Docker
docker compose up -d

# 5. Generate Prisma client and run database migrations
npm run prisma:generate
npm run prisma:migrate

# 6. Start the development server (hot-reload via tsx)
npm run dev
```

The server will be available at **http://localhost:5000**.
Health check: **http://localhost:5000/health**

---

## Environment Variables

Copy `.env.example` to `.env` and set every value before running.

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NODE_ENV` | No | `development` | `development`, `test`, or `production` |
| `PORT` | No | `5000` | HTTP server port |
| `HOST` | No | `0.0.0.0` | Bind address |
| `CORS_ORIGIN` | No | `*` | Allowed CORS origins. Comma-separated list or `*` |
| `LOG_LEVEL` | No | `info` | Pino log level: `fatal`, `error`, `warn`, `info`, `debug`, `trace` |
| `DATABASE_URL` | **Yes** | — | PostgreSQL connection string (Prisma format) |
| `REDIS_URL` | No | `redis://localhost:6379` | Redis connection URL |
| `JWT_ACCESS_SECRET` | **Yes** | — | ≥ 32-char secret for signing access tokens |
| `JWT_REFRESH_SECRET` | **Yes** | — | ≥ 32-char secret for signing refresh tokens (unused in current opaque-token implementation, reserved for future JWT refresh) |
| `JWT_ACCESS_EXPIRES_IN` | No | `15m` | Access token TTL (e.g. `15m`, `1h`) |
| `JWT_REFRESH_EXPIRES_IN` | No | `30d` | Refresh token TTL stored in DB |
| `TURN_SECRET` | **Yes** | — | ≥ 16-char shared secret matching coturn `static-auth-secret` |
| `TURN_REALM` | No | `synthox.local` | coturn realm (must match `turnserver.conf`) |
| `STUN_URL` | No | `stun:localhost:3478` | STUN server URL returned to Flutter clients |
| `TURN_URL` | No | `turn:localhost:3478` | Base TURN server URL |
| `TURN_TTL_SECONDS` | No | `86400` | Lifetime of issued TURN credentials in seconds |

> [!CAUTION]
> **Never commit `.env` to version control.** Generate strong secrets with:
> ```bash
> node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
> # or
> openssl rand -hex 32
> ```

---

## Database Setup

```bash
# Generate the Prisma TypeScript client (run after any schema change)
npm run prisma:generate

# Run all pending migrations (creates tables on first run)
npm run prisma:migrate

# Open Prisma Studio (GUI browser for the database)
npx prisma studio
```

### Schema tables

| Table | Purpose |
|-------|---------|
| `users` | User accounts |
| `refresh_tokens` | Hashed refresh tokens with expiry and revocation flag |
| `conversations` | 1:1 chat rooms |
| `conversation_members` | Membership join table with `lastReadAt` for unread counts |
| `messages` | Chat messages with delivery and read timestamps |
| `call_logs` | Audit log of every call attempt with status and duration |

---

## Running the Server

```bash
# Development (hot-reload)
npm run dev

# Production build
npm run build
npm start

# Type-check without emitting
npm run typecheck
```

---

## Running Tests

```bash
# Run all tests once (Vitest)
npm test

# Watch mode
npm run test:watch
```

**Test suites (50 tests total):**

| Suite | Type | Coverage |
|-------|------|---------|
| `auth.unit.test.ts` | Unit | Password hashing, token generation, JWT verification, Zod schemas |
| `users.unit.test.ts` | Unit | User update and search Zod schemas |
| `conversations.unit.test.ts` | Unit | Conversation creation and param Zod schemas |
| `messages.unit.test.ts` | Unit | Message pagination query Zod schemas |
| `calls.unit.test.ts` | Unit | ICE credential generation (RFC 5766 HMAC-SHA1), call signaling Zod schemas, CallManager lifecycle |
| `sockets.unit.test.ts` | Unit | Socket Zod schemas, PresenceService multi-socket tracking, JWT handshake middleware |
| `sockets.integration.test.ts` | Integration | Live Socket.IO server: reject unauthenticated connections, authenticated connect + presence query |

> [!NOTE]
> Unit tests run without a database or Redis connection. The integration test spins up a real Socket.IO server on a random port and tears it down automatically.

---

## Project Structure

```
backend/
├── prisma/
│   ├── schema.prisma          # Database schema and relations
│   └── migrations/            # Prisma migration files
├── src/
│   ├── app.ts                 # Express app factory (middleware, routes)
│   ├── server.ts              # HTTP server bootstrap and graceful shutdown
│   ├── config/
│   │   ├── env.ts             # Zod-validated environment configuration
│   │   ├── logger.ts          # Pino structured logger
│   │   ├── prisma.ts          # Prisma client singleton
│   │   └── redis.ts           # ioredis client factory
│   ├── middleware/
│   │   ├── auth.middleware.ts         # JWT Bearer token verification
│   │   ├── error.middleware.ts        # Centralized error handler (Zod, AppError, 413, 400, 500)
│   │   ├── notFound.middleware.ts     # 404 handler
│   │   ├── rateLimit.middleware.ts    # Three-tier REST rate limiters
│   │   └── requestLogger.middleware.ts # pino-http request logging
│   ├── modules/
│   │   ├── auth/              # Signup, login, refresh, logout
│   │   ├── users/             # Profile and search
│   │   ├── conversations/     # 1:1 conversation management
│   │   ├── messages/          # Cursor-paginated message history
│   │   └── calls/             # ICE servers endpoint
│   ├── sockets/
│   │   ├── index.ts           # Socket.IO server initialization (Redis adapter, auth middleware)
│   │   ├── socket.auth.ts     # Handshake JWT authentication middleware
│   │   ├── socket.schema.ts   # Zod schemas for chat events
│   │   ├── socket.types.ts    # TypeScript types for authenticated sockets
│   │   ├── socket.limiter.ts  # Per-socket packet rate limiter
│   │   ├── chat.handler.ts    # message:*, typing:*, presence:get handlers
│   │   ├── call.handler.ts    # call:* signaling relay handlers
│   │   ├── call.manager.ts    # In-memory call state, ring timeout, call logging
│   │   ├── call.schema.ts     # Zod schemas for call signaling events
│   │   ├── call.types.ts      # Call state TypeScript types
│   │   └── presence.service.ts # Redis-backed online/offline tracking
│   └── utils/
│       ├── errors.ts          # Typed AppError subclasses (400/401/403/404/409/500)
│       └── response.ts        # Uniform JSON envelope helpers (sendSuccess / sendError)
├── docker-compose.yml         # PostgreSQL 16, Redis 7, coturn
├── turnserver.conf            # coturn configuration
├── vitest.config.ts           # Vitest test runner configuration
├── tsconfig.json              # TypeScript compiler options
├── .env.example               # Environment variable template
└── package.json
```

---

## API Reference

See **[API.md](./API.md)** for complete documentation of every REST endpoint and Socket.IO event with request/response payload examples formatted for Flutter client integration.
