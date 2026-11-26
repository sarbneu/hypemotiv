library;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hypemotiv/models/alarm.dart';

class AlarmService {
  static const String boxName = 'alarms';
  late Box<Alarm> _box;

  AlarmService() {
    _box = Hive.box<Alarm>(boxName);
  }

  Future<void> saveAlarm(Alarm alarm) async {
    await _box.put(alarm.id, alarm);
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await _box.put(alarm.id, alarm);
  }

  Future<void> deleteAlarm(String id) async {
    await _box.delete(id);
  }

  List<Alarm> getAllAlarms() {
    return _box.values.cast<Alarm>().toList();
  }

  Alarm? getAlarmById(String id) {
    return _box.get(id);
  }

  List<Alarm> getEnabledAlarms() {
    return _box.values
        .where((a) => a.enabled)
        .cast<Alarm>()
        .toList();
  }

  List<Alarm> getUpcomingAlarms() {
    final now = DateTime.now();
    return _box.values
        .where((a) => a.enabled && a.scheduledTime.isAfter(now))
        .cast<Alarm>()
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  Alarm? getAlarmAtNow() {
    final now = DateTime.now();
    return _box.values
        .where((a) => a.enabled &&
            a.scheduledTime.hour == now.hour &&
            a.scheduledTime.minute == now.minute)
        .cast<Alarm>()
        .firstOrNull;
  }

  int get alarmCount => _box.values.length;
}
