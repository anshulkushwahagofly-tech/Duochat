const mongoose = require('mongoose');

// Synced device contacts, matched against registered DuoChat users.
const contactSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    phoneNumber: { type: String, required: true },
    localName: { type: String }, // name as saved in the owner's phonebook
    matchedUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    isFavorite: { type: Boolean, default: false },
  },
  { timestamps: true }
);

contactSchema.index({ owner: 1, phoneNumber: 1 }, { unique: true });

module.exports = mongoose.model('Contact', contactSchema);
