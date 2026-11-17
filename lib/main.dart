/// HypeMotiv - Meme audio alarm, daily habit checklist and streak tracker.
///
/// Features:
/// - Basic alarm timer with meme audio
/// - Microphone-based sleep tracking and circadian rhythm analysis
/// - Text-to-speech quote scraper
/// - Local file upload for custom meme sounds
/// - 5-task daily checklist
/// - Streak tracking system
/// - Oracle database connectivity (via REST API sync)
library;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hypemotiv/screens/main_screen.dart';
import 'package:hypemotiv/services/hive_initializer.dart';
import 'package:hypemotiv/services/alarm_service.dart';
import 'package:hypemotiv/services/checklist_service.dart';
import 'package:hypemotiv/services/streak_service.dart';
import 'package:hypemotiv/services/tts_service.dart';
import 'package:hypemotiv/services/audio_service.dart';
import 'package:hypemotiv/services/sleep_tracking_service.dart';
import 'package:hypemotiv/services/quote_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveInitializer.init();

  // Initialize services
  await AlarmService().getAllAlarms(); // Warm up the alarm service
  await ChecklistService().seedDailyChecklist();
  await StreakService().updateStreak();
  await TTSService().init();
  await AudioService().init();

  runApp(const HypeMotivApp());
}

class HypeMotivApp extends StatelessWidget {
  const HypeMotivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HypeMotiv',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: ColorScheme.dark(
          primary: Colors.yellow,
          secondary: Colors.cyan,
          surface: const Color(0xFF2A2A2A),
          error: Colors.red,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Color(0xFFB0B0B0)),
          bodySmall: TextStyle(color: Color(0xFFB0B0B0)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFC107),
          foregroundColor: Colors.black,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Colors.yellow,
          unselectedItemColor: Color(0xFFB0B0B0),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
