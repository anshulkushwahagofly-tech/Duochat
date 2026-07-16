const admin = require('firebase-admin');

// DuoChat uses Firebase purely for:
//   1. Phone OTP verification (client-side Firebase Auth generates an ID token,
//      backend verifies it with the Admin SDK).
//   2. Firebase Cloud Storage (profile photos, media, voice notes, docs).
//   3. Firebase Cloud Messaging (push notifications).
// The app's own session/authorization token is a first-party JWT issued after
// the Firebase ID token is verified — see auth.controller.js.

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
    }),
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  });
}

const bucket = admin.storage().bucket();

module.exports = { admin, bucket };
