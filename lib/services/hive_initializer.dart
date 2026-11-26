library;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hypemotiv/models/task.dart';
import 'package:hypemotiv/models/alarm.dart';
import 'package:hypemotiv/models/streak.dart';
import 'package:hypemotiv/models/sleep_session.dart';
import 'package:hypemotiv/services/task_adapter.dart';
import 'package:hypemotiv/services/alarm_adapter.dart';
import 'package:hypemotiv/services/streak_adapter.dart';
import 'package:hypemotiv/services/sleep_session_adapter.dart';

class HiveInitializer {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(AlarmAdapter());
    Hive.registerAdapter(StreakAdapter());
    Hive.registerAdapter(SleepSessionAdapter());

    await Hive.openBox<Task>('checklist');
    await Hive.openBox<Alarm>('alarms');
    await Hive.openBox<Streak>('streaks');
    await Hive.openBox<SleepSession>('sleep_sessions');
  }
}
