const mongoose = require('mongoose');

// A "Chat" is the container for both 1:1 and group conversations.
// 1:1 chats have exactly 2 participants and isGroup=false.
const chatSchema = new mongoose.Schema(
  {
    isGroup: { type: Boolean, default: false },
    participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }],

    // Group-only fields
    groupName: { type: String, trim: true, maxlength: 50 },
    groupAvatarUrl: { type: String },
    groupDescription: { type: String, maxlength: 200 },
    groupAdmins: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    inviteLink: { type: String }, // e.g. duochat.app/invite/<token>

    lastMessage: { type: mongoose.Schema.Types.ObjectId, ref: 'Message' },
    lastMessageAt: { type: Date, default: Date.now },

    // Per-user mute / archive / pin state, keyed by userId
    mutedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    archivedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    pinnedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

    // Per-user unread counters — map of userId(string) -> count
    unreadCounts: { type: Map, of: Number, default: {} },

    isDisappearing: { type: Boolean, default: false },
    disappearingDuration: { type: Number, default: 0 }, // seconds
  },
  { timestamps: true }
);

chatSchema.index({ participants: 1 });
chatSchema.index({ lastMessageAt: -1 });

module.exports = mongoose.model('Chat', chatSchema);
