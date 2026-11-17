/// Hive box initialization helper.
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hypemotiv/models/alarm.dart';
import 'package:hypemotiv/models/task.dart';
import 'package:hypemotiv/models/streak.dart';
import 'package:hypemotiv/models/sleep_session.dart';

class HiveInitializer {
  static Future<void> init() async {
    // Ensure Hive is initialized with Flutter
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(AlarmAdapter());
    Hive.registerAdapter(StreakAdapter());
    Hive.registerAdapter(SleepSessionAdapter());

    // Open boxes
    await Hive.openBox<Task>('checklist');
    await Hive.openBox<Alarm>('alarms');
    await Hive.openBox<Streak>('streaks');
    await Hive.openBox<SleepSession>('sleep_sessions');
  }
}
