const express = require('express');
const User = require('../models/User');
const Contact = require('../models/Contact');
const { protect } = require('../middleware/auth');

const router = express.Router();

/** GET /api/users/me */
router.get('/me', protect, async (req, res) => {
  res.json({ success: true, user: req.user });
});

/** PUT /api/users/me — profile setup / edit (name, username, about, avatarUrl, theme) */
router.put('/me', protect, async (req, res) => {
  const allowed = ['name', 'username', 'about', 'avatarUrl', 'themePreference', 'showLastSeen', 'showReadReceipts', 'showOnlineStatus'];
  allowed.forEach((field) => {
    if (req.body[field] !== undefined) req.user[field] = req.body[field];
  });
  await req.user.save();
  res.json({ success: true, user: req.user });
});

/** GET /api/users/search?q=...  — find users by name/username/phone for "new chat" */
router.get('/search', protect, async (req, res) => {
  const q = (req.query.q || '').trim();
  if (!q) return res.json({ success: true, users: [] });
  const users = await User.find({ $text: { $search: q }, _id: { $ne: req.user._id } })
    .select('name username phoneNumber avatarUrl about isOnline lastSeen')
    .limit(20);
  res.json({ success: true, users });
});

/** POST /api/users/contacts/sync — bulk upload device phonebook, returns matched DuoChat users */
router.post('/contacts/sync', protect, async (req, res) => {
  const { contacts } = req.body; // [{ phoneNumber, localName }]
  if (!Array.isArray(contacts)) return res.status(400).json({ success: false, message: 'contacts array required' });

  const phoneNumbers = contacts.map((c) => c.phoneNumber);
  const matchedUsers = await User.find({ phoneNumber: { $in: phoneNumbers } }).select('phoneNumber name avatarUrl about isOnline lastSeen');
  const matchedMap = new Map(matchedUsers.map((u) => [u.phoneNumber, u]));

  const ops = contacts.map((c) => ({
    updateOne: {
      filter: { owner: req.user._id, phoneNumber: c.phoneNumber },
      update: {
        $set: {
          localName: c.localName,
          matchedUser: matchedMap.get(c.phoneNumber)?._id || null,
        },
      },
      upsert: true,
    },
  }));
  if (ops.length) await Contact.bulkWrite(ops);

  const savedContacts = await Contact.find({ owner: req.user._id, matchedUser: { $ne: null } }).populate(
    'matchedUser',
    'name avatarUrl about isOnline lastSeen phoneNumber'
  );

  res.json({ success: true, contacts: savedContacts });
});

/** POST /api/users/:id/block  &  /unblock */
router.post('/:id/block', protect, async (req, res) => {
  if (!req.user.blockedUsers.includes(req.params.id)) req.user.blockedUsers.push(req.params.id);
  await req.user.save();
  res.json({ success: true });
});
router.post('/:id/unblock', protect, async (req, res) => {
  req.user.blockedUsers = req.user.blockedUsers.filter((id) => id.toString() !== req.params.id);
  await req.user.save();
  res.json({ success: true });
});

/** GET /api/users/:id — public profile view */
router.get('/:id', protect, async (req, res) => {
  const user = await User.findById(req.params.id).select('name username avatarUrl about isOnline lastSeen showLastSeen showOnlineStatus');
  if (!user) return res.status(404).json({ success: false, message: 'User not found' });
  res.json({ success: true, user });
});

module.exports = router;
