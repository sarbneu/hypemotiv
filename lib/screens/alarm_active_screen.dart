/// Screen 05 — live alarm strike with camera proof mission HUD.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hypemotiv/services/hype_api.dart';
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
        backgroundColor: CyberTheme.panelAlt,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmProof() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (picked == null || !mounted) {
      _toast('PROOF CANCELLED // ALARM STILL LIVE');
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
    _toast(
      url == null
          ? 'PROOF VERIFIED ON DEVICE // ALARM DISARMED'
          : 'PROOF UPLOADED // ALARM DISARMED',
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
                    status: 'ALARM ACTIVE // BLAST LEVEL 120%',
                    trailing: 'SNOOZE LOCKED',
                    statusColor: Color(0xFFFF2E88),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFB6FF3B),
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      shadows: <Shadow>[
                        Shadow(color: Color(0x55B6FF3B), blurRadius: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  CyberCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(
                          'WAR VOLUME AUDIO STRIKE',
                          trailing: '120%',
                        ),
                        const SizedBox(height: 10),
                        const Waveform(
                          color: Color(0xFFFF2E88),
                          bars: 42,
                          height: 56,
                        ),
                        const SizedBox(height: 6),
                        const MicroText(
                          'NO SNOOZE // DISCIPLINE OVERRIDE ENGAGED',
                          color: Color(0xFF7C8C82),
                          fontSize: 9,
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
                          'AI ROAST DISPATCH',
                          trailing: 'GOGGINS',
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "David Goggins: Who's Gonna Carry...",
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFFF4F8F3),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          _quote,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF00E5FF),
                            fontSize: 12,
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
                              gradient: LinearGradient(
                                colors: <Color>[
                                  CyberTheme.panelAlt,
                                  CyberTheme.bg,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SectionLabel(
                                  'MISSION HUD SCANNER',
                                  trailing: 'LOCK',
                                ),
                                const Spacer(),
                                const MicroText(
                                  'TARGET: Bathroom Sink & Runner',
                                  color: Color(0xFFF4F8F3),
                                  fontSize: 11,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: <Widget>[
                                    const Text(
                                      '94% Match',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        color: Color(0xFFB6FF3B),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const Spacer(),
                                    const StatusChip('SCANNING'),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const LinearProgressIndicator(
                                  value: 0.94,
                                  minHeight: 4,
                                  color: Color(0xFFB6FF3B),
                                  backgroundColor: Color(0xFF1E2A22),
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
                                color: Color(0xFFB6FF3B),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: MicroText(
                                  'PROOF ACCEPTED // ALARM DISARMED',
                                  color: Color(0xFFB6FF3B),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )
                      : NeonButton(
                          label: _uploading
                              ? 'UPLOADING PROOF...'
                              : 'CONFIRM PROOF & DISARM',
                          icon: Icons.camera_alt,
                          onPressed: _confirmProof,
                        ),
                  const SizedBox(height: 12),
                  const Text(
                    'Need 5 minutes? Pay with 20 Jumping Jacks penalty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF7C8C82),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  NeonButton(
                    label: 'PAY TO SNOOZE',
                    primary: false,
                    icon: Icons.fitness_center,
                    onPressed: () => _toast(
                      'SNOOZE PENALTY ARMED // 20 JUMPING JACKS REQUIRED',
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel(
                    'MORNING PRIORITY PRIME',
                    trailing: '02 TASKS',
                  ),
                  const SizedBox(height: 10),
                  const _PriorityItem(
                    text: 'Chug 500ml cold electrolyte water',
                  ),
                  const SizedBox(height: 8),
                  const _PriorityItem(text: 'Gym session heavy deadlifts'),
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
          const Icon(Icons.radio_button_unchecked, color: Color(0xFF00E5FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFF4F8F3),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
