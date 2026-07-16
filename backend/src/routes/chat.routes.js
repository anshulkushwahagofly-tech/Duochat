const express = require('express');
const { v4: uuidv4 } = require('uuid');
const Chat = require('../models/Chat');
const Message = require('../models/Message');
const { protect } = require('../middleware/auth');

const router = express.Router();

/** GET /api/chats — list all chats for the logged-in user, sorted by recent activity */
router.get('/', protect, async (req, res) => {
  const chats = await Chat.find({ participants: req.user._id, archivedBy: { $ne: req.user._id } })
    .populate('participants', 'name username avatarUrl isOnline lastSeen showOnlineStatus')
    .populate('lastMessage')
    .sort({ lastMessageAt: -1 });
  res.json({ success: true, chats });
});

/** POST /api/chats/one-to-one  Body: { userId } — get-or-create a 1:1 chat */
router.post('/one-to-one', protect, async (req, res) => {
  const { userId } = req.body;
  let chat = await Chat.findOne({
    isGroup: false,
    participants: { $all: [req.user._id, userId], $size: 2 },
  }).populate('participants', 'name username avatarUrl isOnline lastSeen');

  if (!chat) {
    chat = await Chat.create({ isGroup: false, participants: [req.user._id, userId] });
    chat = await chat.populate('participants', 'name username avatarUrl isOnline lastSeen');
  }
  res.json({ success: true, chat });
});

/** POST /api/chats/group  Body: { groupName, participantIds: [] } */
router.post('/group', protect, async (req, res) => {
  const { groupName, participantIds = [], groupAvatarUrl, groupDescription } = req.body;
  if (!groupName || participantIds.length < 1) {
    return res.status(400).json({ success: false, message: 'groupName and at least 1 other participant required' });
  }
  const chat = await Chat.create({
    isGroup: true,
    groupName,
    groupAvatarUrl,
    groupDescription,
    participants: [req.user._id, ...participantIds],
    groupAdmins: [req.user._id],
    createdBy: req.user._id,
    inviteLink: `duochat.app/invite/${uuidv4()}`,
  });
  res.status(201).json({ success: true, chat });
});

/** PUT /api/chats/:id/group — update group name/avatar/description (admin only) */
router.put('/:id/group', protect, async (req, res) => {
  const chat = await Chat.findById(req.params.id);
  if (!chat || !chat.isGroup) return res.status(404).json({ success: false, message: 'Group not found' });
  if (!chat.groupAdmins.some((a) => a.equals(req.user._id))) {
    return res.status(403).json({ success: false, message: 'Only admins can edit group info' });
  }
  ['groupName', 'groupAvatarUrl', 'groupDescription'].forEach((f) => {
    if (req.body[f] !== undefined) chat[f] = req.body[f];
  });
  await chat.save();
  res.json({ success: true, chat });
});

/** POST /api/chats/:id/participants  Body: { userIds: [] } — add members (admin only) */
router.post('/:id/participants', protect, async (req, res) => {
  const chat = await Chat.findById(req.params.id);
  if (!chat || !chat.isGroup) return res.status(404).json({ success: false, message: 'Group not found' });
  if (!chat.groupAdmins.some((a) => a.equals(req.user._id))) {
    return res.status(403).json({ success: false, message: 'Only admins can add members' });
  }
  const { userIds = [] } = req.body;
  userIds.forEach((id) => {
    if (!chat.participants.some((p) => p.equals(id))) chat.participants.push(id);
  });
  await chat.save();
  res.json({ success: true, chat });
});

/** DELETE /api/chats/:id/participants/:userId — remove member / leave group */
router.delete('/:id/participants/:userId', protect, async (req, res) => {
  const chat = await Chat.findById(req.params.id);
  if (!chat || !chat.isGroup) return res.status(404).json({ success: false, message: 'Group not found' });
  const isSelf = req.params.userId === req.user._id.toString();
  const isAdmin = chat.groupAdmins.some((a) => a.equals(req.user._id));
  if (!isSelf && !isAdmin) return res.status(403).json({ success: false, message: 'Not authorized' });

  chat.participants = chat.participants.filter((p) => p.toString() !== req.params.userId);
  chat.groupAdmins = chat.groupAdmins.filter((a) => a.toString() !== req.params.userId);
  await chat.save();
  res.json({ success: true, chat });
});

/** POST /api/chats/:id/mute | /archive | /pin — toggle per-user chat state */
['mute', 'archive', 'pin'].forEach((action) => {
  const field = `${action}dBy`.replace('mutedBy', 'mutedBy'); // mutedBy / archivedBy / pinnedBy
  const map = { mute: 'mutedBy', archive: 'archivedBy', pin: 'pinnedBy' };
  router.post(`/:id/${action}`, protect, async (req, res) => {
    const chat = await Chat.findById(req.params.id);
    if (!chat) return res.status(404).json({ success: false, message: 'Chat not found' });
    const key = map[action];
    const already = chat[key].some((u) => u.equals(req.user._id));
    chat[key] = already ? chat[key].filter((u) => !u.equals(req.user._id)) : [...chat[key], req.user._id];
    await chat.save();
    res.json({ success: true, [key]: !already });
  });
});

/** GET /api/chats/search?q=... — search across chat names & message text */
router.get('/search', protect, async (req, res) => {
  const q = (req.query.q || '').trim();
  const chats = await Chat.find({ participants: req.user._id }).populate('participants', 'name username avatarUrl');
  const matchingChats = chats.filter((c) => {
    const label = c.isGroup ? c.groupName : c.participants.find((p) => !p._id.equals(req.user._id))?.name;
    return label && label.toLowerCase().includes(q.toLowerCase());
  });
  const matchingMessages = await Message.find({
    chat: { $in: chats.map((c) => c._id) },
    $text: { $search: q },
  }).limit(50);
  res.json({ success: true, chats: matchingChats, messages: matchingMessages });
});

module.exports = router;
