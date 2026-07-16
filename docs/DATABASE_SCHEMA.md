# DuoChat — Database Schema (MongoDB)

All collections use Mongoose ODM. IDs are MongoDB ObjectIds unless noted.
See `backend/src/models/*.js` for the authoritative Mongoose schemas.

## `users`
| Field | Type | Notes |
|---|---|---|
| phoneNumber | String (unique, E.164) | e.g. `+919876543210` |
| firebaseUid | String (unique) | Firebase Auth UID from phone OTP |
| name | String | |
| username | String (unique, sparse) | optional handle |
| about | String | status/bio line, default "Hey there! I am using DuoChat." |
| avatarUrl | String | Firebase Storage URL |
| isOnline | Boolean | live presence flag |
| lastSeen | Date | |
| showLastSeen / showReadReceipts / showOnlineStatus | Boolean | privacy toggles |
| contacts | [ObjectId → users] | |
| blockedUsers | [ObjectId → users] | |
| devices | [DeviceSubdoc] | multi-device sessions: deviceId, deviceName, platform, fcmToken, lastActiveAt, loggedInAt |
| qrLoginToken | String | rotating token for QR login |
| themePreference | enum('dark','light','system') | |
| isVerified / isActive / isBanned | Boolean | moderation flags |
| lastBackupAt | Date | |
| createdAt / updatedAt | Date | |

Indexes: `phoneNumber` (unique), `firebaseUid` (unique), `username` (unique sparse),
text index on `name`, `username`, `phoneNumber` for search.

## `chats`
Represents both 1:1 conversations and groups.

| Field | Type | Notes |
|---|---|---|
| isGroup | Boolean | |
| participants | [ObjectId → users] | exactly 2 for 1:1 chats |
| groupName / groupAvatarUrl / groupDescription | String | group-only |
| groupAdmins | [ObjectId → users] | group-only |
| createdBy | ObjectId → users | |
| inviteLink | String | group-only |
| lastMessage | ObjectId → messages | |
| lastMessageAt | Date | drives chat-list sort order |
| mutedBy / archivedBy / pinnedBy | [ObjectId → users] | per-user chat state |
| unreadCounts | Map\<userId, Number\> | per-user unread badge count |
| isDisappearing / disappearingDuration | Boolean / Number (sec) | |

Indexes: `participants`, `lastMessageAt` (desc).

## `messages`
| Field | Type | Notes |
|---|---|---|
| chat | ObjectId → chats | |
| sender | ObjectId → users | |
| type | enum: text, image, video, audio, document, voice_note, location, contact, system | |
| text | String | max 4096 chars |
| media | Subdoc | url, thumbnailUrl, mimeType, sizeBytes, durationSec, fileName, width, height |
| replyTo | ObjectId → messages | quoted message |
| forwardedFrom | ObjectId → users | |
| reactions | [{ user, emoji }] | one reaction per user (upsert-replace) |
| deliveredTo / readBy | [{ user, at }] | per-recipient delivery/read tracking (blue tick) |
| status | enum: sending, sent, delivered, read, failed | |
| isEdited | Boolean | |
| isDeleted | Boolean | deleted-for-everyone |
| deletedFor | [ObjectId → users] | deleted-for-me |
| expiresAt | Date | TTL index — disappearing messages |

Indexes: `{ chat: 1, createdAt: -1 }`, text index on `text`, TTL index on `expiresAt`.

## `statuses` (Stories)
| Field | Type | Notes |
|---|---|---|
| user | ObjectId → users | |
| type | enum: image, video, text | |
| mediaUrl / caption / backgroundColor / font | | |
| viewers | [{ user, viewedAt }] | |
| visibility | enum: contacts, custom, exclude | |
| visibleTo / hiddenFrom | [ObjectId → users] | |
| expiresAt | Date, default now+24h | TTL index auto-deletes after 24h |

## `contacts`
Synced device phonebook, matched against registered DuoChat users.

| Field | Type | Notes |
|---|---|---|
| owner | ObjectId → users | |
| phoneNumber | String | as stored on device |
| localName | String | name saved in the owner's phonebook |
| matchedUser | ObjectId → users, nullable | resolved DuoChat account, if any |
| isFavorite | Boolean | |

Indexes: `{ owner: 1, phoneNumber: 1 }` unique.

## Entity relationship summary
```
users ─┬─< chats.participants (many-to-many via array)
       ├─< messages.sender
       ├─< statuses.user
       └─< contacts.owner / contacts.matchedUser

chats ──< messages.chat
      └── chats.lastMessage → messages (1:1)

messages ──< messages.replyTo (self-referencing)
```

## Design notes
- **Why embed reactions/deliveries in `messages` instead of separate collections?**
  Read/delivery/reaction fan-out per message is bounded by chat size (small for
  1:1, capped in groups), so embedding avoids extra round trips for the hottest
  read path (rendering a chat thread).
- **Why TTL indexes for `statuses` and disappearing `messages`?** Native MongoDB
  TTL background deletion is simpler and cheaper than a cron/worker for
  time-boxed content.
- **Multi-device**: `users.devices[]` holds one entry per logged-in device
  (phone, tablet, web/desktop), each with its own FCM token so pushes fan out
  to every device independently.
