const express = require('express');
const Message = require('../models/Message');
const Chat = require('../models/Chat');
const { protect } = require('../middleware/auth');

const router = express.Router();

/** GET /api/messages/:chatId?before=<messageId>&limit=30 — paginated history */
router.get('/:chatId', protect, async (req, res) => {
  const { before, limit = 30 } = req.query;
  const query = { chat: req.params.chatId, deletedFor: { $ne: req.user._id } };
  if (before) query._id = { $lt: before };

  const messages = await Message.find(query)
    .sort({ _id: -1 })
    .limit(Number(limit))
    .populate('sender', 'name username avatarUrl')
    .populate('replyTo');

  res.json({ success: true, messages: messages.reverse() });
});

/**
 * POST /api/messages — send a message (REST fallback; the primary path is the
 * `message:send` Socket.IO event, which delivers in real time. This endpoint
 * exists for reliability when a client is briefly offline / for bots & webhooks.
 */
router.post('/', protect, async (req, res) => {
  const { chatId, type = 'text', text, media, replyTo } = req.body;
  const chat = await Chat.findById(chatId);
  if (!chat || !chat.participants.some((p) => p.equals(req.user._id))) {
    return res.status(403).json({ success: false, message: 'Not a participant of this chat' });
  }

  const message = await Message.create({ chat: chatId, sender: req.user._id, type, text, media, replyTo });
  chat.lastMessage = message._id;
  chat.lastMessageAt = new Date();
  chat.participants.forEach((p) => {
    if (!p.equals(req.user._id)) {
      const key = p.toString();
      chat.unreadCounts.set(key, (chat.unreadCounts.get(key) || 0) + 1);
    }
  });
  await chat.save();

  const populated = await message.populate('sender', 'name username avatarUrl');
  // req.app.get('io') is set in server.js so REST-sent messages also broadcast live
  req.app.get('io')?.to(`chat:${chatId}`).emit('message:new', populated);

  res.status(201).json({ success: true, message: populated });
});

/** POST /api/messages/:id/react  Body: { emoji } */
router.post('/:id/react', protect, async (req, res) => {
  const { emoji } = req.body;
  const message = await Message.findById(req.params.id);
  if (!message) return res.status(404).json({ success: false, message: 'Message not found' });

  message.reactions = message.reactions.filter((r) => !r.user.equals(req.user._id));
  if (emoji) message.reactions.push({ user: req.user._id, emoji });
  await message.save();

  req.app.get('io')?.to(`chat:${message.chat}`).emit('message:reaction', { messageId: message._id, reactions: message.reactions });
  res.json({ success: true, reactions: message.reactions });
});

/** PUT /api/messages/:id — edit text message (own messages only, within 15 min) */
router.put('/:id', protect, async (req, res) => {
  const message = await Message.findById(req.params.id);
  if (!message || !message.sender.equals(req.user._id)) return res.status(403).json({ success: false, message: 'Not authorized' });
  if (Date.now() - message.createdAt.getTime() > 15 * 60 * 1000) {
    return res.status(400).json({ success: false, message: 'Edit window (15 min) has expired' });
  }
  message.text = req.body.text;
  message.isEdited = true;
  await message.save();
  req.app.get('io')?.to(`chat:${message.chat}`).emit('message:edited', message);
  res.json({ success: true, message });
});

/** DELETE /api/messages/:id?forEveryone=true|false */
router.delete('/:id', protect, async (req, res) => {
  const message = await Message.findById(req.params.id);
  if (!message) return res.status(404).json({ success: false, message: 'Message not found' });

  const forEveryone = req.query.forEveryone === 'true';
  if (forEveryone) {
    if (!message.sender.equals(req.user._id)) return res.status(403).json({ success: false, message: 'Not authorized' });
    message.isDeleted = true;
    message.text = '';
    message.media = undefined;
  } else {
    message.deletedFor.push(req.user._id);
  }
  await message.save();

  if (forEveryone) req.app.get('io')?.to(`chat:${message.chat}`).emit('message:deleted', { messageId: message._id });
  res.json({ success: true });
});

/** POST /api/messages/:chatId/read-all — mark all messages in chat as read (blue tick) */
router.post('/:chatId/read-all', protect, async (req, res) => {
  await Message.updateMany(
    { chat: req.params.chatId, sender: { $ne: req.user._id }, 'readBy.user': { $ne: req.user._id } },
    { $push: { readBy: { user: req.user._id, at: new Date() } }, $set: { status: 'read' } }
  );
  const chat = await Chat.findById(req.params.chatId);
  chat.unreadCounts.set(req.user._id.toString(), 0);
  await chat.save();

  req.app.get('io')?.to(`chat:${req.params.chatId}`).emit('message:read', { chatId: req.params.chatId, userId: req.user._id });
  res.json({ success: true });
});

module.exports = router;
