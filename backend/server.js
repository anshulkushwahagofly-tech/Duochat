require('dotenv').config();
const http = require('http');
const { Server } = require('socket.io');

const app = require('./src/app');
const connectDB = require('./src/config/db');
const initSockets = require('./src/sockets');

const PORT = process.env.PORT || 5000;

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: process.env.CLIENT_URL || '*', methods: ['GET', 'POST'] },
  maxHttpBufferSize: 1e7, // 10MB, for small inline media over socket if ever needed
});

app.set('io', io); // lets REST routes emit socket events too (see message.routes.js)
initSockets(io);

connectDB().then(() => {
  server.listen(PORT, () => {
    console.log(`🚀 DuoChat backend running on port ${PORT} [${process.env.NODE_ENV || 'development'}]`);
  });
});

process.on('unhandledRejection', (err) => {
  console.error('Unhandled promise rejection:', err);
});
