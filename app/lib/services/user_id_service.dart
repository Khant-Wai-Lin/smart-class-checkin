import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserIdService {
  static const _prefsKey = 'local_user_id';

  Future<String> getUserId() async {
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) return current.uid;
    } catch (_) {
      // Firebase not configured; fall back to local-only user id.
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString(_prefsKey, generated);
    return generated;
  }
}
