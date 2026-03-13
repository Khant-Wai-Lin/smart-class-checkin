import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../services/attendance_repository.dart';
import '../services/location_service.dart';
import '../services/qr_payload.dart';
import '../services/user_id_service.dart';
import '../widgets/class_flow_bottom_nav.dart';
import 'qr_scanner_screen.dart';

class FinishClassScreen extends StatefulWidget {
  const FinishClassScreen({super.key});

  @override
  State<FinishClassScreen> createState() => _FinishClassScreenState();
}

class _FinishClassScreenState extends State<FinishClassScreen> {
  final _formKey = GlobalKey<FormState>();

  final _learnedTodayController = TextEditingController();
  final _feedbackController = TextEditingController();

  final _locationService = LocationService();
  final _repo = AttendanceRepository();
  final _userIdService = UserIdService();

  bool _busy = false;

  DateTime? _finishAt;
  Position? _position;
  QrPayload? _qr;

  void _resetAfterSuccess() {
    _formKey.currentState?.reset();
    _learnedTodayController.clear();
    _feedbackController.clear();

    setState(() {
      _finishAt = null;
      _position = null;
      _qr = null;
    });
  }

  @override
  void dispose() {
    _learnedTodayController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _startFinish() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final position = await _locationService.getCurrentPosition();

      final raw = await navigator.push<String>(QrScannerScreen.route());
      if (!mounted) return;
      if (raw == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('QR scan cancelled.')),
        );
        return;
      }

      final payload = QrPayload.parse(raw);
      payload.validateRequired(expectedPhase: 'finish');

      setState(() {
        _finishAt = now;
        _position = position;
        _qr = payload;
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Captured GPS + QR. Fill the form to submit.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Finish step failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_qr == null || _position == null || _finishAt == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Press Scan the QR first (GPS + QR required).')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      final uid = await _userIdService.getUserId();

      final room = await _repo.tryGetSessionRoom(_qr!.sessionId);
      final distance = (room.roomLat != null && room.roomLng != null)
          ? _locationService.distanceMeters(
              fromLat: _position!.latitude,
              fromLng: _position!.longitude,
              toLat: room.roomLat!,
              toLng: room.roomLng!,
            )
          : null;

      await _repo.saveFinish(
        sessionId: _qr!.sessionId,
        uid: uid,
        userEmail: _tryGetUserEmail(),
        finishAt: _finishAt!,
        lat: _position!.latitude,
        lng: _position!.longitude,
        distanceMeters: distance,
        qrPayload: _qr!.raw,
        phase: _qr!.phase,
        nonce: _qr!.nonce,
        expiresAt: _qr!.expiresAt,
        learnedToday: _learnedTodayController.text.trim(),
        feedback: _feedbackController.text.trim(),
      );

      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Successfully submitted finish reflection.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _resetAfterSuccess();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Save failed (Firebase?): $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _tryGetUserEmail() {
    try {
      return FirebaseAuth.instance.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrSession = _qr?.sessionId;

    return Scaffold(
      appBar: AppBar(title: const Text('Finish Class (After Class)')),
      bottomNavigationBar: const ClassFlowBottomNav(currentIndex: 2),
      body: AbsorbPointer(
        absorbing: _busy,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: _startFinish,
                child: Text(_busy ? 'Working…' : 'Scan the QR'),
              ),
              const SizedBox(height: 12),
              Text('Timestamp: ${_finishAt ?? '-'}'),
              Text(
                'GPS: ${_position == null ? '-' : '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}'}',
              ),
              Text('Session (QR): ${qrSession ?? '-'}'),
              const Divider(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _learnedTodayController,
                      decoration: const InputDecoration(
                        labelText: 'What did you learn today?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _feedbackController,
                      decoration: const InputDecoration(
                        labelText: 'Feedback about the class or instructor',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Submit Finish'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
