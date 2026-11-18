/// Screen 01 — sign-in gate.
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
        backgroundColor: CyberTheme.panel,
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
                    status: 'Welcome back',
                    trailing: 'Sign in',
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      color: Color(0xFF1F2933),
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const MicroText(
                    'Sign in to your account',
                    color: Color(0xFF667085),
                    fontSize: 14,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pick up where you left off: your streak, your reminders '
                    'and your morning routine.',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Face ID sign-in
                  CyberCard(
                    glow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SectionLabel(
                          'Sign in with Face ID',
                          trailing: 'Optional',
                        ),
                        const SizedBox(height: 12),
                        NeonButton(
                          label: 'Sign in with Face ID',
                          icon: Icons.fingerprint,
                          onPressed: () => _toast('Face ID sign in'),
                        ),
                        const SizedBox(height: 8),
                        const MicroText(
                          'Use Face ID, or sign in with your passcode below.',
                          color: Color(0xFF667085),
                          fontSize: 12,
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
                          label: 'Apple',
                          primary: false,
                          icon: Icons.apple,
                          onPressed: () => _toast('Apple sign in requested'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: NeonButton(
                          label: 'Google',
                          primary: false,
                          icon: Icons.g_mobiledata,
                          onPressed: () => _toast('Google sign in requested'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  const MicroText(
                    'Email address',
                    color: Color(0xFF667085),
                    fontSize: 13,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _handleController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.alternate_email,
                        color: Color(0xFF3D5AFE),
                        size: 18,
                      ),
                      hintText: 'you@example.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      const MicroText(
                        'Passcode',
                        color: Color(0xFF667085),
                        fontSize: 13,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            _toast('Password reset link sent'),
                        child: const MicroText(
                          'Forgot password?',
                          color: Color(0xFF3D5AFE),
                          fontSize: 12,
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
                        color: Color(0xFF3D5AFE),
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
                        'Keep me signed in',
                        color: Color(0xFF1F2933),
                        fontSize: 13,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  NeonButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward,
                    onPressed: widget.onEnter,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => _toast('Privacy'),
                        child: const MicroText(
                          'Privacy',
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                      const MicroText(
                        '·',
                        color: Color(0xFF667085),
                        fontSize: 12,
                      ),
                      TextButton(
                        onPressed: () => _toast('Terms'),
                        child: const MicroText(
                          'Terms',
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const MicroText(
                    'Privacy · Terms · 256-bit encryption verified',
                    color: Color(0xFF667085),
                    fontSize: 12,
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
