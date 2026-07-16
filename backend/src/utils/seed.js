/**
 * Seeds a couple of demo users + a 1:1 chat + a group chat with sample
 * messages, for local development. NOT for production use.
 * Run with: npm run seed
 */
require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../config/db');
const User = require('../models/User');
const Chat = require('../models/Chat');
const Message = require('../models/Message');

async function seed() {
  await connectDB();

  await Promise.all([User.deleteMany({}), Chat.deleteMany({}), Message.deleteMany({})]);

  const [alice, bob, carol] = await User.create([
    { phoneNumber: '+919876500001', firebaseUid: 'seed-alice', name: 'Alice', about: 'Building DuoChat ⚡' },
    { phoneNumber: '+919876500002', firebaseUid: 'seed-bob', name: 'Bob', about: 'Hey there! I am using DuoChat.' },
    { phoneNumber: '+919876500003', firebaseUid: 'seed-carol', name: 'Carol', about: 'On call, back soon' },
  ]);

  const oneToOne = await Chat.create({ isGroup: false, participants: [alice._id, bob._id] });
  const group = await Chat.create({
    isGroup: true,
    groupName: 'DuoChat Launch Team',
    participants: [alice._id, bob._id, carol._id],
    groupAdmins: [alice._id],
    createdBy: alice._id,
  });

  const m1 = await Message.create({ chat: oneToOne._id, sender: alice._id, type: 'text', text: 'Hey Bob! DuoChat is live 🎉' });
  const m2 = await Message.create({ chat: oneToOne._id, sender: bob._id, type: 'text', text: 'Looks amazing, congrats!' });
  oneToOne.lastMessage = m2._id;
  oneToOne.lastMessageAt = new Date();
  await oneToOne.save();

  const m3 = await Message.create({ chat: group._id, sender: alice._id, type: 'text', text: 'Welcome to the launch group 🚀' });
  group.lastMessage = m3._id;
  group.lastMessageAt = new Date();
  await group.save();

  console.log('✅ Seed complete: 3 users, 1 direct chat, 1 group chat');
  await mongoose.disconnect();
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
