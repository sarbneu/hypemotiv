/// Alarm service - manages alarm scheduling and lifecycle.
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hypemotiv/models/alarm.dart';
import 'package:flutter/cupertino.dart';

class AlarmService {
  static const String boxName = 'alarms';
  late Box<Alarm> _box;

  AlarmService() {
    _box = Hive.box<Alarm>(boxName);
  }

  /// Save a new alarm.
  Future<void> saveAlarm(Alarm alarm) async {
    await _box.put(alarm.id, alarm);
  }

  /// Update an existing alarm.
  Future<void> updateAlarm(Alarm alarm) async {
    await _box.put(alarm.id, alarm);
  }

  /// Delete an alarm.
  Future<void> deleteAlarm(String id) async {
    await _box.delete(id);
  }

  /// Get all alarms.
  List<Alarm> getAllAlarms() {
    return _box.values.cast<Alarm>().toList();
  }

  /// Get a specific alarm by ID.
  Alarm? getAlarmById(String id) {
    return _box.get(id);
  }

  /// Get enabled alarms.
  List<Alarm> getEnabledAlarms() {
    return _box.values
        .where((a) => a.enabled)
        .cast<Alarm>()
        .toList();
  }

  /// Get upcoming alarms (future dates).
  List<Alarm> getUpcomingAlarms() {
    final now = DateTime.now();
    return _box.values
        .where((a) => a.enabled && a.scheduledTime.isAfter(now))
        .cast<Alarm>()
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// Check if there is an alarm scheduled now.
  Alarm? getAlarmAtNow() {
    final now = DateTime.now();
    return _box.values
        .where((a) => a.enabled &&
            a.scheduledTime.hour == now.hour &&
            a.scheduledTime.minute == now.minute)
        .cast<Alarm>()
        .firstOrNull;
  }

  /// Total number of alarms.
  int get alarmCount => _box.values.length;
}
