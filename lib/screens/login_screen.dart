/// Screen 01 — operator authorisation gate.
library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onEnter});

  final VoidCallback? onEnter;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _handleController = TextEditingController(
    text: 'runner@hypemotiv.app',
  );
  final TextEditingController _keyController = TextEditingController();
  bool _streakLock = true;

  @override
  void dispose() {
    _handleController.dispose();
    _keyController.dispose();
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const BrandHeader(
                    status: 'SYS // ONLINE',
                    trailing: 'STAGE 01 PROTOCOL',
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'STAGE 01 PROTOCOL',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFB6FF3B),
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const MicroText(
                    'SECURE OPERATOR ACCESS',
                    color: Color(0xFF00E5FF),
                    fontSize: 11,
                    letterSpacing: 2.2,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Sync discipline nodes to restore your streak multiplier, '
                    'accountability vault, and roast packs.',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF7C8C82),
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // BIO-LOCK OVERRIDE
                  CyberCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(
                          'BIO-LOCK OVERRIDE',
                          trailing: 'AUTH // 01',
                        ),
                        const SizedBox(height: 12),
                        NeonButton(
                          label: 'PASS',
                          icon: Icons.fingerprint,
                          onPressed: () => _toast(
                            'FACE ID / NEURAL SCAN / TAP WAKE — BIOMETRIC PASS',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const MicroText(
                          'Face ID / Neural Scan / Tap Wake',
                          color: Color(0xFF7C8C82),
                          fontSize: 9,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: NeonButton(
                          label: 'Apple Key',
                          primary: false,
                          icon: Icons.apple,
                          onPressed: () =>
                              _toast('APPLE KEY HANDSHAKE REQUESTED'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: NeonButton(
                          label: 'Google ID',
                          primary: false,
                          icon: Icons.g_mobiledata,
                          onPressed: () =>
                              _toast('GOOGLE ID HANDSHAKE REQUESTED'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  const MicroText(
                    'RUNNER IDENTIFIER / HANDLE',
                    color: Color(0xFF00E5FF),
                    fontSize: 10,
                    letterSpacing: 1.8,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _handleController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.alternate_email,
                        color: Color(0xFFB6FF3B),
                        size: 18,
                      ),
                      hintText: '@runner@hypemotiv.app',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      const MicroText(
                        'DAWN SECURITY KEY',
                        color: Color(0xFF00E5FF),
                        fontSize: 10,
                        letterSpacing: 1.8,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            _toast('KEY RECOVERY LINK DISPATCHED'),
                        child: const MicroText(
                          'Forgot Key?',
                          color: Color(0xFFFF2E88),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.key,
                        color: Color(0xFFB6FF3B),
                        size: 18,
                      ),
                      hintText: '••••••••••••',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _streakLock,
                          activeColor: CyberTheme.lime,
                          checkColor: CyberTheme.bg,
                          side: BorderSide(color: CyberTheme.line),
                          onChanged: (bool? value) {
                            setState(() => _streakLock = value ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const MicroText(
                        'Maintain Daily Streak Lock',
                        color: Color(0xFFF4F8F3),
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  NeonButton(
                    label: 'AUTHORIZE & ENTER ARENA ⚡',
                    icon: Icons.bolt,
                    onPressed: widget.onEnter,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => _toast('PRIVACY MANIFESTO'),
                        child: const MicroText(
                          'Privacy',
                          color: Color(0xFF7C8C82),
                          fontSize: 9,
                        ),
                      ),
                      const MicroText(
                        '/',
                        color: Color(0xFF1E2A22),
                        fontSize: 9,
                      ),
                      TextButton(
                        onPressed: () => _toast('TERMS OF DISCIPLINE'),
                        child: const MicroText(
                          'Terms',
                          color: Color(0xFF7C8C82),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const MicroText(
                    '256-BIT DISCIPLINE ENCRYPTION VERIFIED',
                    color: Color(0xFF1E2A22),
                    fontSize: 9,
                    textAlign: TextAlign.center,
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
