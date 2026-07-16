const mongoose = require('mongoose');

const statusSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    type: { type: String, enum: ['image', 'video', 'text'], default: 'image' },
    mediaUrl: { type: String },
    caption: { type: String, maxlength: 200 },
    backgroundColor: { type: String }, // for text-only statuses
    font: { type: String },

    viewers: [
      {
        user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        viewedAt: { type: Date, default: Date.now },
      },
    ],

    visibility: { type: String, enum: ['contacts', 'custom', 'exclude'], default: 'contacts' },
    visibleTo: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    hiddenFrom: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

    expiresAt: { type: Date, required: true, default: () => new Date(Date.now() + 24 * 60 * 60 * 1000) },
  },
  { timestamps: true }
);

statusSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('Status', statusSchema);
