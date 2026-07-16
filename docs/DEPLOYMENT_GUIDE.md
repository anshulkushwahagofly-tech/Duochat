# DuoChat — Deployment Guide

## 1. Prerequisites
- Node.js 18+, npm
- MongoDB Atlas cluster (or self-hosted MongoDB 6+)
- Firebase project with **Phone Authentication**, **Cloud Storage**, and
  **Cloud Messaging** enabled
- Flutter SDK 3.3+ (for building the mobile app)
- A domain + TLS certificate for the API (e.g. `api.duochat.app`)
- (For calling) a STUN/TURN provider — Twilio Network Traversal Service,
  Xirsys, or self-hosted `coturn`

## 2. Firebase setup
1. Create a Firebase project → enable **Authentication → Phone** sign-in.
2. Enable **Cloud Storage** → note the bucket name (`<project>.appspot.com`).
3. Enable **Cloud Messaging** → note the Sender ID / Server key for FCM v1.
4. Project Settings → Service Accounts → **Generate new private key** →
   download the JSON. You'll map its fields into the backend `.env`:
   `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`.
5. Add your app's SHA-1/SHA-256 fingerprints (Android) and bundle ID (iOS) to
   the Firebase project so phone auth reCAPTCHA/Safety Net checks pass.
6. Download `google-services.json` (Android) → `flutter_app/android/app/`.
   Download `GoogleService-Info.plist` (iOS) → `flutter_app/ios/Runner/`.

## 3. Backend deployment (Node.js + Socket.IO + MongoDB)

### Environment variables (`backend/.env`)
See `backend/.env.example` for the full list: `MONGO_URI`, `JWT_SECRET`,
`FIREBASE_*`, `CLIENT_URL`, rate-limit settings.

### Option A — Docker (recommended)
```dockerfile
# backend/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 5000
CMD ["node", "server.js"]
```
```bash
docker build -t duochat-backend ./backend
docker run -d --env-file backend/.env -p 5000:5000 --name duochat-api duochat-backend
```

### Option B — PM2 on a VM (EC2 / DigitalOcean / Lightsail)
```bash
cd backend && npm install
npm install -g pm2
pm2 start server.js --name duochat-api
pm2 save && pm2 startup
```

### Reverse proxy (Nginx) + TLS
```nginx
server {
  listen 443 ssl http2;
  server_name api.duochat.app;
  ssl_certificate     /etc/letsencrypt/live/api.duochat.app/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/api.duochat.app/privkey.pem;

  location / {
    proxy_pass http://127.0.0.1:5000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;   # required for Socket.IO websockets
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```
Get a free cert: `certbot --nginx -d api.duochat.app`.

### Scaling Socket.IO horizontally
If you run more than one backend instance behind a load balancer, add the
Redis adapter so Socket.IO rooms/broadcasts work across processes:
```bash
npm install @socket.io/redis-adapter redis
```
```js
// server.js
const { createAdapter } = require('@socket.io/redis-adapter');
const { createClient } = require('redis');
const pubClient = createClient({ url: process.env.REDIS_URL });
const subClient = pubClient.duplicate();
await Promise.all([pubClient.connect(), subClient.connect()]);
io.adapter(createAdapter(pubClient, subClient));
```
Also ensure your load balancer uses **sticky sessions** (or the Redis adapter
above handles cross-node delivery regardless).

## 4. MongoDB
- Use MongoDB Atlas (M10+ for production) with automated backups enabled.
- Whitelist your backend server's IP (or use VPC peering).
- Run once in production to ensure indexes exist:
  ```bash
  node -e "require('./src/models/User'); require('./src/models/Chat'); require('./src/models/Message'); require('./src/models/Status'); require('./src/models/Contact'); require('./src/config/db')()"
  ```

## 5. Admin panel deployment
Deploy `admin-panel/` the same way as the backend (Docker/PM2), on a
separate port or subdomain (e.g. `admin.duochat.app`), pointed at the same
`MONGO_URI`. Put it behind an IP allowlist or VPN in addition to its login
screen, since it can ban users and broadcast to everyone.

## 6. STUN/TURN for calling
Add ICE servers to the Flutter WebRTC config (`flutter_webrtc`):
```dart
final config = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'turn:your-turn-host:3478', 'username': '...', 'credential': '...'},
  ]
};
```
For production-grade reliability across carrier-grade NAT, use a paid TURN
provider (Twilio NTS, Xirsys) rather than self-hosting unless you have your
own network operations capacity.

## 7. Push notifications (FCM)
The backend stores an `fcmToken` per device (`users.devices[].fcmToken`).
Add a small worker/service using `firebase-admin`'s messaging API to send
notifications on `message:new` for offline recipients (checked via
`isOnline`/absent socket connection), and on `call:invite` for incoming
calls. This is intentionally decoupled from the request path so a slow FCM
call never blocks message delivery.

## 8. CI/CD suggestion
- GitHub Actions: lint + test on PR, build Docker image, push to a registry
  (ECR/GHCR/Docker Hub), deploy via SSH or a managed platform (Render,
  Railway, Fly.io, AWS ECS).
- Flutter: use `flutter build appbundle` / `flutter build ipa` in a
  Codemagic, Bitrise, or GitHub Actions workflow with matching signing
  secrets (see `APP_STORE_PUBLISHING_GUIDE.md`).

## 9. Environment checklist before going live
- [ ] `JWT_SECRET` is a long random value, not the example placeholder
- [ ] Firebase phone auth quota / billing configured (SMS costs money past free tier)
- [ ] MongoDB backups enabled + tested restore
- [ ] Rate limiting tuned for expected traffic
- [ ] TURN server configured and load-tested
- [ ] FCM server key rotated from any example/test key
- [ ] Admin panel behind VPN/IP allowlist, strong `ADMIN_PASSWORD`
- [ ] App Store / Play Store privacy policy URL live (required by both stores
      given phone number + contacts + media collection — see the publishing guide)
