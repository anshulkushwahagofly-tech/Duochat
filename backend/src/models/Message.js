const mongoose = require('mongoose');

const reactionSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    emoji: { type: String, required: true }, // 👍 ❤️ 😂 😮 😢 🙏
  },
  { _id: false }
);

const messageSchema = new mongoose.Schema(
  {
    chat: { type: mongoose.Schema.Types.ObjectId, ref: 'Chat', required: true, index: true },
    sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

    type: {
      type: String,
      enum: ['text', 'image', 'video', 'audio', 'document', 'voice_note', 'location', 'contact', 'system'],
      default: 'text',
    },

    text: { type: String, maxlength: 4096 },

    media: {
      url: String,
      thumbnailUrl: String,
      mimeType: String,
      sizeBytes: Number,
      durationSec: Number, // for voice notes / video
      fileName: String,
      width: Number,
      height: Number,
    },

    replyTo: { type: mongoose.Schema.Types.ObjectId, ref: 'Message', default: null },
    forwardedFrom: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

    reactions: [reactionSchema],

    // Delivery / read tracking per recipient (for groups this grows to N entries)
    deliveredTo: [
      {
        user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        at: { type: Date, default: Date.now },
      },
    ],
    readBy: [
      {
        user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        at: { type: Date, default: Date.now },
      },
    ],

    status: {
      type: String,
      enum: ['sending', 'sent', 'delivered', 'read', 'failed'],
      default: 'sent',
    },

    isEdited: { type: Boolean, default: false },
    isDeleted: { type: Boolean, default: false }, // deleted for everyone
    deletedFor: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], // deleted for me

    expiresAt: { type: Date }, // disappearing messages (TTL index below)
  },
  { timestamps: true }
);

messageSchema.index({ chat: 1, createdAt: -1 });
messageSchema.index({ text: 'text' }); // search within chats
messageSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('Message', messageSchema);
