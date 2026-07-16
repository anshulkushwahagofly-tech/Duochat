# DuoChat — "Connect Instantly, Chat Seamlessly"

Premium real-time messaging app. This repository contains three deployable pieces:

```
duochat/
├── backend/          Node.js + Express + Socket.IO + MongoDB API & realtime server
├── flutter_app/       Flutter client (premium dark theme, glassmorphism)
├── admin-panel/       Express + EJS admin dashboard (users, groups, reports, broadcast)
└── docs/              Database schema, API reference, deployment & app-store guides
```

## Quick start (backend)
```bash
cd backend
cp .env.example .env      # fill in Mongo URI, Firebase creds, JWT secret
npm install
npm run dev                # nodemon on http://localhost:5000
```

## Quick start (admin panel)
```bash
cd admin-panel
cp .env.example .env
npm install
npm start                  # http://localhost:4000
```

## Quick start (Flutter app)
```bash
cd flutter_app
flutter pub get
flutter run
```

See `/docs` for the full database schema, REST + Socket.IO API reference,
production deployment guide, and Play Store / App Store publishing checklist.

## Tech stack
| Layer | Choice |
|---|---|
| Frontend | Flutter (iOS + Android, single codebase) |
| Realtime | Socket.IO over WSS |
| Backend API | Node.js, Express.js |
| Database | MongoDB (Atlas recommended) |
| Auth | Firebase Phone OTP Authentication |
| Media storage | Firebase Storage |
| Push | Firebase Cloud Messaging (FCM) |
| Admin | Express + EJS + Chart.js |

## Note on scope
This is a full architectural implementation covering every screen and feature
requested (auth, 1:1 & group chat, voice/video calling signaling, stories,
read receipts, typing indicators, presence, contact sync, QR login, multi-device,
search, backup). Voice/video calling here is implemented as **WebRTC signaling
over Socket.IO** — the actual media path is peer-to-peer WebRTC, which is the
standard production pattern (this repo does not bundle a TURN server; use
Twilio NTS or coturn in production, see docs/DEPLOYMENT_GUIDE.md).
