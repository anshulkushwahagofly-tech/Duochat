# DuoChat — API Documentation

Base URL (production): `https://api.duochat.app/api`
All authenticated endpoints require: `Authorization: Bearer <jwt>`
(JWT is issued by `/auth/verify-otp` and stored client-side after Firebase OTP verification.)

Standard response envelope: `{ "success": true|false, ...data, "message"?: string }`

---
## Auth

### POST `/auth/verify-otp`
Exchange a verified Firebase phone-auth ID token for a DuoChat session JWT.
```json
// Request
{ "idToken": "<firebase-id-token>", "deviceId": "uuid", "deviceName": "Pixel 8", "platform": "android", "fcmToken": "..." }
// Response 200
{ "success": true, "isNewUser": false, "token": "<jwt>", "user": { "id": "...", "phoneNumber": "+91...", "name": "...", "profileComplete": true } }
```

### POST `/auth/qr/generate`
Desktop/web client requests a login QR token. Response: `{ qrToken, expiresInSec }`.

### POST `/auth/qr/confirm` *(auth required)*
Mobile app, already logged in, scans the QR and confirms the login for that session.

### POST `/auth/logout` *(auth required)*
Body: `{ "deviceId": "uuid" }` — removes that device from the account.

---
## Users

| Method | Path | Description |
|---|---|---|
| GET | `/users/me` | current user's full profile |
| PUT | `/users/me` | update name, username, about, avatarUrl, themePreference, privacy toggles |
| GET | `/users/search?q=` | search users by name/username/phone (for "new chat") |
| POST | `/users/contacts/sync` | body `{ contacts: [{phoneNumber, localName}] }` — bulk match device phonebook |
| POST | `/users/:id/block` | block a user |
| POST | `/users/:id/unblock` | unblock a user |
| GET | `/users/:id` | public profile of another user |

---
## Chats

| Method | Path | Description |
|---|---|---|
| GET | `/chats` | list all chats for current user, sorted by recent activity |
| POST | `/chats/one-to-one` | body `{ userId }` — get-or-create a 1:1 chat |
| POST | `/chats/group` | body `{ groupName, participantIds[], groupAvatarUrl?, groupDescription? }` |
| PUT | `/chats/:id/group` | update group name/avatar/description (admin only) |
| POST | `/chats/:id/participants` | body `{ userIds[] }` — add members (admin only) |
| DELETE | `/chats/:id/participants/:userId` | remove member / leave group |
| POST | `/chats/:id/mute` \| `/archive` \| `/pin` | toggle per-user chat state |
| GET | `/chats/search?q=` | search chats by name + message text |

---
## Messages

| Method | Path | Description |
|---|---|---|
| GET | `/messages/:chatId?before=&limit=` | paginated history (cursor = message `_id`) |
| POST | `/messages` | REST fallback for sending (primary path is the socket event below) |
| POST | `/messages/:id/react` | body `{ emoji }` (omit/empty to remove your reaction) |
| PUT | `/messages/:id` | edit text (own message, within 15 min) |
| DELETE | `/messages/:id?forEveryone=true\|false` | delete for me / for everyone |
| POST | `/messages/:chatId/read-all` | mark all unread messages in a chat as read |

---
## Status (Stories)

| Method | Path | Description |
|---|---|---|
| POST | `/status` | create a story; auto-expires after 24h |
| GET | `/status/feed` | contacts' stories, grouped by user |
| POST | `/status/:id/view` | mark viewed |
| GET | `/status/:id/viewers` | list viewers (own status only) |
| DELETE | `/status/:id` | delete own story |

---
## Upload

### POST `/upload` *(multipart/form-data)*
Fields: `file` (binary), `folder` (`avatars` \| `chat-media` \| `voice-notes` \| `documents` \| `status`).
Returns `{ url, mimeType, sizeBytes, fileName }` pointing at Firebase Storage.

---
## Socket.IO Realtime Events

Connect with `io(SOCKET_URL, { auth: { token: jwt } })`.

### Client → Server
| Event | Payload | Purpose |
|---|---|---|
| `chat:open` | chatId | join a chat room while its screen is open |
| `chat:close` | chatId | leave the room |
| `typing:start` / `typing:stop` | `{ chatId }` | typing indicator |
| `message:send` | `{ chatId, type, text?, media?, replyTo?, clientTempId }` (ack) | send a message in real time |
| `message:delivered` | `{ messageId }` | double grey tick |
| `message:read` | `{ messageId, chatId }` | blue tick |
| `call:invite` | `{ toUserId, chatId, callType, offer }` | WebRTC call offer relay |
| `call:answer` | `{ toUserId, answer }` | WebRTC answer relay |
| `call:ice-candidate` | `{ toUserId, candidate }` | ICE candidate relay |
| `call:decline` / `call:end` | `{ toUserId }` | end signaling |

### Server → Client
| Event | Payload | Purpose |
|---|---|---|
| `presence:update` | `{ userId, isOnline, lastSeen? }` | online/offline broadcast |
| `typing:start` / `typing:stop` | `{ chatId, userId }` | |
| `message:new` | full message object | new message delivered |
| `message:status` | `{ messageId, status, userId }` | delivered/read tick updates |
| `message:reaction` | `{ messageId, reactions }` | |
| `message:edited` | full message object | |
| `message:deleted` | `{ messageId }` | |
| `call:incoming` | `{ fromUserId, chatId, callType, offer, caller }` | |
| `call:answered` / `call:ice-candidate` / `call:declined` / `call:ended` | | |

**Note on calling:** signaling only travels through Socket.IO; the actual
audio/video stream is peer-to-peer WebRTC. Production deployments need a
STUN/TURN server (see `docs/DEPLOYMENT_GUIDE.md`) for NAT traversal when
both peers are behind restrictive networks.

---
## Error format
```json
{ "success": false, "message": "Human-readable error" }
```
Common HTTP codes: `400` validation, `401` auth, `403` not authorized/not a participant,
`404` not found, `429` rate-limited, `500` server error.
