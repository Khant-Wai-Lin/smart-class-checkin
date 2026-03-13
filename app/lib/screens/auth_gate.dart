import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase_options.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<void> _initFuture;
  final _authService = const AuthService();

  @override
  void initState() {
    super.initState();
    _initFuture = _initFirebase();
  }

  Future<void> _initFirebase() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey.contains('REPLACE_ME') || options.projectId.contains('REPLACE_ME')) {
      throw Exception('Firebase options missing. Run: flutterfire configure');
    }
    await Firebase.initializeApp(options: options);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Smart Class Check-in')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Firebase is not configured for this app.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'To use Email/Password login and save attendance, complete Firebase setup (see FIREBASE_SETUP.md).',
                  ),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: _authService.authStateChanges(),
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;
            if (user == null) {
              return const LoginScreen();
            }
            return const HomeScreen();
          },
        );
      },
    );
  }
}
