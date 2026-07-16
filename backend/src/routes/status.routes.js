const express = require('express');
const Status = require('../models/Status');
const Contact = require('../models/Contact');
const { protect } = require('../middleware/auth');

const router = express.Router();

/** POST /api/status — post a new story (expires in 24h automatically via TTL index) */
router.post('/', protect, async (req, res) => {
  const { type, mediaUrl, caption, backgroundColor, font, visibility, visibleTo, hiddenFrom } = req.body;
  const status = await Status.create({
    user: req.user._id,
    type,
    mediaUrl,
    caption,
    backgroundColor,
    font,
    visibility,
    visibleTo,
    hiddenFrom,
  });
  res.status(201).json({ success: true, status });
});

/** GET /api/status/feed — statuses from my contacts, grouped by user */
router.get('/feed', protect, async (req, res) => {
  const contacts = await Contact.find({ owner: req.user._id, matchedUser: { $ne: null } }).select('matchedUser');
  const contactIds = contacts.map((c) => c.matchedUser);

  const statuses = await Status.find({
    user: { $in: [...contactIds, req.user._id] },
    hiddenFrom: { $ne: req.user._id },
  })
    .sort({ createdAt: -1 })
    .populate('user', 'name username avatarUrl');

  const grouped = {};
  statuses.forEach((s) => {
    const key = s.user._id.toString();
    grouped[key] = grouped[key] || { user: s.user, statuses: [] };
    grouped[key].statuses.push(s);
  });

  res.json({ success: true, feed: Object.values(grouped) });
});

/** POST /api/status/:id/view — mark viewed */
router.post('/:id/view', protect, async (req, res) => {
  const status = await Status.findById(req.params.id);
  if (!status) return res.status(404).json({ success: false, message: 'Status not found' });
  if (!status.viewers.some((v) => v.user.equals(req.user._id))) {
    status.viewers.push({ user: req.user._id });
    await status.save();
  }
  res.json({ success: true });
});

/** GET /api/status/:id/viewers — who viewed my status */
router.get('/:id/viewers', protect, async (req, res) => {
  const status = await Status.findById(req.params.id).populate('viewers.user', 'name username avatarUrl');
  if (!status || !status.user.equals(req.user._id)) return res.status(403).json({ success: false, message: 'Not authorized' });
  res.json({ success: true, viewers: status.viewers });
});

/** DELETE /api/status/:id */
router.delete('/:id', protect, async (req, res) => {
  const status = await Status.findById(req.params.id);
  if (!status || !status.user.equals(req.user._id)) return res.status(403).json({ success: false, message: 'Not authorized' });
  await status.deleteOne();
  res.json({ success: true });
});

module.exports = router;
