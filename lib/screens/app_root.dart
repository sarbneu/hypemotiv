/// Root navigation: secure access -> arena setup -> main dashboard.
/// Keeping the flow here means each screen stays independently reusable.
library;

import 'package:flutter/material.dart';

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

  void _advance() {
    if (_stage < 2) setState(() => _stage++);
  }

  @override
  Widget build(BuildContext context) {
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
