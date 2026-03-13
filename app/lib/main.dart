import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'screens/check_in_screen.dart';
import 'screens/finish_class_screen.dart';
import 'screens/home_screen.dart';
import 'screens/instructor_qr_screen.dart';
import 'screens/signup_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartClassApp());
}

class SmartClassApp extends StatelessWidget {
  const SmartClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Class Check-in',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routes: {
        '/': (_) => const AuthGate(),
        '/home': (_) => const HomeScreen(),
        '/checkin': (_) => const CheckInScreen(),
        '/finish': (_) => const FinishClassScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/instructor': (_) => const InstructorQrScreen(),
      },
      initialRoute: '/',
    );
  }
}
