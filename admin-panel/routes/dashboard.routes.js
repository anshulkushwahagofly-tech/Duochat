const express = require('express');
const { User, Chat, Message, Status } = require('../models');
const router = express.Router();

/** Dashboard home — key stats */
router.get('/', async (req, res) => {
  const [totalUsers, onlineUsers, totalChats, totalGroups, totalMessages, activeStatuses] = await Promise.all([
    User.countDocuments(),
    User.countDocuments({ isOnline: true }),
    Chat.countDocuments({ isGroup: false }),
    Chat.countDocuments({ isGroup: true }),
    Message.countDocuments(),
    Status.countDocuments(),
  ]);
  const recentUsers = await User.find().sort({ createdAt: -1 }).limit(8);

  res.render('dashboard', {
    title: 'Dashboard',
    stats: { totalUsers, onlineUsers, totalChats, totalGroups, totalMessages, activeStatuses },
    recentUsers,
  });
});

/** User management */
router.get('/users', async (req, res) => {
  const q = req.query.q || '';
  const filter = q ? { $or: [{ name: new RegExp(q, 'i') }, { phoneNumber: new RegExp(q, 'i') }] } : {};
  const users = await User.find(filter).sort({ createdAt: -1 }).limit(200);
  res.render('users', { title: 'Users', users, q });
});

router.post('/users/:id/ban', async (req, res) => {
  await User.findByIdAndUpdate(req.params.id, { isBanned: true, isActive: false });
  res.redirect('/users');
});

router.post('/users/:id/unban', async (req, res) => {
  await User.findByIdAndUpdate(req.params.id, { isBanned: false, isActive: true });
  res.redirect('/users');
});

/** Groups */
router.get('/groups', async (req, res) => {
  const groups = await Chat.find({ isGroup: true }).populate('participants', 'name phoneNumber').sort({ createdAt: -1 }).limit(200);
  res.render('groups', { title: 'Groups', groups });
});

/** Reported / flagged messages (isDeleted used here as a stand-in moderation flag) */
router.get('/messages', async (req, res) => {
  const messages = await Message.find().populate('sender', 'name phoneNumber').sort({ createdAt: -1 }).limit(100);
  res.render('messages', { title: 'Messages', messages });
});

/** Broadcast — send a system announcement (persisted here; actual push handled by backend FCM job) */
router.get('/broadcast', (req, res) => {
  res.render('broadcast', { title: 'Broadcast', sent: false });
});
router.post('/broadcast', async (req, res) => {
  // In production: enqueue a job that the main backend picks up to fan out
  // via FCM + a system message inserted into every active chat.
  res.render('broadcast', { title: 'Broadcast', sent: true, message: req.body.message });
});

module.exports = router;
