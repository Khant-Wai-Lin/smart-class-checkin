import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../services/attendance_repository.dart';
import '../services/location_service.dart';
import '../services/qr_payload.dart';
import '../services/user_id_service.dart';
import '../widgets/class_flow_bottom_nav.dart';
import 'qr_scanner_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();

  final _prevTopicController = TextEditingController();
  final _expectedTopicController = TextEditingController();

  final _locationService = LocationService();
  final _repo = AttendanceRepository();
  final _userIdService = UserIdService();

  bool _busy = false;

  DateTime? _checkInAt;
  Position? _position;
  QrPayload? _qr;

  int? _moodBefore;

  void _resetAfterSuccess() {
    _formKey.currentState?.reset();
    _prevTopicController.clear();
    _expectedTopicController.clear();

    setState(() {
      _checkInAt = null;
      _position = null;
      _qr = null;
      _moodBefore = null;
    });
  }

  @override
  void dispose() {
    _prevTopicController.dispose();
    _expectedTopicController.dispose();
    super.dispose();
  }

  Future<void> _startCheckIn() async {
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
      payload.validateRequired(expectedPhase: 'checkin');

      setState(() {
        _checkInAt = now;
        _position = position;
        _qr = payload;
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Captured GPS + QR. Fill the form to submit.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Check-in step failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);

    if (_qr == null || _position == null || _checkInAt == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Press Scan the QR first (GPS + QR required).')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_moodBefore == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Select your mood before class.')),
      );
      return;
    }

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

      await _repo.saveCheckIn(
        sessionId: _qr!.sessionId,
        uid: uid,
        userEmail: _tryGetUserEmail(),
        checkInAt: _checkInAt!,
        lat: _position!.latitude,
        lng: _position!.longitude,
        distanceMeters: distance,
        qrPayload: _qr!.raw,
        phase: _qr!.phase,
        nonce: _qr!.nonce,
        expiresAt: _qr!.expiresAt,
        prevTopic: _prevTopicController.text.trim(),
        expectedTopic: _expectedTopicController.text.trim(),
        moodBefore: _moodBefore!,
      );

      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Successfully submitted check-in.'),
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
      appBar: AppBar(title: const Text('Check-in (Before Class)')),
      bottomNavigationBar: const ClassFlowBottomNav(currentIndex: 1),
      body: AbsorbPointer(
        absorbing: _busy,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: _startCheckIn,
                child: Text(_busy ? 'Working…' : 'Scan the QR'),
              ),
              const SizedBox(height: 12),
              Text('Timestamp: ${_checkInAt ?? '-'}'),
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
                      controller: _prevTopicController,
                      decoration: const InputDecoration(
                        labelText: 'What topic was covered in the previous class?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _expectedTopicController,
                      decoration: const InputDecoration(
                        labelText: 'What topic do you expect to learn today?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _moodBefore,
                      decoration: const InputDecoration(
                        labelText: 'Mood before class (1–5)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 — 😡 Very negative')),
                        DropdownMenuItem(value: 2, child: Text('2 — 🙁 Negative')),
                        DropdownMenuItem(value: 3, child: Text('3 — 😐 Neutral')),
                        DropdownMenuItem(value: 4, child: Text('4 — 🙂 Positive')),
                        DropdownMenuItem(value: 5, child: Text('5 — 😄 Very positive')),
                      ],
                      onChanged: (v) => setState(() => _moodBefore = v),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Submit Check-in'),
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
