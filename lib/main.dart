/// HypeMotiv - meme audio alarm, daily habit checklist and streak tracker.
///
/// Architecture:
///  - Flutter app + Hive for offline-first local storage
///  - Node.js/Express REST backend (`oracle-backend/`) hosted on an Oracle Cloud VPS
///  - Oracle Database for relational data and BLOB file storage
///  - nodemailer for accountability email, myinstants scraping and video audio ripping
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

  // Boxes must be open before any service looks them up.
  await HiveInitializer.init();

  // Real alarm / reminder notifications.
  await NotificationService().init();

  // Persisted light/dark preference.
  await ThemeService().init();

  // Non-Hive services are safe to initialise afterwards.
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
