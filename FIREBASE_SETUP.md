# Firebase + Permissions Setup (MVP)

This repo contains only the MVP Dart code (screens + GPS + QR + Firestore write).
To run on a real device/emulator, install Flutter and then configure Firebase + platform permissions.

## 1) Install Flutter
- Install Flutter SDK and add `flutter` to PATH.
- Verify: `flutter --version`

## 2) Create platform scaffolding (if missing)
If you don’t have `android/`, `ios/`, etc under `app/`, generate them:
- `cd app`
- `flutter create .`

## 3) Add Firebase to Flutter
Option A (recommended): FlutterFire CLI
- Create a Firebase project first (steps below)
- Install FlutterFire CLI:
	- `dart pub global activate flutterfire_cli`
- Run config (inside `app/`):
	- `flutterfire configure`
	- If `flutterfire` is not recognized, run:
		- `dart pub global run flutterfire_cli:flutterfire configure`

Option B: Manual config
- Add `android/app/google-services.json`
- Add `ios/Runner/GoogleService-Info.plist`
- Ensure Android uses the Google Services plugin.

Packages already referenced in [app/pubspec.yaml](app/pubspec.yaml):
- `firebase_core`, `firebase_auth`, `cloud_firestore`

## 3.1) Enable Email/Password Auth
In Firebase Console:
- Authentication → Sign-in method → enable **Email/Password**

The app includes Login + Sign up screens using email/password.

## 3.2) Firebase Console steps (Web / Chrome)
1. Go to https://console.firebase.google.com/
2. **Add project** → name it (e.g., `smart-class-checkin`)
3. Project → Build → **Authentication** → Sign-in method → enable **Email/Password**
4. Project → Build → **Firestore Database** → Create database
	- For lab MVP you can start in **test mode** while developing, then apply rules from [firestore.rules](firestore.rules)
5. Project settings (gear icon) → General → Your apps → **Add app** → choose **Web**
	- Register app
6. Back in your project folder: run FlutterFire config:
	- `cd app`
	- `flutterfire configure`

After step 6 you should get a generated file:
- `app/lib/firebase_options.dart`

Our app uses that file in [app/lib/screens/auth_gate.dart](app/lib/screens/auth_gate.dart) to initialize Firebase on Web.

## Troubleshooting: `CONFIGURATION_NOT_FOUND` on Login/Sign up
If you see an error calling `identitytoolkit.googleapis.com` with message `CONFIGURATION_NOT_FOUND`, it usually means **Firebase Authentication isn't fully enabled for the project** or the **API key is restricted / points to a different project**.

Fix checklist (Firebase Console / Google Cloud Console):
1. Firebase Console → Build → **Authentication**
	- If you see a **Get started** button, click it.
	- Then Authentication → **Sign-in method** → enable **Email/Password**.
2. Firebase Console → Authentication → **Settings** → **Authorized domains**
	- Ensure `localhost` is present (for `flutter run -d chrome`).
	- If you use `127.0.0.1`, add it too.
3. Google Cloud Console (same project) → APIs & Services → **Library**
	- Ensure **Identity Toolkit API** is enabled.
4. Google Cloud Console → APIs & Services → **Credentials** → your API key
	- For development, set Application restrictions to **None**, or allow `http://localhost:*` and `http://127.0.0.1:*`.

## 4) Permissions
### Android
Update `android/app/src/main/AndroidManifest.xml`:
- Camera: `android.permission.CAMERA`
- Location: `android.permission.ACCESS_FINE_LOCATION` (and optionally `ACCESS_COARSE_LOCATION`)

### iOS
Update `ios/Runner/Info.plist`:
- `NSCameraUsageDescription`
- `NSLocationWhenInUseUsageDescription`

## 5) Firestore collections expected
- `sessions/{sessionId}` (optional: contains `roomLat`, `roomLng`)
- `attendance/{sessionId}_{uid}` (created/updated by the app)

QR should encode either:
- Plain: `S123`
- JSON: `{ "sessionId": "S123" }`
