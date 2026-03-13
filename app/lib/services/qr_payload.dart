import 'dart:convert';

class QrPayload {
  final String sessionId;
  final String? phase;
  final String? nonce;
  final DateTime? expiresAt;
  final String raw;

  const QrPayload({
    required this.sessionId,
    required this.raw,
    this.phase,
    this.nonce,
    this.expiresAt,
  });

  static QrPayload parse(String raw) {
    final trimmed = raw.trim();

    // Accept either plain sessionId or JSON with a sessionId field.
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is! Map) {
          throw const FormatException('Invalid QR JSON.');
        }

        final sessionId = decoded['sessionId'];
        if (sessionId is! String || sessionId.trim().isEmpty) {
          throw const FormatException('QR missing sessionId.');
        }

        final phase = decoded['phase'];
        final nonce = decoded['nonce'];
        final expiresAt = _parseExpiresAt(decoded['expiresAt']);

        return QrPayload(
          sessionId: sessionId.trim(),
          phase: phase is String ? phase.trim() : null,
          nonce: nonce is String ? nonce.trim() : null,
          expiresAt: expiresAt,
          raw: raw,
        );
      } catch (_) {
        // Fall through to raw-as-sessionId.
      }
    }

    return QrPayload(sessionId: trimmed, raw: raw);
  }

  static DateTime? _parseExpiresAt(dynamic value) {
    if (value == null) return null;

    // Accept:
    // - number (unix epoch seconds or milliseconds)
    // - ISO-8601 string
    if (value is num) {
      final intValue = value.toInt();
      // Heuristic: seconds are ~1.7B, milliseconds are ~1.7T.
      final isSeconds = intValue < 10000000000;
      final millis = isSeconds ? intValue * 1000 : intValue;
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed;
    }

    return null;
  }

  void validateRequired({required String expectedPhase}) {
    if (phase == null || phase!.isEmpty) {
      throw const FormatException('QR missing phase.');
    }
    if (nonce == null || nonce!.isEmpty) {
      throw const FormatException('QR missing nonce.');
    }
    if (expiresAt == null) {
      throw const FormatException('QR missing expiresAt.');
    }
    if (phase != expectedPhase) {
      throw FormatException('Wrong QR for this step (expected phase: $expectedPhase).');
    }
    final now = DateTime.now().toUtc();
    if (expiresAt!.toUtc().isBefore(now)) {
      throw const FormatException('QR code expired. Ask the instructor for a new one.');
    }
  }
}
