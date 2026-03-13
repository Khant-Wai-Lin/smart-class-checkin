# AI Usage Report — Smart Class Check-in

## Summary
This project was built with assistance from GitHub Copilot (model: GPT-5.2) as a programming assistant. The assistant was used to draft requirements documentation, scaffold Flutter UI/screens, implement Firebase/Auth/Firestore integration, and iterate on QR + GPS workflows. A human developer remained responsible for reviewing changes, configuring Firebase in the console, and validating the app end-to-end.

## Where AI Was Used
- **Product/requirements**: Drafted the initial PRD and clarified assumptions (QR payload format, GPS proximity, Firestore schema).
- **Flutter development**: Generated and iterated on Dart/Flutter code for screens, navigation, validation, and styling (Material 3 theme).
- **Firebase integration**: Added Firebase initialization, AuthGate flow, email/password auth screens, and Firestore repository writes.
- **QR + GPS workflow**: Implemented structured QR payload parsing/validation and added an instructor test QR generator.
- **Docs & setup**: Wrote setup guidance and troubleshooting steps for Firebase Web configuration and common errors.

## Outputs Created/Modified With AI Assistance
- **Documentation**: PRD, Firebase setup notes, in-app workflow notes.
- **App code**: UI screens, services/repositories, QR parsing, location helper, and navigation widgets.
- **Config**: Hosting config added for Firebase Hosting deployment.

## Human Review & Validation Recommended
- **Firebase Console**: Ensure Auth providers, authorized domains, and Firestore rules are correct for your course/demo.
- **Security review**: Firestore rules should be tightened for real production usage; avoid relying on client-only QR validation.
- **Testing**: Run `flutter analyze`, then do a live run (web) and confirm documents appear in Firestore.

## Known Limitations
- **Client-side QR validation** can be bypassed by a modified client; for stronger security, validate nonces server-side (Cloud Functions) or restrict writes more tightly.
- **Location checks** depend on device permissions and browser accuracy; GPS can be inaccurate indoors.

## Change Log (High Level)
- Implemented MVP screens (Home, Check-in, Finish).
- Added Email/Password authentication flow.
- Added Firestore persistence for check-in/finish records.
- Added structured QR payload format (sessionId/phase/nonce/expiresAt).
- Added Firebase Hosting configuration for deployment.
