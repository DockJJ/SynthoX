# SynthoX API Reference

Complete documentation for all REST endpoints and Socket.IO events in the SynthoX backend.
Built for the Flutter client using `http`, `socket_io_client`, `flutter_webrtc`, and `flutter_secure_storage`.

---

## Table of Contents

- [General Conventions](#general-conventions)
- [Authentication](#authentication)
- [REST Endpoints](#rest-endpoints)
  - [Health](#get-health)
  - [Auth — POST /auth/signup](#post-authsignup)
  - [Auth — POST /auth/login](#post-authlogin)
  - [Auth — POST /auth/refresh](#post-authrefresh)
  - [Auth — POST /auth/logout](#post-authlogout)
  - [Users — GET /users/me](#get-usersme)
  - [Users — PATCH /users/me](#patch-usersme)
  - [Users — GET /users/search](#get-userssearch)
  - [Conversations — POST /conversations](#post-conversations)
  - [Conversations — GET /conversations](#get-conversations)
  - [Conversations — GET /conversations/:id](#get-conversationsid)
  - [Messages — GET /conversations/:id/messages](#get-conversationsidmessages)
  - [Calls — GET /calls/ice-servers](#get-callsice-servers)
- [Socket.IO Events](#socketio-events)
  - [Connection & Authentication](#connection--authentication)
  - [Chat Events](#chat-events)
  - [Presence Events](#presence-events)
  - [Call Signaling Events](#call-signaling-events)
- [Error Reference](#error-reference)
- [Flutter Integration Notes](#flutter-integration-notes)

---

## General Conventions

### Base URL

```
http://localhost:5000
# or prefixed:
http://localhost:5000/api
```

Both prefixes (`/auth/...` and `/api/auth/...`) resolve to the same handlers.

### Response Envelope

Every response (success or error) uses this JSON envelope:

**Success:**
```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "timestamp": "2026-11-20T13:00:00.000Z"
  }
}
```

**Error:**
```json
{
  "success": false,
  "error": {
    "message": "Human-readable error message",
    "details": [ ... ]
  },
  "meta": {
    "timestamp": "2026-11-20T13:00:00.000Z"
  }
}
```

### Common HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 400 | Validation error or bad request |
| 401 | Missing or invalid access token |
| 403 | Forbidden (authenticated but not authorized) |
| 404 | Resource not found |
| 409 | Conflict (duplicate email/username) |
| 413 | Payload too large (> 100 KB) |
| 429 | Rate limit exceeded |
| 500 | Internal server error |

---

## Authentication

Protected endpoints require a **Bearer access token** in the `Authorization` header:

```
Authorization: Bearer <accessToken>
```

Access tokens expire in **15 minutes**. Use `POST /auth/refresh` to rotate them.

**Flutter storage:** Store `accessToken` and `refreshToken` in `flutter_secure_storage`. Never store in `SharedPreferences`.

---

## REST Endpoints

---

### GET /health

Check server health. No authentication required.

**Response 200:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "uptimeSeconds": 342,
    "timestamp": "2026-11-20T13:00:00.000Z",
    "environment": "development",
    "version": "1.0.0"
  },
  "meta": { "timestamp": "2026-11-20T13:00:00.000Z" }
}
```

---

### POST /auth/signup

Register a new user account. Returns the user profile and token pair.

> Rate limited: **10 requests per 15 minutes per IP**.

**Request body:**
```json
{
  "email": "alice@synthox.health",
  "username": "alice_md",
  "displayName": "Dr. Alice",
  "password": "password123",
  "avatarUrl": "https://cdn.example.com/alice.jpg"
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `email` | string | Yes | Valid email; lowercased automatically |
| `username` | string | Yes | 3–30 chars; alphanumeric + underscores; lowercased automatically |
| `displayName` | string | Yes | 1–50 chars |
| `password` | string | Yes | 8–100 chars; must contain ≥ 1 letter and ≥ 1 number |
| `avatarUrl` | string | No | Valid URL |

**Response 201:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "alice@synthox.health",
      "username": "alice_md",
      "displayName": "Dr. Alice",
      "avatarUrl": "https://cdn.example.com/alice.jpg",
      "createdAt": "2026-11-20T13:00:00.000Z"
    },
    "tokens": {
      "accessToken": "eyJhbGc...",
      "refreshToken": "a1b2c3d4e5f6...",
      "expiresIn": 900,
      "tokenType": "Bearer"
    }
  },
  "meta": { "timestamp": "2026-11-20T13:00:00.000Z" }
}
```

**Errors:** 400 (validation), 409 (email or username already taken)

---

### POST /auth/login

Authenticate with email or username + password.

> Rate limited: **10 requests per 15 minutes per IP**.

**Request body:**
```json
{
  "login": "alice@synthox.health",
  "password": "password123"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `login` | string | Yes | Email address **or** username |
| `password` | string | Yes | Account password |

**Response 200:** Same shape as `/auth/signup` response (user + tokens).

**Errors:** 400 (validation), 401 (invalid credentials)

---

### POST /auth/refresh

Exchange a valid refresh token for a new access token + refresh token pair. The old refresh token is **revoked immediately** (token rotation).

**Request body:**
```json
{
  "refreshToken": "a1b2c3d4e5f6..."
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "tokens": {
      "accessToken": "eyJhbGc...",
      "refreshToken": "f7g8h9i0j1k2...",
      "expiresIn": 900,
      "tokenType": "Bearer"
    }
  },
  "meta": { "timestamp": "2026-11-20T13:00:00.000Z" }
}
```

**Errors:** 400 (validation), 401 (token invalid, expired, or already revoked)

**Flutter pattern:**
```dart
// In your http interceptor — on 401, call refresh and retry
Future<void> refreshTokens() async {
  final refreshToken = await secureStorage.read(key: 'refreshToken');
  final response = await http.post(
    Uri.parse('$baseUrl/auth/refresh'),
    body: jsonEncode({'refreshToken': refreshToken}),
    headers: {'Content-Type': 'application/json'},
  );
  final data = jsonDecode(response.body)['data']['tokens'];
  await secureStorage.write(key: 'accessToken',  value: data['accessToken']);
  await secureStorage.write(key: 'refreshToken', value: data['refreshToken']);
}
```

---

### POST /auth/logout

Revoke the refresh token. If `refreshToken` is omitted, **all** active sessions for the authenticated user are revoked.

**Headers:** `Authorization: Bearer <accessToken>` *(optional — improves session-scoped logout)*

**Request body:**
```json
{
  "refreshToken": "a1b2c3d4e5f6..."
}
```

**Response 200:**
```json
{
  "success": true,
  "data": { "message": "Logged out successfully" },
  "meta": { "timestamp": "2026-11-20T13:00:00.000Z" }
}
```

---

### GET /users/me

Return the authenticated user's profile.

**Headers:** `Authorization: Bearer <accessToken>`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "alice@synthox.health",
      "username": "alice_md",
      "displayName": "Dr. Alice",
      "avatarUrl": "https://cdn.example.com/alice.jpg",
      "createdAt": "2026-11-20T13:00:00.000Z"
    }
  },
  "meta": { "timestamp": "2026-11-20T13:00:00.000Z" }
}
```

---

### PATCH /users/me

Update the authenticated user's display name or avatar URL. At least one field must be provided.

**Headers:** `Authorization: Bearer <accessToken>`

**Request body:**
```json
{
  "displayName": "Dr. Alice Smith",
  "avatarUrl": "https://cdn.example.com/new-avatar.jpg"
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `displayName` | string | At least one | 1–50 chars |
| `avatarUrl` | string \| null | At least one | Valid URL or `null` to clear |

**Response 200:** Same shape as `GET /users/me`.

**Errors:** 400 (neither field provided or invalid URL)

---

### GET /users/search

Search for users by username or display name (case-insensitive). The calling user is excluded from results.

**Headers:** `Authorization: Bearer <accessToken>`

> Rate limited: **60 requests per 1 minute per IP**.

**Query parameters:**

| Param | Type | Required | Rules |
|-------|------|----------|-------|
| `q` | string | Yes | 1–50 chars |
| `limit` | number | No | 1–50; default 20 |

**Example:** `GET /users/search?q=alice&limit=10`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "username": "alice_md",
        "displayName": "Dr. Alice",
        "avatarUrl": "https://cdn.example.com/alice.jpg"
      }
    ],
    "count": 1
  },
  "meta": { "timestamp": "2026-11-20T13:00:00.000Z" }
}
```

---

### POST /conversations

Create a new 1:1 conversation with another user, or return the existing one if it already exists (idempotent).

**Headers:** `Authorization: Bearer <accessToken>`

**Request body:**
```json
{
  "recipientId": "660e8400-e29b-41d4-a716-446655440001"
}
```

**Response 201:**
```json
{
  "success": true,
  "data": {
    "conversation": {
      "id": "770e8400-e29b-41d4-a716-446655440002",
      "isGroup": false,
      "createdAt": "2026-11-20T13:00:00.000Z",
      "updatedAt": "2026-11-20T13:00:00.000Z",
      "members": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440000",
          "username": "alice_md",
          "displayName": "Dr. Alice",
          "avatarUrl": "https://cdn.example.com/alice.jpg"
        },
        {
          "id": "660e8400-e29b-41d4-a716-446655440001",
          "username": "bob_patient",
          "displayName": "Bob",
          "avatarUrl": null
        }
      ],
      "lastMessage": null,
      "unreadCount": 0
    }
  },
  "meta": { "timestamp": "2026-11-20T13:00:00.000Z" }
}
```

**Errors:** 400 (self-conversation), 404 (recipient not found)

---

### GET /conversations

List all conversations for the authenticated user, ordered by most recently active.

**Headers:** `Authorization: Bearer <accessToken>`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "conversations": [
      {
        "id": "770e8400-e29b-41d4-a716-446655440002",
        "isGroup": false,
        "createdAt": "2026-11-20T13:00:00.000Z",
        "updatedAt": "2026-11-20T13:05:00.000Z",
        "members": [ { "id": "...", "username": "bob_patient", "displayName": "Bob", "avatarUrl": null } ],
        "lastMessage": {
          "id": "880e8400-e29b-41d4-a716-446655440003",
          "senderId": "550e8400-e29b-41d4-a716-446655440000",
          "content": "Hello Bob!",
          "createdAt": "2026-11-20T13:05:00.000Z",
          "deliveredAt": "2026-11-20T13:05:01.000Z",
          "readAt": null
        },
        "unreadCount": 2
      }
    ],
    "count": 1
  },
  "meta": { "timestamp": "2026-11-20T13:00:00.000Z" }
}
```

---

### GET /conversations/:id

Get a single conversation by ID. Returns 403 if the caller is not a member.

**Headers:** `Authorization: Bearer <accessToken>`

**Response 200:** Same shape as a single item from `GET /conversations`.

**Errors:** 403 (not a member), 404 (not found)

---

### GET /conversations/:id/messages

Fetch messages in a conversation with **cursor-based pagination** (newest first).

**Headers:** `Authorization: Bearer <accessToken>`

**Query parameters:**

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `limit` | number | No | 1–50; default 20 |
| `cursor` | string | No | Message ID to paginate from (exclusive). Omit for the first page. |

**Example first page:** `GET /conversations/770e.../messages?limit=20`
**Example next page:** `GET /conversations/770e.../messages?limit=20&cursor=880e8400-...`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "messages": [
      {
        "id": "880e8400-e29b-41d4-a716-446655440003",
        "conversationId": "770e8400-e29b-41d4-a716-446655440002",
        "senderId": "550e8400-e29b-41d4-a716-446655440000",
        "sender": {
          "id": "550e8400-e29b-41d4-a716-446655440000",
          "username": "alice_md",
          "displayName": "Dr. Alice",
          "avatarUrl": "https://cdn.example.com/alice.jpg"
        },
        "content": "Hello Bob!",
        "createdAt": "2026-11-20T13:05:00.000Z",
        "deliveredAt": "2026-11-20T13:05:01.000Z",
        "readAt": null
      }
    ],
    "nextCursor": null,
    "hasMore": false
  },
  "meta": { "timestamp": "2026-11-20T13:00:00.000Z" }
}
```

> When `hasMore` is `true`, pass `nextCursor` as the `cursor` query param for the next page.

**Errors:** 403 (not a member), 404 (conversation not found), 400 (invalid cursor)

---

### GET /calls/ice-servers

Return STUN and TURN server configurations with ephemeral credentials valid for `TURN_TTL_SECONDS` (default 24 hours). Call this endpoint before initiating or accepting a WebRTC call.

**Headers:** `Authorization: Bearer <accessToken>`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "realm": "synthox.local",
    "ttl": 86400,
    "iceServers": [
      {
        "urls": "stun:localhost:3478"
      },
      {
        "urls": [
          "turn:localhost:3478?transport=udp",
          "turn:localhost:3478?transport=tcp"
        ],
        "username": "1764000000:550e8400-e29b-41d4-a716-446655440000",
        "credential": "AbCdEfGhIjKlMnOp=="
      }
    ]
  },
  "meta": { "timestamp": "2026-11-20T13:00:00.000Z" }
}
```

**Flutter WebRTC usage:**
```dart
final response = await http.get(
  Uri.parse('$baseUrl/calls/ice-servers'),
  headers: {'Authorization': 'Bearer $accessToken'},
);
final data = jsonDecode(response.body)['data'];
final configuration = RTCConfiguration(
  iceServers: (data['iceServers'] as List).map((server) {
    return RTCIceServer(
      urls: server['urls'] is List
          ? List<String>.from(server['urls'])
          : [server['urls'] as String],
      username: server['username'],
      credential: server['credential'],
    );
  }).toList(),
);
```

---

## Socket.IO Events

### Connection & Authentication

Connect to the Socket.IO server by passing the JWT access token in the handshake. The connection is **rejected** if the token is missing or invalid.

**Flutter connection:**
```dart
final socket = io('http://localhost:5000', OptionBuilder()
  .setTransports(['websocket'])
  .disableAutoConnect()
  .setAuth({'token': accessToken})
  .build(),
);
socket.connect();
```

Alternatively, the token may be sent in the `Authorization` header:
```dart
.setExtraHeaders({'Authorization': 'Bearer $accessToken'})
```

**On successful connection:**
- The user automatically joins their personal room: `user:<userId>`
- Presence is set to `online` and broadcast to contacts
- All chat and call handlers are registered

**On connection error:**
```dart
socket.on('connect_error', (err) {
  // err.message contains the reason (e.g. "Authentication error: Invalid access token")
});
```

> [!IMPORTANT]
> Access tokens expire in 15 minutes. If the socket disconnects with an auth error, refresh the token with `POST /auth/refresh` and reconnect with the new token.

---

### Chat Events

#### CLIENT → SERVER: `message:send`

Send a new message to a conversation. The message is **persisted to the database before** the acknowledgement is sent back.

**Payload:**
```json
{
  "conversationId": "770e8400-e29b-41d4-a716-446655440002",
  "content": "Hello Bob, how are you feeling?",
  "tempId": "local-uuid-for-optimistic-ui"
}
```

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `conversationId` | string | Yes | Must be a conversation the sender is a member of |
| `content` | string | Yes | 1–10,000 characters |
| `tempId` | string | No | Client-generated ID for optimistic UI reconciliation |

**Acknowledgement callback:**
```dart
socket.emitWithAck('message:send', {
  'conversationId': convId,
  'content': 'Hello!',
  'tempId': 'temp-123',
}, ack: (response) {
  if (response['success'] == true) {
    final message = response['data']; // saved message object
  } else {
    print('Failed: ${response['error']}');
  }
});
```

**Ack success payload:**
```json
{
  "success": true,
  "data": {
    "id": "880e8400-e29b-41d4-a716-446655440003",
    "conversationId": "770e8400-e29b-41d4-a716-446655440002",
    "senderId": "550e8400-e29b-41d4-a716-446655440000",
    "sender": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "username": "alice_md",
      "displayName": "Dr. Alice",
      "avatarUrl": "https://cdn.example.com/alice.jpg"
    },
    "content": "Hello Bob, how are you feeling?",
    "createdAt": "2026-11-20T13:05:00.000Z",
    "deliveredAt": null,
    "readAt": null
  }
}
```

---

#### SERVER → CLIENT: `message:new`

Emitted to **other members** of the conversation when a new message is sent.

**Payload:**
```json
{
  "message": {
    "id": "880e8400-e29b-41d4-a716-446655440003",
    "conversationId": "770e8400-e29b-41d4-a716-446655440002",
    "senderId": "550e8400-e29b-41d4-a716-446655440000",
    "sender": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "username": "alice_md",
      "displayName": "Dr. Alice",
      "avatarUrl": "https://cdn.example.com/alice.jpg"
    },
    "content": "Hello Bob, how are you feeling?",
    "createdAt": "2026-11-20T13:05:00.000Z",
    "deliveredAt": null,
    "readAt": null
  }
}
```

**Flutter:**
```dart
socket.on('message:new', (data) {
  final message = data['message'];
  // Add to local message list and trigger UI rebuild
});
```

---

#### CLIENT → SERVER: `message:delivered`

Notify the sender that a message has been delivered to the recipient's device. The server updates `deliveredAt` in the database (idempotent — only sets it once).

**Payload:**
```json
{
  "messageId": "880e8400-e29b-41d4-a716-446655440003",
  "conversationId": "770e8400-e29b-41d4-a716-446655440002"
}
```

**Ack success payload:**
```json
{ "success": true, "data": { "messageId": "880e8400-..." } }
```

---

#### SERVER → CLIENT: `message:delivered`

Emitted to the **original sender** when their message is delivered.

**Payload:**
```json
{
  "messageId": "880e8400-e29b-41d4-a716-446655440003",
  "conversationId": "770e8400-e29b-41d4-a716-446655440002",
  "deliveredAt": "2026-11-20T13:05:01.000Z",
  "recipientId": "660e8400-e29b-41d4-a716-446655440001"
}
```

---

#### CLIENT → SERVER: `message:read`

Mark all unread messages in a conversation as read. Updates `readAt` on all messages in the conversation sent by other users, and updates `lastReadAt` on the membership record.

**Payload:**
```json
{
  "conversationId": "770e8400-e29b-41d4-a716-446655440002"
}
```

**Ack success payload:**
```json
{ "success": true, "data": { "conversationId": "770e8400-..." } }
```

---

#### SERVER → CLIENT: `message:read`

Emitted to **other members** of the conversation when the user reads messages.

**Payload:**
```json
{
  "conversationId": "770e8400-e29b-41d4-a716-446655440002",
  "readerId": "660e8400-e29b-41d4-a716-446655440001",
  "readAt": "2026-11-20T13:06:00.000Z"
}
```

---

#### CLIENT → SERVER: `typing:start`

Notify other conversation members that this user started typing.

**Payload:**
```json
{
  "conversationId": "770e8400-e29b-41d4-a716-446655440002"
}
```

No acknowledgement. Invalid payloads are silently ignored.

---

#### SERVER → CLIENT: `typing:start`

**Payload:**
```json
{
  "conversationId": "770e8400-e29b-41d4-a716-446655440002",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "username": "alice_md"
}
```

---

#### CLIENT → SERVER: `typing:stop`

**Payload:**
```json
{
  "conversationId": "770e8400-e29b-41d4-a716-446655440002"
}
```

---

#### SERVER → CLIENT: `typing:stop`

**Payload:**
```json
{
  "conversationId": "770e8400-e29b-41d4-a716-446655440002",
  "userId": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

### Presence Events

#### CLIENT → SERVER: `presence:get`

Query the online/offline status of up to 100 users at once.

**Payload:**
```json
{
  "userIds": [
    "550e8400-e29b-41d4-a716-446655440000",
    "660e8400-e29b-41d4-a716-446655440001"
  ]
}
```

**Ack success payload:**
```json
{
  "success": true,
  "data": {
    "550e8400-e29b-41d4-a716-446655440000": "online",
    "660e8400-e29b-41d4-a716-446655440001": "offline"
  }
}
```

---

#### SERVER → CLIENT: `presence:update`

Broadcast to all conversation contacts when a user comes online or goes offline.

**Payload:**
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "online"
}
```

Values for `status`: `"online"` | `"offline"`

> Multi-device: a user is only marked `offline` when their **last** socket disconnects.

---

### Call Signaling Events

> [!IMPORTANT]
> The server **only relays signaling messages** between the two users. All audio and video data travels **peer-to-peer** (or via TURN relay). Always call `GET /calls/ice-servers` before initiating or accepting a call.

#### CLIENT → SERVER: `call:invite`

Initiate a call to another user. The server checks if the callee is online and not already in a call before forwarding.

**Payload:**
```json
{
  "calleeId": "660e8400-e29b-41d4-a716-446655440001",
  "callType": "video"
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `calleeId` | string | Yes | Target user ID |
| `callType` | string | No | `"video"` (default) or `"audio"` |

**Ack payloads:**

| Scenario | Ack |
|----------|-----|
| Invite forwarded to callee | `{ "success": true, "data": { "callId": "uuid", "callType": "video" } }` |
| Callee is offline | `{ "success": false, "reason": "callee_offline" }` |
| Callee is busy | `{ "success": false, "reason": "callee_busy" }` |
| Caller already in a call | `{ "success": false, "error": "You are already in an active call" }` |

---

#### SERVER → CLIENT: `call:invite`

Received by the **callee** when they are being called.

**Payload:**
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004",
  "callType": "video",
  "callerId": "550e8400-e29b-41d4-a716-446655440000",
  "callerUsername": "alice_md",
  "callerDisplayName": "Dr. Alice",
  "callerAvatarUrl": "https://cdn.example.com/alice.jpg"
}
```

**Flutter:**
```dart
socket.on('call:invite', (data) {
  // Show incoming call UI with caller info
  // Start 30-second ring countdown
  final callId = data['callId'];
  final callerName = data['callerDisplayName'];
});
```

---

#### CLIENT → SERVER: `call:accept`

Accept an incoming call. The server notifies the caller.

**Payload:**
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004"
}
```

**Ack:** `{ "success": true }` or `{ "success": false, "error": "Call not found" }`

---

#### SERVER → CLIENT: `call:accept`

Received by the **caller** when the callee accepts.

**Payload:**
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004",
  "calleeId": "660e8400-e29b-41d4-a716-446655440001"
}
```

After receiving this, the **caller creates the RTCPeerConnection and sends `call:offer`**.

---

#### CLIENT → SERVER: `call:reject`

Reject an incoming call.

**Payload:**
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004",
  "reason": "Busy with another patient"
}
```

The `reason` field is optional (defaults to `"Call rejected by user"`).

---

#### SERVER → CLIENT: `call:reject`

Received by the **caller** when the callee rejects.

**Payload:**
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004",
  "reason": "Busy with another patient"
}
```

---

#### SERVER → CLIENT: `call:busy`

Received by the **caller** when the callee is already in another call.

**Payload:**
```json
{
  "calleeId": "660e8400-e29b-41d4-a716-446655440001",
  "reason": "User is currently on another call"
}
```

---

#### CLIENT → SERVER: `call:offer`

Send the WebRTC SDP offer from caller to callee. Send **after** receiving `call:accept`.

**Payload:**
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004",
  "sdp": {
    "type": "offer",
    "sdp": "v=0\r\no=- 123456789 2 IN IP4 127.0.0.1\r\n..."
  }
}
```

The `sdp` field accepts either an SDP object `{ type, sdp }` or a raw SDP string.

---

#### SERVER → CLIENT: `call:offer`

Received by the **callee**. Create the peer connection and generate an answer.

**Payload:** Same as `call:offer` sent by caller, plus:
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004",
  "callerId": "550e8400-e29b-41d4-a716-446655440000",
  "sdp": { "type": "offer", "sdp": "..." }
}
```

---

#### CLIENT → SERVER: `call:answer`

Send the SDP answer from callee to caller.

**Payload:**
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004",
  "sdp": {
    "type": "answer",
    "sdp": "v=0\r\no=- 987654321 2 IN IP4 127.0.0.1\r\n..."
  }
}
```

---

#### SERVER → CLIENT: `call:answer`

Received by the **caller**. Set as the remote description on the peer connection.

**Payload:**
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004",
  "calleeId": "660e8400-e29b-41d4-a716-446655440001",
  "sdp": { "type": "answer", "sdp": "..." }
}
```

---

#### CLIENT → SERVER: `call:ice-candidate`

Send an ICE candidate from one peer to the other. Send as candidates are discovered by the WebRTC engine.

**Payload:**
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004",
  "candidate": {
    "candidate": "candidate:1 1 UDP 2130706431 192.168.1.5 54321 typ host",
    "sdpMid": "0",
    "sdpMLineIndex": 0
  }
}
```

The `candidate` field accepts either an RTCIceCandidate object or a raw candidate string.

---

#### SERVER → CLIENT: `call:ice-candidate`

Received by the **partner peer**. Add to the peer connection as a remote ICE candidate.

**Payload:**
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004",
  "fromUserId": "550e8400-e29b-41d4-a716-446655440000",
  "candidate": { "candidate": "...", "sdpMid": "0", "sdpMLineIndex": 0 }
}
```

**Flutter:**
```dart
socket.on('call:ice-candidate', (data) async {
  final candidate = RTCIceCandidate(
    data['candidate']['candidate'],
    data['candidate']['sdpMid'],
    data['candidate']['sdpMLineIndex'],
  );
  await peerConnection.addCandidate(candidate);
});
```

---

#### CLIENT → SERVER: `call:hangup`

End or cancel a call.

**Payload:**
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004",
  "reason": "User ended call"
}
```

The `reason` field is optional (defaults to `"Call ended"`).

---

#### SERVER → CLIENT: `call:hangup`

Received by the **partner** when the other side hangs up, disconnects, or the 30-second ring timeout fires.

**Payload:**
```json
{
  "callId": "990e8400-e29b-41d4-a716-446655440004",
  "reason": "Partner disconnected"
}
```

**Possible reasons:**
- `"User ended call"` — normal hangup
- `"Partner disconnected"` — socket disconnected mid-call
- `"Ring timeout: Callee did not answer"` — sent to caller after 30 s
- `"Ring timeout: Call missed"` — sent to callee after 30 s

**Flutter:**
```dart
socket.on('call:hangup', (data) {
  // Close peer connection and local streams
  peerConnection?.close();
  localStream?.dispose();
  // Navigate back to previous screen
});
```

---

#### SERVER → CLIENT: `error:rate-limit`

Emitted when the socket packet rate limit is exceeded (> 30 events in 5 seconds).

**Payload:**
```json
{
  "message": "Rate limit exceeded. Please slow down your requests."
}
```

After this event, the offending packet is dropped. The connection is not terminated unless the client continues exceeding the limit.

---

## Error Reference

### Validation Error (400)

Sent when Zod schema validation fails on any REST route:

```json
{
  "success": false,
  "error": {
    "message": "Validation failed",
    "details": [
      { "path": "email", "message": "Invalid email address" },
      { "path": "password", "message": "Password must contain at least one number" }
    ]
  },
  "meta": { "timestamp": "..." }
}
```

### Socket Validation Error

When a socket event fails Zod validation, the ack callback (if provided) receives:
```json
{ "success": false, "error": "Validation error message" }
```

Events without callbacks (`typing:start`, `typing:stop`) silently drop invalid payloads.

---

## Flutter Integration Notes

### Complete WebRTC Call Flow

```
Caller                          Server                          Callee
  │                               │                               │
  │── call:invite ───────────────▶│── call:invite ───────────────▶│
  │                               │                               │ (show incoming call UI)
  │◀──────────────── call:accept ─│◀──────────── call:accept ─────│
  │ (create RTCPeerConnection)    │                               │ (create RTCPeerConnection)
  │── call:offer ────────────────▶│── call:offer ────────────────▶│
  │                               │                               │ (setRemoteDescription)
  │◀───────────────── call:answer─│◀──────────── call:answer ─────│ (createAnswer)
  │ (setRemoteDescription)        │                               │
  │── call:ice-candidate ────────▶│── call:ice-candidate ────────▶│
  │◀────────────── call:ice-cand ─│◀─────────── call:ice-cand ────│
  │                               │                               │
  │        ◀══ P2P Audio/Video ══▶│                               │
  │                               │                               │
  │── call:hangup ───────────────▶│── call:hangup ───────────────▶│
```

### Token Refresh Strategy

```
1. HTTP request returns 401
2. Call POST /auth/refresh with stored refreshToken
3. If 200: store new accessToken + refreshToken, retry original request
4. If 401 from refresh: clear secure storage, navigate to login screen
```

### Reconnection Strategy

When the socket disconnects (network change, app background):
1. `socket_io_client` auto-reconnects by default
2. On `connect_error` with auth error: refresh the access token, then reconnect with the new token
3. After reconnect: re-query `presence:get` for active conversations
4. Scroll to the latest message in each open conversation (messages are persisted — no loss)

### Socket.IO Rate Limits

| Event type | Server-side limit |
|------------|------------------|
| All events | 30 events per 5 seconds per socket |

Throttle typing events client-side (emit `typing:start` at most once every 1–2 seconds, debounce `typing:stop` by 2–3 seconds after the last keystroke).
