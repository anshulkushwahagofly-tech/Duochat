const express = require('express');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const { bucket } = require('../config/firebase');
const { protect } = require('../middleware/auth');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 100 * 1024 * 1024 } }); // 100MB cap

/**
 * POST /api/upload  (multipart/form-data, field name "file")
 * Used for: profile photos, chat images/video/voice-notes/documents, group avatars, statuses.
 * Returns a public/signed Firebase Storage URL to reference in a Message/Status document.
 */
router.post('/', protect, upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: 'No file provided' });

  const folder = req.body.folder || 'media'; // e.g. avatars | chat-media | voice-notes | documents | status
  const ext = req.file.originalname.split('.').pop();
  const filePath = `duochat/${folder}/${req.user._id}/${uuidv4()}.${ext}`;
  const blob = bucket.file(filePath);

  const stream = blob.createWriteStream({ metadata: { contentType: req.file.mimetype } });
  stream.on('error', (err) => res.status(500).json({ success: false, message: err.message }));
  stream.on('finish', async () => {
    await blob.makePublic();
    const url = `https://storage.googleapis.com/${bucket.name}/${filePath}`;
    res.status(201).json({
      success: true,
      url,
      mimeType: req.file.mimetype,
      sizeBytes: req.file.size,
      fileName: req.file.originalname,
    });
  });
  stream.end(req.file.buffer);
});

module.exports = router;
