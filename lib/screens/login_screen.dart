/// Sign-in gate with a real on-device account (create / sign in / reset).
library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/auth_service.dart';
import 'package:hypemotiv/services/notification_service.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onEnter});

  final VoidCallback? onEnter;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _handleController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String _error = '';
  bool _registered = false;
  bool _registerMode = true;
  bool _busy = false;
  bool _remember = true;
  bool _alarmTesting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AuthService auth = AuthService();
    final bool registered = await auth.isRegistered();
    final String? user = await auth.savedUser();
    if (!mounted) return;
    setState(() {
      _registered = registered;
      _registerMode = !registered;
      if (user != null) _handleController.text = user;
    });
  }

  @override
  void dispose() {
    if (_alarmTesting) AudioService().stop();
    _handleController.dispose();
    _keyController.dispose();
    _confirmController.dispose();
    super.dispose();
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

  String? _validate() {
    final String? userError =
        AuthService.validateUser(_handleController.text);
    if (userError != null) return userError;
    return AuthService.validatePasscode(
      _keyController.text,
      confirmation: _registerMode ? _confirmController.text : null,
    );
  }

  Future<void> _submit() async {
    final String? problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      _toast(problem);
      return;
    }
    setState(() {
      _error = '';
      _busy = true;
    });
    final String user = _handleController.text.trim().toLowerCase();
    final String pass = _keyController.text.trim();
    final AuthService auth = AuthService();
    bool ok;
    if (_registerMode) {
      await auth.register(user, pass);
      ok = true;
    } else {
      ok = await auth.login(user, pass);
    }
    if (!_remember) await auth.signOut();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!ok) {
      setState(() => _error = 'Incorrect passcode or handle');
      _toast(_error);
      return;
    }
    _toast(_registerMode ? 'Account created' : 'Signed in');
    widget.onEnter?.call();
  }

  void _showInfo(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Reset local account'),
        content: const Text(
          'This deletes the saved handle and passcode on this device. Your sleep logs and tasks are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService().resetAccount();
    if (!mounted) return;
    setState(() {
      _registered = false;
      _registerMode = true;
      _handleController.clear();
      _keyController.clear();
    });
    _toast('Local account reset');
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
                  BrandHeader(
                    status: _statusText,
                    trailing: _trailingText,
                  ),
                  const SizedBox(height: 26),
                  Text(
                    _registerMode ? 'Create your account' : 'Welcome back',
                    style: const TextStyle(
                      color: Color(0xFF1F2933),
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  MicroText(
                    _registerMode
                        ? 'One handle and passcode, saved on this device.'
                        : 'Sign in to your account',
                    color: const Color(0xFF667085),
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
                  CyberCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
                        SectionLabel('Your account', trailing: 'On this device'),
                        SizedBox(height: 8),
                        Text(
                          'No server account is needed for the demo. Your handle and '
                          'passcode stay in this app; sleep logs and tasks are stored locally '
                          'and sync to Oracle when a backend is configured.',
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const MicroText(
                    'Email or handle',
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
                      hintText: 'you@example.com or runner09',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const MicroText(
                    'Passcode',
                    color: Color(0xFF667085),
                    fontSize: 13,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.key,
                        color: Color(0xFF3D5AFE),
                        size: 18,
                      ),
                      hintText: 'Any passcode, even 1 character',
                    ),
                  ),
                  if (_registerMode) ...<Widget>[
                    const SizedBox(height: 12),
                    const MicroText(
                      'Repeat passcode',
                      color: Color(0xFF667085),
                      fontSize: 13,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.key,
                          color: Color(0xFF3D5AFE),
                          size: 18,
                        ),
                        hintText: 'Repeat your passcode',
                      ),
                    ),
                  ],
                  if (_error.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      _error,
                      style: const TextStyle(
                        color: Color(0xFFF04438),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _remember,
                          activeColor: CyberTheme.lime,
                          checkColor: CyberTheme.bg,
                          side: BorderSide(color: CyberTheme.line),
                          onChanged: (bool? value) {
                            setState(() => _remember = value ?? false);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const MicroText(
                        'Stay signed in on this device',
                        color: Color(0xFF1F2933),
                        fontSize: 13,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  NeonButton(
                    label: _busy
                        ? 'Please wait...'
                        : _registerMode
                            ? 'Create account and continue'
                            : 'Sign in and continue',
                    icon: Icons.arrow_forward,
                    onPressed: _busy ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => setState(
                          () => _registerMode = !_registerMode,
                        ),
                        child: MicroText(
                          _registerMode
                              ? 'Already have an account? Sign in'
                              : 'Need an account? Create one',
                          color: const Color(0xFF3D5AFE),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => widget.onEnter?.call(),
                    child: const MicroText(
                      'Skip sign in for now',
                      color: Color(0xFF667085),
                      fontSize: 12,
                    ),
                  ),
                  if (_registered)
                    TextButton(
                      onPressed: _resetAccount,
                      child: const MicroText(
                        'Reset local account',
                        color: Color(0xFF667085),
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      await AudioService().playLocalTest();
                      _toast('Test sound played');
                    },
                    icon: const Icon(Icons.volume_up, size: 16),
                    label: const MicroText(
                      'Play test sound (offline)',
                      color: Color(0xFF3D5AFE),
                      fontSize: 12,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      if (_alarmTesting) {
                        await AudioService().stop();
                        if (!mounted) return;
                        setState(() => _alarmTesting = false);
                        _toast('Alarm test stopped');
                        return;
                      }
                      await AudioService().play(
                        AudioService.fallbackSoundUrl,
                        loop: true,
                      );
                      await NotificationService().showImmediate(
                        title: 'Alarm test',
                        body: 'Your alarm can ring and notify you.',
                      );
                      if (!mounted) return;
                      setState(() => _alarmTesting = true);
                      _toast('Alarm ringing - tap again to stop');
                    },
                    icon: const Icon(Icons.notifications_active_outlined, size: 16),
                    label: MicroText(
                      _alarmTesting ? 'Stop alarm test' : 'Test alarm now',
                      color: Color(0xFF3D5AFE),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => _showInfo(
                          'Privacy',
                          'HypeMotiv stores your demo account, tasks and sleep '
                          'sessions on this device. When a backend is configured, '
                          'data is sent to your own Oracle database.',
                        ),
                        child: const MicroText(
                          'Privacy',
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                      const MicroText('·', color: Color(0xFF667085), fontSize: 12),
                      TextButton(
                        onPressed: () => _showInfo(
                          'Terms',
                          'This is a student prototype for CIS099-2. Use it at '
                          'your own risk and do not store real passwords here.',
                        ),
                        child: const MicroText(
                          'Terms',
                          color: Color(0xFF667085),
                          fontSize: 12,
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

  String get _statusText => _registerMode ? 'Create account' : 'Sign in';
  String get _trailingText => _registered ? 'Account saved' : 'First run';
}
