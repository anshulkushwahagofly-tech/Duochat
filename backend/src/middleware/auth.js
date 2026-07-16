const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Verifies DuoChat's own first-party JWT (issued after Firebase OTP verification).
const protect = async (req, res, next) => {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.split(' ')[1] : null;

    if (!token) {
      return res.status(401).json({ success: false, message: 'Not authorized, no token' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id).select('-qrLoginToken');

    if (!user || !user.isActive || user.isBanned) {
      return res.status(401).json({ success: false, message: 'Account not accessible' });
    }

    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Not authorized, token invalid or expired' });
  }
};

module.exports = { protect };
