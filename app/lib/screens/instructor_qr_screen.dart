import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InstructorQrScreen extends StatefulWidget {
  const InstructorQrScreen({super.key});

  @override
  State<InstructorQrScreen> createState() => _InstructorQrScreenState();
}

class _InstructorQrScreenState extends State<InstructorQrScreen> {
  final _sessionIdController = TextEditingController(text: 'S123');

  String _phase = 'checkin';
  int _expiresInMinutes = 10;

  String? _payload;
  DateTime? _expiresAt;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _sessionIdController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_expiresAt == null) return;
      if (DateTime.now().toUtc().isAfter(_expiresAt!.toUtc())) {
        setState(() {});
        return;
      }
      setState(() {});
    });
  }

  void _generate() {
    final sessionId = _sessionIdController.text.trim();
    if (sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session ID is required.')),
      );
      return;
    }

    final now = DateTime.now().toUtc();
    final expiresAt = now.add(Duration(minutes: _expiresInMinutes));
    final nonce = _randomNonce();

    final payloadMap = {
      'sessionId': sessionId,
      'phase': _phase,
      'nonce': nonce,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    };

    final payload = jsonEncode(payloadMap);

    setState(() {
      _payload = payload;
      _expiresAt = expiresAt;
    });

    _startTimer();
  }

  String _randomNonce() {
    // Simple nonce for MVP: time + random component.
    final millis = DateTime.now().millisecondsSinceEpoch;
    final rand = (millis * 2654435761) & 0x7fffffff;
    return '${millis}_$rand';
  }

  String _countdownText() {
    final expiresAt = _expiresAt;
    if (expiresAt == null) return '-';

    final now = DateTime.now().toUtc();
    final diff = expiresAt.difference(now);
    if (diff.isNegative) return 'Expired';

    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Instructor QR (Test)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Generate a QR for students to scan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _sessionIdController,
                          decoration: const InputDecoration(
                            labelText: 'Session ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.class_),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _phase,
                                decoration: const InputDecoration(
                                  labelText: 'Phase',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'checkin', child: Text('checkin')),
                                  DropdownMenuItem(value: 'finish', child: Text('finish')),
                                ],
                                onChanged: (v) => setState(() => _phase = v ?? 'checkin'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _expiresInMinutes,
                                decoration: const InputDecoration(
                                  labelText: 'Expires in',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 2, child: Text('2 minutes')),
                                  DropdownMenuItem(value: 5, child: Text('5 minutes')),
                                  DropdownMenuItem(value: 10, child: Text('10 minutes')),
                                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                                ],
                                onChanged: (v) => setState(() => _expiresInMinutes = v ?? 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _generate,
                          icon: const Icon(Icons.qr_code_2),
                          label: const Text('Generate QR'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Countdown: ${_countdownText()}',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_payload != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'QR Code',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: scheme.outlineVariant),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: QrImageView(
                                  data: _payload!,
                                  size: 260,
                                  eyeStyle: QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: scheme.primary,
                                  ),
                                  dataModuleStyle: QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Payload (students scan this):',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _payload!,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
