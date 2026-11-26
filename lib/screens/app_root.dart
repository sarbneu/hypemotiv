library;

import 'package:flutter/material.dart';

import 'package:hypemotiv/services/auth_service.dart';

import 'login_screen.dart';
import 'main_screen.dart';
import 'setup_screen.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  int _stage = 0;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final bool signedIn = await AuthService().isSignedIn();
    if (!mounted) return;
    setState(() {
      _stage = signedIn ? 2 : 0;
      _checked = true;
    });
  }

  void _advance() {
    if (_stage < 2) setState(() => _stage++);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    switch (_stage) {
      case 0:
        return LoginScreen(onEnter: _advance);
      case 1:
        return SetupScreen(onEnter: _advance);
      default:
        return const MainScreen();
    }
  }
}
