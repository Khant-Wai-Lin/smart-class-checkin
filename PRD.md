# Smart Class Check-in & Learning Reflection App — PRD

## Problem Statement
The university needs a simple way to (1) verify students are physically present in class and (2) confirm participation, without creating heavy administrative work for instructors. Current attendance methods (manual roll call, paper sign-in) are slow and easy to spoof.

Success means:
- Attendance is captured quickly and consistently.
- “Presence” is supported by both **GPS proximity** and **in-room QR scanning**.
- “Participation” is supported by **before/after reflections** tied to a specific class session.

## Target User
- **Primary:** University students attending classes.
- **Secondary:** Instructors (generate/display QR; review attendance and reflections).
- **Admin (optional):** Department staff (audit/reporting).

## Feature List (Prototype / MVP)
1. **Student check-in (before class)**
   - Tap **Check-in**
   - Capture **timestamp** and **GPS location**
   - **Scan class QR** (in-room)
   - Fill pre-class reflection:
     - Previous class topic (text)
     - Expected topic today (text)
     - Mood rating (1–5)
2. **Student finish class (after class)**
   - Tap **Finish Class**
   - Scan **QR again**
   - Capture **timestamp** and **GPS location**
   - Fill post-class reflection:
     - What I learned today (short text)
     - Feedback about the class/instructor (text)
3. **Basic authentication (prototype)**
   - Sign-in via Firebase Auth (Email/Password).
4. **Instructor session QR (minimal)**
   - QR encodes a short-lived JSON payload with session and expiry info.
   - Prototype includes an **in-app Instructor QR (Test)** generator screen for demos.

Non-goals (for prototype): advanced analytics, offline mode, multi-language, timetable sync, push notifications.

## User Flow
### A) Check-in (Before Class)
1. Student opens app → signs in
2. Selects today’s class session (or auto-detect “active session”) → taps **Check-in**
3. App requests location permission → reads GPS
4. App opens QR scanner → student scans in-room QR
5. App shows pre-class reflection form → student submits
6. App confirms check-in saved

### B) Finish Class (After Class)
1. Student taps **Finish Class**
2. App reads GPS
3. App opens QR scanner → scans the (same or “end-of-class”) QR
4. App shows post-class reflection form → student submits
5. App confirms completion saved

## Key Rules / Assumptions (Defined Missing Details)
- **QR content (MVP):** JSON payload with required fields:
  - `sessionId` (string)
  - `phase` (string): `checkin` or `finish`
  - `nonce` (string): random value to reduce screenshot reuse
  - `expiresAt` (number): UNIX epoch (milliseconds recommended)
- **GPS validation (prototype):** store coordinates and compute distance to the session’s classroom coordinates.
  - Suggested rule: mark as *valid* if within **100 meters** of classroom location at time of scan.
  - Prototype stores both raw coordinates and computed distance.
- **Two scans required:** one for check-in (`phase=checkin`), one for finish (`phase=finish`), both tied to the same `sessionId`.
- **Reflection required:** submission blocked until required fields are entered.
- **Success behavior (MVP):** after a successful submit, the app shows a success message and clears the form fields.

## Data Fields (Firestore-oriented)
### Collections used in the MVP

### `sessions` (optional)
Used only if you want distance-to-room calculations.
- `roomLat` (number)
- `roomLng` (number)

### `attendance`
One document per student per session, document id: `{sessionId}_{uid}`

Identity:
- `uid` (string)
- `userEmail` (string, nullable)
- `sessionId` (string)

Check-in:
- `checkInAt` (timestamp)
- `checkInLat` (number)
- `checkInLng` (number)
- `checkInDistanceMeters` (number, nullable)
- `checkInQrPayload` (string)
- `checkInPhase` (string)
- `checkInNonce` (string)
- `checkInQrExpiresAt` (timestamp, nullable)
- `prevTopic` (string)
- `expectedTopic` (string)
- `moodBefore` (int 1–5)

Finish:
- `finishAt` (timestamp, nullable until finished)
- `finishLat` (number)
- `finishLng` (number)
- `finishDistanceMeters` (number, nullable)
- `finishQrPayload` (string)
- `finishPhase` (string)
- `finishNonce` (string)
- `finishQrExpiresAt` (timestamp, nullable)
- `learnedToday` (string)
- `feedback` (string)

System:
- `status` ("checked_in" | "finished")
- `updatedAt` (server timestamp)

## Tech Stack
- **Mobile:** Flutter (Dart)
- **Firebase:**
  - Firebase Auth (student identity)
  - Cloud Firestore (sessions + attendance + reflections)
  - (Optional) Cloud Functions (server-side QR nonce validation, anti-spoof checks)
- **Device capabilities:**
  - GPS via `geolocator`
  - QR scanning via `mobile_scanner` (or equivalent)

## Acceptance Criteria (MVP)
- Student can check in only after scanning QR and submitting required pre-class fields.
- Student can finish class only after scanning QR and submitting required post-class fields.
- Each submission stores timestamp + GPS and is linked to a `sessionId`.
- After a successful submit, the app shows a success message and clears the form.
- App clearly shows success/failure states (permissions missing, invalid QR, missing required fields).
