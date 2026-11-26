library;

import 'package:flutter/material.dart';
import 'package:hypemotiv/screens/app_root.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/hive_initializer.dart';
import 'package:hypemotiv/services/notification_service.dart';
import 'package:hypemotiv/services/theme_service.dart';
import 'package:hypemotiv/services/tts_service.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveInitializer.init();

  await NotificationService().init();

  await ThemeService().init();

  await AudioService().init();
  await TTSService().init();

  runApp(const HypeMotivApp());
}

class HypeMotivApp extends StatelessWidget {
  const HypeMotivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().mode,
      builder: (BuildContext context, ThemeMode mode, Widget? child) {
        return MaterialApp(
          title: 'HypeMotiv',
          debugShowCheckedModeBanner: false,
          theme: CyberTheme.themeData(),
          darkTheme: _darkTheme(),
          themeMode: mode,
          home: const AppRoot(),
        );
      },
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111417),
      cardColor: const Color(0xFF1A1F24),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8FA9FF),
        secondary: Color(0xFF4DD0C1),
        surface: Color(0xFF1A1F24),
      ),
      useMaterial3: true,
    );
  }
}
