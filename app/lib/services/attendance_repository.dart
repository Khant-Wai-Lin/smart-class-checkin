import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRepository {
  AttendanceRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore _firestoreOrThrow() {
    try {
      return _firestore ?? FirebaseFirestore.instance;
    } catch (_) {
      throw Exception(
        'Firebase is not configured (no default app). See FIREBASE_SETUP.md.',
      );
    }
  }

  String docIdFor({required String sessionId, required String uid}) {
    return '${sessionId}_$uid';
  }

  Future<({double? roomLat, double? roomLng})> tryGetSessionRoom(String sessionId) async {
    try {
      final snap = await _firestoreOrThrow().collection('sessions').doc(sessionId).get();
      final data = snap.data();
      if (!snap.exists || data == null) return (roomLat: null, roomLng: null);

      final lat = data['roomLat'];
      final lng = data['roomLng'];
      if (lat is num && lng is num) return (roomLat: lat.toDouble(), roomLng: lng.toDouble());

      return (roomLat: null, roomLng: null);
    } catch (_) {
      return (roomLat: null, roomLng: null);
    }
  }

  Future<void> saveCheckIn({
    required String sessionId,
    required String uid,
    String? userEmail,
    required DateTime checkInAt,
    required double lat,
    required double lng,
    required double? distanceMeters,
    required String qrPayload,
    required String? phase,
    required String? nonce,
    required DateTime? expiresAt,
    required String prevTopic,
    required String expectedTopic,
    required int moodBefore,
  }) async {
    final docId = docIdFor(sessionId: sessionId, uid: uid);

    await _firestoreOrThrow().collection('attendance').doc(docId).set({
      'uid': uid,
      'userEmail': userEmail,
      'sessionId': sessionId,
      'checkInAt': Timestamp.fromDate(checkInAt),
      'checkInLat': lat,
      'checkInLng': lng,
      'checkInDistanceMeters': distanceMeters,
      'checkInQrPayload': qrPayload,
      'checkInPhase': phase,
      'checkInNonce': nonce,
      'checkInQrExpiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt),
      'prevTopic': prevTopic,
      'expectedTopic': expectedTopic,
      'moodBefore': moodBefore,
      'status': 'checked_in',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveFinish({
    required String sessionId,
    required String uid,
    String? userEmail,
    required DateTime finishAt,
    required double lat,
    required double lng,
    required double? distanceMeters,
    required String qrPayload,
    required String? phase,
    required String? nonce,
    required DateTime? expiresAt,
    required String learnedToday,
    required String feedback,
  }) async {
    final docId = docIdFor(sessionId: sessionId, uid: uid);

    await _firestoreOrThrow().collection('attendance').doc(docId).set({
      'uid': uid,
      'userEmail': userEmail,
      'sessionId': sessionId,
      'finishAt': Timestamp.fromDate(finishAt),
      'finishLat': lat,
      'finishLng': lng,
      'finishDistanceMeters': distanceMeters,
      'finishQrPayload': qrPayload,
      'finishPhase': phase,
      'finishNonce': nonce,
      'finishQrExpiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt),
      'learnedToday': learnedToday,
      'feedback': feedback,
      'status': 'finished',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
