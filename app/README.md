# Smart Class Check-in (Flutter MVP)

Flutter + Firebase prototype for:
- **Before class:** Check-in with GPS + QR + short reflection
- **After class:** Finish class with GPS + QR + short reflection

## Run (Chrome)
From the `app/` folder:
- `flutter pub get`
- `flutter run -d chrome --web-port=5055`

## Firebase setup
See: [../FIREBASE_SETUP.md](../FIREBASE_SETUP.md)

This app uses:
- Firebase Auth (Email/Password)
- Cloud Firestore

## QR Workflow (Teacher → Student)

### Why QR?
QR proves the student is in the room (they can see the instructor’s QR) and ties attendance to a **specific class session**.

### QR Payload Format (recommended)
The QR must contain JSON with these fields:

```json
{
	"sessionId": "S123",
	"phase": "checkin",
	"nonce": "RANDOM",
	"expiresAt": 1710336000000
}
```

Field meanings:
- `sessionId` (string): unique id for today’s class session
- `phase` (string): must be either `checkin` or `finish`
- `nonce` (string): random value to prevent re-using an old screenshot
- `expiresAt` (number): expiry time (UNIX epoch **milliseconds**, UTC). Seconds also work, but milliseconds are recommended.

### Teacher process (simple)
1. Decide a `sessionId` for today (example: `CS101_2026-03-13_0900`).
2. Generate **two QR codes**:
	 - One with `phase: "checkin"`
	 - One with `phase: "finish"`
3. Set `expiresAt` to a short time window (example: now + 10 minutes).
4. Display the QR on the projector / screen.

Quick PowerShell snippet to generate payload text:

```powershell
$sessionId = "CS101_2026-03-13_0900"
$nonce = [guid]::NewGuid().ToString('N')
$expiresAt = [DateTimeOffset]::UtcNow.AddMinutes(10).ToUnixTimeMilliseconds()
$payload = @{ sessionId=$sessionId; phase="checkin"; nonce=$nonce; expiresAt=$expiresAt } | ConvertTo-Json -Compress
$payload
```

Paste the printed JSON into any QR generator website to create the QR.

### Teacher process (in-app test screen)
For quick demos/testing, open:
- Home → **Instructor QR (Test)**

It generates the same JSON payload and displays a QR code students can scan.

### Student app behavior
When the student scans the QR:
- The app parses the JSON.
- It **rejects** the QR if:
	- `phase` doesn’t match the current screen (Check-in vs Finish)
	- `expiresAt` is in the past
	- required fields are missing

## Firestore data written
Collection: `attendance`
- One document per student per session, id like: `{sessionId}_{uid}`

Stored fields include:
- Identity: `uid`, `userEmail` (if available)
- Check-in: timestamp, GPS, QR raw payload, `phase/nonce/expiresAt`, pre-class reflection
- Finish: timestamp, GPS, QR raw payload, `phase/nonce/expiresAt`, post-class reflection

Notes:
- `userEmail` is captured from Firebase Auth (Email/Password) at submit time.
- You can always identify the submitter using `uid` by matching it to Firebase Console → Authentication → Users.
