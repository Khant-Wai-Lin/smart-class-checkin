import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();

  static Route<String> route() {
    return MaterialPageRoute(builder: (_) => const QrScannerScreen());
  }
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _returned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Class QR')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_returned) return;
          final barcodes = capture.barcodes;
          final value = barcodes.isNotEmpty ? barcodes.first.rawValue : null;
          if (value == null || value.trim().isEmpty) return;
          _returned = true;
          Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
