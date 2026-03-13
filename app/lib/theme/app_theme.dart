import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ).copyWith(
      // Keep both primary + secondary in the blue family.
      secondary: Colors.lightBlue,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: Colors.lightBlueAccent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    );
  }
}
