const express = require('express');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { admin } = require('../config/firebase');
const User = require('../models/User');
const { protect } = require('../middleware/auth');

const router = express.Router();

const signToken = (userId) =>
  jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '30d' });

/**
 * POST /api/auth/verify-otp
 * Body: { idToken, deviceId, deviceName, platform, fcmToken }
 * The Flutter client performs the actual OTP verification with Firebase Auth
 * client SDK, then sends the resulting Firebase ID token here to be verified
 * and exchanged for a DuoChat session (first-party JWT).
 */
router.post('/verify-otp', async (req, res) => {
  try {
    const { idToken, deviceId, deviceName, platform, fcmToken } = req.body;
    if (!idToken || !deviceId) {
      return res.status(400).json({ success: false, message: 'idToken and deviceId are required' });
    }

    const decoded = await admin.auth().verifyIdToken(idToken);
    const phoneNumber = decoded.phone_number;
    const firebaseUid = decoded.uid;

    if (!phoneNumber) {
      return res.status(400).json({ success: false, message: 'Phone number missing from Firebase token' });
    }

    let user = await User.findOne({ firebaseUid });
    let isNewUser = false;

    if (!user) {
      user = await User.create({
        phoneNumber,
        firebaseUid,
        qrLoginToken: uuidv4(),
      });
      isNewUser = true;
    }

    // Register / refresh this device (multi-device support)
    const deviceIdx = user.devices.findIndex((d) => d.deviceId === deviceId);
    const deviceEntry = { deviceId, deviceName, platform, fcmToken, lastActiveAt: new Date(), loggedInAt: new Date() };
    if (deviceIdx >= 0) user.devices[deviceIdx] = { ...user.devices[deviceIdx].toObject(), ...deviceEntry };
    else user.devices.push(deviceEntry);

    user.isOnline = true;
    await user.save();

    const token = signToken(user._id);

    res.json({
      success: true,
      isNewUser,
      token,
      user: {
        id: user._id,
        phoneNumber: user.phoneNumber,
        name: user.name,
        username: user.username,
        avatarUrl: user.avatarUrl,
        about: user.about,
        profileComplete: Boolean(user.name),
      },
    });
  } catch (err) {
    console.error('verify-otp error:', err.message);
    res.status(401).json({ success: false, message: 'Invalid or expired Firebase ID token' });
  }
});

/**
 * POST /api/auth/qr/generate  — desktop/web client asks for a login QR code
 * POST /api/auth/qr/confirm   — mobile app (already logged in) scans it and confirms
 * GET  /api/auth/qr/status/:token — desktop polls (or listens via socket) for confirmation
 */
router.post('/qr/generate', (req, res) => {
  const token = uuidv4();
  res.json({ success: true, qrToken: token, expiresInSec: 60 });
});

router.post('/qr/confirm', protect, async (req, res) => {
  const { qrToken, deviceId, deviceName } = req.body;
  // In production this emits a socket event `qr:confirmed:<qrToken>` to the
  // waiting desktop session, which then issues its own JWT for req.user.id.
  res.json({ success: true, message: 'QR login confirmed', userId: req.user._id, qrToken, deviceId, deviceName });
});

/** POST /api/auth/logout — remove this device */
router.post('/logout', protect, async (req, res) => {
  const { deviceId } = req.body;
  req.user.devices = req.user.devices.filter((d) => d.deviceId !== deviceId);
  if (req.user.devices.length === 0) req.user.isOnline = false;
  await req.user.save();
  res.json({ success: true });
});

module.exports = router;
