const mongoose = require('mongoose');

// Lightweight, admin-facing schemas pointed at the SAME collections as the
// main backend (backend/src/models). Kept in sync manually since this is a
// separate deployable service — for a single source of truth, consider
// extracting shared models into an npm workspace package.

const User = mongoose.models.User || mongoose.model(
  'User',
  new mongoose.Schema(
    {
      phoneNumber: String,
      name: String,
      username: String,
      avatarUrl: String,
      about: String,
      isOnline: Boolean,
      lastSeen: Date,
      isActive: { type: Boolean, default: true },
      isBanned: { type: Boolean, default: false },
      devices: Array,
    },
    { timestamps: true, strict: false }
  )
);

const Chat = mongoose.models.Chat || mongoose.model(
  'Chat',
  new mongoose.Schema(
    {
      isGroup: Boolean,
      groupName: String,
      participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
      lastMessageAt: Date,
    },
    { timestamps: true, strict: false }
  )
);

const Message = mongoose.models.Message || mongoose.model(
  'Message',
  new mongoose.Schema(
    {
      chat: { type: mongoose.Schema.Types.ObjectId, ref: 'Chat' },
      sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
      type: String,
      text: String,
      isDeleted: Boolean,
    },
    { timestamps: true, strict: false }
  )
);

const Status = mongoose.models.Status || mongoose.model(
  'Status',
  new mongoose.Schema({ user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' } }, { timestamps: true, strict: false })
);

module.exports = { User, Chat, Message, Status };
