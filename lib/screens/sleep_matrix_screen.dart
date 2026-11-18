/// Screen 04 — circadian recovery / sleep matrix telemetry.
library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';

class SleepMatrixScreen extends StatelessWidget {
  const SleepMatrixScreen({super.key});

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CyberTheme.panelAlt,
        behavior: SnackBarBehavior.floating,
      ),
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
                    status: 'CIRCADIAN RECOVERY',
                    trailing: '5-DAY STREAK',
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Sleep Matrix',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFF4F8F3),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CyberCard(
                    glow: true,
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          width: 172,
                          height: 172,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: 172,
                                height: 172,
                                child: CircularProgressIndicator(
                                  value: 0.89,
                                  strokeWidth: 10,
                                  backgroundColor: CyberTheme.line,
                                  color: CyberTheme.lime,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text(
                                    '89%',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      color: Color(0xFFB6FF3B),
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const MicroText(
                                    'SCI SCORE',
                                    color: Color(0xFF00E5FF),
                                    fontSize: 9,
                                  ),
                                  const MicroText(
                                    'OPTIMAL',
                                    color: Color(0xFF7C8C82),
                                    fontSize: 9,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const MicroText(
                          'SCI SCORE 89% OPTIMAL',
                          color: Color(0xFFB6FF3B),
                          fontSize: 11,
                          letterSpacing: 1.6,
                        ),
                        const SizedBox(height: 18),
                        const Divider(color: Color(0xFF1E2A22), height: 1),
                        const SizedBox(height: 14),
                        const MicroText(
                          'TOTAL REST ARCHITECTURE 7h 45m',
                          color: Color(0xFFF4F8F3),
                          fontSize: 10,
                        ),
                        const SizedBox(height: 12),
                        const _RestRow(
                          label: 'Deep Rest',
                          value: '2h14m',
                          ratio: 0.28,
                          color: Color(0xFFB6FF3B),
                        ),
                        const SizedBox(height: 10),
                        const _RestRow(
                          label: 'Dream REM',
                          value: '1h48m',
                          ratio: 0.23,
                          color: Color(0xFF00E5FF),
                        ),
                        const SizedBox(height: 10),
                        const _RestRow(
                          label: 'Light Rest',
                          value: '3h40m',
                          ratio: 0.47,
                          color: Color(0xFF7C8C82),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel(
                    'SCHEDULED SHUTDOWN',
                    trailing: 'AUTO // ARMED',
                  ),
                  const SizedBox(height: 10),
                  CyberCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const MicroText(
                              'Lockdown in 2h45m',
                              color: Color(0xFFFF2E88),
                              fontSize: 13,
                            ),
                            const Spacer(),
                            const StatusChip('10:45 PM'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const MicroText(
                          'Auto-lock IG / TikTok / YouTube at 10:45 PM',
                          color: Color(0xFF7C8C82),
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                        const SizedBox(height: 12),
                        const MicroText(
                          'Neural Sleep Frequency: 432Hz Binaural Phonk',
                          color: Color(0xFF00E5FF),
                          fontSize: 10,
                        ),
                        const SizedBox(height: 14),
                        NeonButton(
                          label: 'ENGAGE SLEEP PROTOCOL & LOCKS APP',
                          icon: Icons.lock,
                          fontSize: 10,
                          onPressed: () => _toast(
                            context,
                            'SLEEP PROTOCOL ENGAGED // DISTRACTION LOCKS ON',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('TELEMETRY', trailing: 'MIC ON'),
                  const SizedBox(height: 10),
                  CyberCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const MicroText(
                          'MICROPHONE / AUDIO EVENTS DETECTED',
                          color: Color(0xFF00E5FF),
                          fontSize: 9,
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: <Widget>[
                            Icon(
                              Icons.graphic_eq,
                              color: Color(0xFFFF2E88),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '1 Disturbance (03:42 AM Snort/Stir)',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: Color(0xFFF4F8F3),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const _DataRow(
                          label: 'Acoustic Baseline',
                          value: '28 dB',
                        ),
                        const SizedBox(height: 6),
                        const _DataRow(
                          label: 'Room Sound Profile',
                          value: '+30 dB Safe Zone',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CyberCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const MicroText(
                          'NEXT WAKE SYNERGY',
                          color: Color(0xFFB6FF3B),
                          fontSize: 9,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Hard Math Drill & Freezing Shower',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFFF4F8F3),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Waveform(
                          color: Color(0xFF00E5FF),
                          bars: 44,
                          height: 34,
                        ),
                      ],
                    ),
                  ),
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

class _RestRow extends StatelessWidget {
  const _RestRow({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 88,
          child: MicroText(label, color: CyberTheme.muted, fontSize: 9),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: CyberTheme.line,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          child: MicroText(
            value,
            color: color,
            fontSize: 10,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        MicroText(label, color: CyberTheme.muted, fontSize: 10),
        const Spacer(),
        MicroText(value, color: CyberTheme.white, fontSize: 10),
      ],
    );
  }
}
