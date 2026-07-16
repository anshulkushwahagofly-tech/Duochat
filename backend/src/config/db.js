const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    mongoose.set('strictQuery', true);
    const conn = await mongoose.connect(process.env.MONGO_URI, {
      autoIndex: process.env.NODE_ENV !== 'production',
    });
    console.log(`[MongoDB] Connected: ${conn.connection.host}`);
  } catch (err) {
    console.error('[MongoDB] Connection error:', err.message);
    process.exit(1);
  }
};

module.exports = connectDB;
