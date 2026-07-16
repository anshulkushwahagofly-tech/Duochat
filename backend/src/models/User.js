const mongoose = require('mongoose');

const deviceSchema = new mongoose.Schema(
  {
    deviceId: { type: String, required: true },
    deviceName: { type: String },
    platform: { type: String, enum: ['android', 'ios', 'web', 'desktop'], default: 'android' },
    fcmToken: { type: String },
    lastActiveAt: { type: Date, default: Date.now },
    loggedInAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const userSchema = new mongoose.Schema(
  {
    phoneNumber: { type: String, required: true, unique: true, index: true }, // E.164 format e.g. +919876543210
    firebaseUid: { type: String, required: true, unique: true },
    name: { type: String, trim: true, maxlength: 50 },
    username: { type: String, unique: true, sparse: true, trim: true, lowercase: true },
    about: { type: String, default: 'Hey there! I am using DuoChat.', maxlength: 150 },
    avatarUrl: { type: String, default: '' },

    isOnline: { type: Boolean, default: false },
    lastSeen: { type: Date, default: Date.now },
    showLastSeen: { type: Boolean, default: true },
    showReadReceipts: { type: Boolean, default: true },
    showOnlineStatus: { type: Boolean, default: true },

    contacts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    blockedUsers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

    devices: [deviceSchema], // multi-device login support
    qrLoginToken: { type: String }, // rotating token used for QR code login

    themePreference: { type: String, enum: ['dark', 'light', 'system'], default: 'dark' },

    isVerified: { type: Boolean, default: true },
    isActive: { type: Boolean, default: true },
    isBanned: { type: Boolean, default: false },

    lastBackupAt: { type: Date },
  },
  { timestamps: true }
);

userSchema.index({ name: 'text', username: 'text', phoneNumber: 'text' });

module.exports = mongoose.model('User', userSchema);
