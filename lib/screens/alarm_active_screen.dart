/// Screen 05 — live alarm with photo check-in.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/hype_api.dart';
import 'package:hypemotiv/services/notification_service.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';
import 'package:image_picker/image_picker.dart';

class AlarmActiveScreen extends StatefulWidget {
  const AlarmActiveScreen({super.key});

  @override
  State<AlarmActiveScreen> createState() => _AlarmActiveScreenState();
}

class _AlarmActiveScreenState extends State<AlarmActiveScreen> {
  static const String _quote =
      "Still in bed? Your rivers have already worked out and closed deals. "
      "The Boats?!";

  Timer? _clockTimer;
  DateTime _now = DateTime(2026, 1, 1, 7, 23, 27);
  bool _disarmed = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _now = _now.add(const Duration(seconds: 1)));
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final int hour = _now.hour;
    final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final String hh = hour12.toString().padLeft(2, '0');
    final String mm = _now.minute.toString().padLeft(2, '0');
    final String ss = _now.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss ${hour >= 12 ? 'PM' : 'AM'}';
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CyberTheme.panel,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmProof() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (picked == null || !mounted) {
      _toast('No photo taken · Alarm still ringing');
      return;
    }

    setState(() => _uploading = true);
    final String? url = await HypeApi().uploadFile(
      File(picked.path),
      kind: 'proof',
    );
    if (!mounted) return;
    setState(() {
      _uploading = false;
      _disarmed = true;
    });
    await AudioService().stop();
    _toast(
      url == null
          ? 'Check-in saved · Alarm stopped'
          : 'Check-in uploaded · Alarm stopped',
    );
  }

  /// The snooze button really requires 20 taps, then schedules a 5-minute alarm.
  Future<void> _snoozeWithExercise() async {
    int completed = 0;
    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('20 jumping jacks'),
              content: Text('Tap the button $completed of 20 times to unlock snooze.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (completed < 20) {
                      setState(() => completed++);
                    } else {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: Text(completed < 20 ? '1 rep' : 'Finish'),
                ),
              ],
            );
          },
        );
      },
    );
    if (accepted != true || !mounted) return;

    final DateTime wake = DateTime.now().add(const Duration(minutes: 5));
    await AudioService().stop();
    await NotificationService().scheduleAlarm(
      when: wake,
      title: 'Wake up',
      body: 'Snooze is over. Get up.',
      id: wake.millisecondsSinceEpoch ~/ 1000,
    );
    setState(() => _disarmed = true);
    _toast(
      'Snoozed until ${wake.hour.toString().padLeft(2, '0')}:${wake.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const BrandHeader(
                    status: 'Alarm ringing',
                    trailing: 'Snooze locked',
                    statusColor: Color(0xFFF04438),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      color: Color(0xFF3D5AFE),
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CyberCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(
                          'Playing at high volume',
                          trailing: 'High volume',
                        ),
                        const SizedBox(height: 10),
                        const Waveform(
                          color: Color(0xFF3D5AFE),
                          bars: 42,
                          height: 56,
                        ),
                        const SizedBox(height: 6),
                        const MicroText(
                          'Snooze is locked',
                          color: Color(0xFF667085),
                          fontSize: 12,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CyberCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(
                          'Motivation for today',
                          trailing: 'David Goggins',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "David Goggins: Who's Gonna Carry...",
                          style: TextStyle(
                            color: Color(0xFF1F2933),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          _quote,
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 184,
                    child: CyberCard(
                      padding: EdgeInsets.zero,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: <Color>[
                                  Color(0xFFF9FAFB),
                                  Color(0xFFFFFFFF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SectionLabel(
                                  'Photo check-in',
                                  trailing: 'Required',
                                ),
                                const Spacer(),
                                const MicroText(
                                  'Show your bathroom sink to check in',
                                  color: Color(0xFF1F2933),
                                  fontSize: 13,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: <Widget>[
                                    const Text(
                                      'Ready when you are',
                                      style: TextStyle(
                                        color: Color(0xFF3D5AFE),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    const StatusChip('Ready'),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const LinearProgressIndicator(
                                  value: 0.94,
                                  minHeight: 4,
                                  color: Color(0xFF3D5AFE),
                                  backgroundColor: Color(0xFFE4E7EC),
                                ),
                              ],
                            ),
                          ),
                          const ScanOverlay(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _disarmed
                      ? CyberCard(
                          glow: true,
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF12B76A),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: MicroText(
                                  'Check-in complete · Alarm stopped',
                                  color: Color(0xFF12B76A),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : NeonButton(
                          label: _uploading
                              ? 'Uploading photo...'
                              : 'Take photo & stop alarm',
                          icon: Icons.camera_alt,
                          onPressed: _confirmProof,
                        ),
                  const SizedBox(height: 12),
                  const Text(
                    'Need 5 more minutes? Do 20 jumping jacks first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  NeonButton(
                    label: 'Snooze with 20 jumping jacks',
                    primary: false,
                    icon: Icons.fitness_center,
                    onPressed: _snoozeWithExercise,
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel(
                    'Today\'s priorities',
                    trailing: '2 tasks',
                  ),
                  const SizedBox(height: 10),
                  const _PriorityItem(
                    text: 'Drink a glass of water',
                  ),
                  const SizedBox(height: 8),
                  const _PriorityItem(text: 'Morning workout'),
                ],
              ),
            ),
          ),
          const ScanOverlay(),
        ],
      ),
    );
  }
}

class _PriorityItem extends StatelessWidget {
  const _PriorityItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          const Icon(Icons.radio_button_unchecked,
              color: Color(0xFF0F766E), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1F2933),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
