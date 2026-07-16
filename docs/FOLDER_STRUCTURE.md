# DuoChat — Folder Structure

```
duochat/
├── README.md
│
├── backend/                          Node.js + Express + Socket.IO + MongoDB
│   ├── server.js                     HTTP + Socket.IO bootstrap
│   ├── package.json
│   ├── .env.example
│   └── src/
│       ├── app.js                    Express app assembly (middleware + routes)
│       ├── config/
│       │   ├── db.js                 MongoDB connection
│       │   └── firebase.js           Firebase Admin SDK init (auth verify, storage)
│       ├── models/
│       │   ├── User.js
│       │   ├── Chat.js               1:1 + group container
│       │   ├── Message.js
│       │   ├── Status.js             Stories
│       │   └── Contact.js            Synced phonebook matches
│       ├── middleware/
│       │   └── auth.js               JWT protect() middleware
│       ├── routes/
│       │   ├── auth.routes.js        OTP verify, QR login, logout
│       │   ├── user.routes.js        profile, search, contacts sync, block
│       │   ├── chat.routes.js        1:1 + group CRUD, mute/archive/pin, search
│       │   ├── message.routes.js     send/react/edit/delete/read-all
│       │   ├── status.routes.js      stories feed/post/view
│       │   └── upload.routes.js      Firebase Storage upload proxy
│       └── sockets/
│           └── index.js              presence, typing, messaging, call signaling
│
├── admin-panel/                      Express + EJS admin dashboard
│   ├── server.js
│   ├── package.json
│   ├── .env.example
│   ├── middleware/requireLogin.js
│   ├── models/index.js               read/moderate models (same collections)
│   ├── routes/
│   │   ├── auth.routes.js            admin login/logout
│   │   └── dashboard.routes.js       stats, users, groups, messages, broadcast
│   ├── views/                        EJS templates (dashboard, users, groups, …)
│   └── public/css/admin.css          premium dark admin theme
│
├── flutter_app/                      Flutter client (iOS + Android)
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── theme/app_theme.dart      DuoColors + dark/light ThemeData
│       ├── services/
│       │   ├── api_service.dart      Dio REST client + JWT storage
│       │   ├── socket_service.dart   Socket.IO client wrapper
│       │   └── theme_provider.dart   dark/light/system toggle
│       └── screens/
│           ├── splash_screen.dart
│           ├── otp_login_screen.dart
│           ├── profile_setup_screen.dart
│           ├── home_screen.dart      Chats / Status / Calls tabs
│           ├── chat_screen.dart      1:1 & group messaging UI
│           ├── group_info_screen.dart
│           ├── calls_screen.dart
│           ├── status_screen.dart
│           ├── settings_screen.dart
│           └── user_profile_screen.dart
│
└── docs/
    ├── DATABASE_SCHEMA.md
    ├── API_DOCUMENTATION.md
    ├── DEPLOYMENT_GUIDE.md
    ├── APP_STORE_PUBLISHING_GUIDE.md
    └── FOLDER_STRUCTURE.md           (this file)
```
