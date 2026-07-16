# DuoChat — App Store Publishing Guide

## Shared prerequisites
- Finished app icon set + splash assets matching the DuoChat brand (violet→cyan
  gradient chat bubble + lightning mark, dark background) at all required sizes.
- A live, public **Privacy Policy** URL and **Terms of Service** URL — both
  stores require these given DuoChat requests phone number, contacts, camera,
  microphone, and media access.
- A support URL/email.
- Marketing screenshots for each required device size (see per-store sections).

---
## Android (Google Play)

### 1. App signing
```bash
keytool -genkey -v -keystore duochat-release.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias duochat
```
Store the keystore + passwords securely (a CI secrets manager, not source
control). Configure `android/key.properties` and reference it from
`android/app/build.gradle`.

### 2. Build the release bundle
```bash
flutter build appbundle --release
# output: build/app/outputs/bundle/release/app-release.aab
```

### 3. Google Play Console setup
1. Create the app → fill **Store listing**: name "DuoChat", short & full
   description (use the tagline "Connect Instantly, Chat Seamlessly"),
   category "Communication".
2. Upload icon (512×512), feature graphic (1024×500), phone screenshots
   (min 2, 16:9 or 9:16), and optionally a promo video.
3. **App content** questionnaire: declare Data Safety (phone number, contacts,
   photos/videos, audio, messages — collected & used for app functionality,
   not sold; encrypted in transit). Complete Content rating questionnaire,
   Target audience (13+ recommended given messaging/user-generated content),
   Ads declaration (none), Government apps (no).
4. **Permissions declared in `AndroidManifest.xml`** must match what's
   actually used: `READ_CONTACTS` (contact sync), `CAMERA`, `RECORD_AUDIO`,
   `READ_MEDIA_IMAGES/VIDEO`, `POST_NOTIFICATIONS`, `INTERNET`.
   If requesting a **sensitive permission like READ_CONTACTS**, Play Console
   will require the "Permissions Declaration Form" explaining why (contact
   matching for "find friends on DuoChat").
5. Set up **App Signing by Google Play** (recommended) during first upload.
6. Create a release on the **Internal testing** track first, invite testers,
   verify OTP login + push notifications + calling work with production
   Firebase config, then promote to **Closed → Open → Production**.
7. Set pricing (Free) and country availability.

### 4. Play Store review notes
- Apps offering OTP-based login should NOT read/auto-verify generic SMS
  content — only use the Firebase Auto-Retrieval API or the SMS Retriever
  API scoped to Firebase's own verification message, or reviewers may flag
  broad `READ_SMS` usage.
- Typical review time: a few hours to a few days for updates; longer for
  first submission.

---
## iOS (Apple App Store)

### 1. Certificates & provisioning
In Apple Developer portal: create an **App ID** (`com.yourcompany.duochat`)
with capabilities enabled: Push Notifications, Background Modes (Voice over
IP for calling, Remote notifications), Associated Domains (if using
universal links for invite/QR login).
Create a **Distribution certificate** and an **App Store provisioning
profile**. Xcode "Automatically manage signing" handles most of this if your
Apple Developer account is linked.

### 2. Build the release IPA
```bash
flutter build ipa --release
# output: build/ios/ipa/duochat.ipa
```
Or archive via Xcode: `flutter build ios --release` then Xcode → Product →
Archive → Distribute App → App Store Connect.

### 3. App Store Connect setup
1. Create the app record: name "DuoChat", primary category
   "Social Networking" or "Utilities", bundle ID matching your App ID.
2. **App Privacy** section (Apple's "nutrition label"): declare data types
   collected — Phone Number, Contacts, Photos/Videos, Audio Data, User
   Content (messages), Identifiers (device ID for push) — and whether each
   is linked to identity and used for tracking (DuoChat: not used for
   tracking/advertising).
3. Upload screenshots for required device sizes (6.7", 6.5", 5.5" iPhone at
   minimum; iPad if universal) and app preview video (optional).
4. Write the App Store description, keywords, promotional text, support URL,
   marketing URL, and the required Privacy Policy URL.
5. **Age rating** questionnaire: since DuoChat has user-generated content and
   unrestricted messaging, expect a 12+ or 17+ rating depending on your
   moderation answers.
6. Add **App Review Information**: a demo account (a pre-verified test phone
   number bypassing real SMS, configured in Firebase Auth's test phone
   numbers) so Apple reviewers can log in without receiving a real SMS.
7. Submit for review from the **Version** page after uploading the build via
   Xcode/Transporter/`flutter build ipa` + `xcrun altool`.

### 4. Common iOS rejection reasons to pre-empt
- Missing/incomplete demo account or OTP flow reviewers can't get through
  → **always provide a Firebase test phone number + fixed OTP** in review notes.
- Camera/Microphone/Contacts usage descriptions missing from `Info.plist`
  (`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`,
  `NSContactsUsageDescription`, `NSPhotoLibraryUsageDescription`) — DuoChat
  needs all four given its feature set.
- VoIP/CallKit: if you want native iOS call UI for incoming DuoChat calls,
  integrate `flutter_callkit_incoming` + register for the VoIP push
  background mode; otherwise incoming calls only show as in-app UI while
  foregrounded, which reviewers may flag as a broken calling experience.
- Sign in with Apple: if you offer any third-party login, Apple requires
  Sign in with Apple as an equivalent option. DuoChat's phone-OTP-only login
  is generally exempt (no third-party social login is used), but re-check
  current App Review Guidelines §4.8 at submission time.

---
## Post-launch
- Monitor crash-free rate (Firebase Crashlytics recommended) and OTP
  delivery success rate (Firebase Auth console).
- Stage rollouts: Play Console supports staged rollout percentages; App
  Store Connect supports phased release over 7 days — use both for major
  updates.
- Keep the Data Safety / App Privacy declarations in sync any time you add
  a new SDK or data collection point (e.g. adding analytics later).
