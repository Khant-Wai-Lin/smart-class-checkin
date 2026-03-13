import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  const AuthService();

  FirebaseAuth _authOrThrow() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      throw Exception('Firebase is not configured. See FIREBASE_SETUP.md.');
    }
  }

  Stream<User?> authStateChanges() {
    return _authOrThrow().authStateChanges();
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final auth = _authOrThrow();
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final auth = _authOrThrow();
    await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    final auth = _authOrThrow();
    await auth.signOut();
  }
}
