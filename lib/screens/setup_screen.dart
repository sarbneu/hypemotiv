/// Screen 06 — first-run beta setup / wake discipline enrolment.
library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, this.onEnter});

  final VoidCallback? onEnter;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _handleController = TextEditingController(
    text: 'cybersamurail_09',
  );
  final TextEditingController _passcodeController = TextEditingController();
  int _disciplineIndex = 0;

  static const List<String> _disciplines = <String>[
    'Goggins Protocol',
    'Brutal Friend Roast (AI Meme)',
    'Bass-Boost Phonk',
  ];

  static const List<IconData> _disciplineIcons = <IconData>[
    Icons.emoji_events,
    Icons.record_voice_over,
    Icons.graphic_eq,
  ];

  @override
  void dispose() {
    _handleController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  void _toast(String message) {
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
                    status: 'HYPEMOTIV BETA 2.0',
                    trailing: '0% SNOOZE SANCTION APP',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'DESTROY SNOOZE.\nOWN YOUR DAWN.',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFB6FF3B),
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Aggressive wake-up protocols: Merciless AI meme roasts, '
                    'peer camera bounties, and unskippable morning drill checks. '
                    'Bed is the enemy.',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF7C8C82),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SOUND FORGE
                  CyberCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(
                          '140 dB SOUND FORGE',
                          trailing: 'FORGED',
                        ),
                        const SizedBox(height: 8),
                        const Waveform(
                          color: Color(0xFFB6FF3B),
                          bars: 48,
                          height: 52,
                        ),
                        const MicroText(
                          'BASS // ROAST // SIREN CASCADE READY',
                          color: Color(0xFF00E5FF),
                          fontSize: 9,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  const MicroText(
                    'LOGIN OPTIONS',
                    color: Color(0xFF00E5FF),
                    fontSize: 10,
                    letterSpacing: 1.8,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: NeonButton(
                          label: 'Apple ID',
                          primary: false,
                          icon: Icons.apple,
                          height: 44,
                          fontSize: 10,
                          onPressed: () =>
                              _toast('APPLE ID LINK REQUESTED'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: NeonButton(
                          label: 'Google',
                          primary: false,
                          icon: Icons.g_mobiledata,
                          height: 44,
                          fontSize: 10,
                          onPressed: () =>
                              _toast('GOOGLE LINK REQUESTED'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: NeonButton(
                          label: 'Cyberpass',
                          primary: false,
                          icon: Icons.key,
                          height: 44,
                          fontSize: 10,
                          onPressed: () =>
                              _toast('CYBERPASS HANDSHAKE REQUESTED'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  const MicroText(
                    'Runner Handle/Email',
                    color: Color(0xFF00E5FF),
                    fontSize: 10,
                    letterSpacing: 1.6,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _handleController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xFFB6FF3B),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const MicroText(
                    'Dawn Security Passcode',
                    color: Color(0xFF00E5FF),
                    fontSize: 10,
                    letterSpacing: 1.6,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passcodeController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Color(0xFFB6FF3B),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SectionLabel(
                    'CHOOSE WAKE DISCIPLINE',
                    trailing: 'SELECT ONE',
                  ),
                  const SizedBox(height: 10),
                  for (int i = 0; i < _disciplines.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _disciplineIndex = i),
                        child: CyberCard(
                          glow: _disciplineIndex == i,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                _disciplineIcons[i],
                                color: _disciplineIndex == i
                                    ? CyberTheme.lime
                                    : CyberTheme.muted,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MicroText(
                                  _disciplines[i],
                                  color: _disciplineIndex == i
                                      ? CyberTheme.lime
                                      : CyberTheme.white,
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Icon(
                                _disciplineIndex == i
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _disciplineIndex == i
                                    ? CyberTheme.lime
                                    : CyberTheme.muted,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),

                  const SectionLabel(
                    'MANDATORY CAMERA PROOF',
                    trailing: 'REQUIRED',
                  ),
                  const SizedBox(height: 10),
                  const _ProofRow(
                    icon: Icons.water_drop,
                    text: 'Sink & Toothbrush Optical Scan',
                  ),
                  const SizedBox(height: 8),
                  const _ProofRow(
                    icon: Icons.accessibility_new,
                    text: '20 Squats Cam (Pose-AI Sync)',
                  ),
                  const SizedBox(height: 18),

                  const CyberCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        MicroText(
                          '48k Wake Streaks',
                          color: Color(0xFFB6FF3B),
                          fontSize: 9,
                          textAlign: TextAlign.center,
                        ),
                        MicroText(
                          '0% Snooze Black',
                          color: Color(0xFF00E5FF),
                          fontSize: 9,
                          textAlign: TextAlign.center,
                        ),
                        MicroText(
                          'Sync Bio-Signal Link',
                          color: Color(0xFF7C8C82),
                          fontSize: 9,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  NeonButton(
                    label: 'ENTER THE ARENA ⚡',
                    icon: Icons.bolt,
                    onPressed: widget.onEnter,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => _toast('PRIVACY MANIFESTO'),
                        child: const MicroText(
                          'Privacy Manifesto',
                          color: Color(0xFF7C8C82),
                          fontSize: 8,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _toast('AI SNOOZE PENALTIES'),
                        child: const MicroText(
                          'AI Snooze Penalties',
                          color: Color(0xFF7C8C82),
                          fontSize: 8,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _toast('SUPPORT DECK'),
                        child: const MicroText(
                          'Support Deck',
                          color: Color(0xFF7C8C82),
                          fontSize: 8,
                        ),
                      ),
                    ],
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

class _ProofRow extends StatelessWidget {
  const _ProofRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return CyberCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: <Widget>[
          Icon(icon, color: CyberTheme.cyan, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: MicroText(text, color: CyberTheme.white, fontSize: 10),
          ),
          const StatusChip('ON'),
        ],
      ),
    );
  }
}
