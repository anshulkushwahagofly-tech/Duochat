const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Chat = require('../models/Chat');
const Message = require('../models/Message');

/**
 * DuoChat realtime layer.
 * Every connected socket authenticates with the same JWT issued by
 * POST /api/auth/verify-otp, passed as `socket.handshake.auth.token`.
 *
 * Rooms:
 *   user:<userId>   — every device of a user joins this, used for presence & call invites
 *   chat:<chatId>   — joined chat rooms, used for message fan-out, typing, read receipts
 */
function initSockets(io) {
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (!token) return next(new Error('Authentication token missing'));
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.id);
      if (!user) return next(new Error('User not found'));
      socket.user = user;
      next();
    } catch (err) {
      next(new Error('Authentication failed'));
    }
  });

  io.on('connection', async (socket) => {
    const userId = socket.user._id.toString();
    socket.join(`user:${userId}`);

    // ---- Presence ----
    await User.findByIdAndUpdate(userId, { isOnline: true, lastSeen: new Date() });
    socket.broadcast.emit('presence:update', { userId, isOnline: true });

    // Join every chat room the user belongs to, so message fan-out reaches them
    const chats = await Chat.find({ participants: userId }).select('_id');
    chats.forEach((c) => socket.join(`chat:${c._id}`));

    // ---- Join / leave a specific chat screen (for typing indicator scoping) ----
    socket.on('chat:open', (chatId) => socket.join(`chat:${chatId}`));
    socket.on('chat:close', (chatId) => socket.leave(`chat:${chatId}`));

    // ---- Typing indicator ----
    socket.on('typing:start', ({ chatId }) => {
      socket.to(`chat:${chatId}`).emit('typing:start', { chatId, userId });
    });
    socket.on('typing:stop', ({ chatId }) => {
      socket.to(`chat:${chatId}`).emit('typing:stop', { chatId, userId });
    });

    // ---- Send message (primary real-time path; REST /api/messages is the fallback) ----
    socket.on('message:send', async (payload, ack) => {
      try {
        const { chatId, type = 'text', text, media, replyTo, clientTempId } = payload;
        const chat = await Chat.findById(chatId);
        if (!chat || !chat.participants.some((p) => p.equals(userId))) {
          return ack?.({ success: false, message: 'Not a participant of this chat' });
        }

        const message = await Message.create({ chat: chatId, sender: userId, type, text, media, replyTo, status: 'sent' });
        chat.lastMessage = message._id;
        chat.lastMessageAt = new Date();
        chat.participants.forEach((p) => {
          if (!p.equals(userId)) {
            const key = p.toString();
            chat.unreadCounts.set(key, (chat.unreadCounts.get(key) || 0) + 1);
          }
        });
        await chat.save();

        const populated = await message.populate('sender', 'name username avatarUrl');
        io.to(`chat:${chatId}`).emit('message:new', { ...populated.toObject(), clientTempId });
        ack?.({ success: true, message: populated });
      } catch (err) {
        ack?.({ success: false, message: err.message });
      }
    });

    // ---- Delivery receipt (double grey tick) ----
    socket.on('message:delivered', async ({ messageId }) => {
      const message = await Message.findById(messageId);
      if (!message || message.deliveredTo.some((d) => d.user.equals(userId))) return;
      message.deliveredTo.push({ user: userId });
      message.status = 'delivered';
      await message.save();
      io.to(`chat:${message.chat}`).emit('message:status', { messageId, status: 'delivered', userId });
    });

    // ---- Read receipt (blue tick) ----
    socket.on('message:read', async ({ messageId, chatId }) => {
      const message = await Message.findById(messageId);
      if (message && !message.readBy.some((r) => r.user.equals(userId))) {
        message.readBy.push({ user: userId });
        message.status = 'read';
        await message.save();
      }
      io.to(`chat:${chatId}`).emit('message:status', { messageId, status: 'read', userId });
    });

    // ---- Voice / Video calling signaling (WebRTC handshake relay) ----
    // Actual media flows peer-to-peer via WebRTC once ICE candidates are exchanged.
    socket.on('call:invite', ({ toUserId, chatId, callType, offer }) => {
      io.to(`user:${toUserId}`).emit('call:incoming', { fromUserId: userId, chatId, callType, offer, caller: socket.user.name });
    });
    socket.on('call:answer', ({ toUserId, answer }) => {
      io.to(`user:${toUserId}`).emit('call:answered', { fromUserId: userId, answer });
    });
    socket.on('call:ice-candidate', ({ toUserId, candidate }) => {
      io.to(`user:${toUserId}`).emit('call:ice-candidate', { fromUserId: userId, candidate });
    });
    socket.on('call:decline', ({ toUserId }) => io.to(`user:${toUserId}`).emit('call:declined', { fromUserId: userId }));
    socket.on('call:end', ({ toUserId }) => io.to(`user:${toUserId}`).emit('call:ended', { fromUserId: userId }));

    // ---- Disconnect / presence teardown ----
    socket.on('disconnect', async () => {
      const remainingSockets = await io.in(`user:${userId}`).allSockets();
      if (remainingSockets.size === 0) {
        await User.findByIdAndUpdate(userId, { isOnline: false, lastSeen: new Date() });
        socket.broadcast.emit('presence:update', { userId, isOnline: false, lastSeen: new Date() });
      }
    });
  });
}

module.exports = initSockets;
