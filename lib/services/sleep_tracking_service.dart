/// Sleep tracking service - simulates circadian rhythm analysis and sleep stage tracking.
import 'package:hypemotiv/models/sleep_session.dart';
import 'package:hive/hive';

class SleepTrackingService {
  static const String boxName = 'sleep_sessions';
  final _box = Hive.box<SleepSession>(boxName);

  /// Record a new sleep session (simulates microphone analysis).
  Future<void> recordSleepSession({
    required DateTime start,
    required DateTime end,
    int sleepStages = 0,
    bool restless = false,
    String? notes,
  }) async {
    final session = SleepSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: start,
      endDate: end,
      duration: end.difference(start),
      sleepStages: sleepStages,
      restless: restless,
      notes: notes ?? '',
    );
    await _box.put(session.id, session);
  }

  /// Get sleep history (last 30 days).
  List<SleepSession> getSleepHistory({int limit = 30}) {
    final all = _box.values.cast<SleepSession>().toList();
    all.sort((a, b) => b.startDate.compareTo(a.startDate));
    return all.take(limit).toList();
  }

  /// Calculate average sleep duration over a period.
  Duration getAverageSleepDuration({int days = 30}) {
    final history = getSleepHistory(days: days);
    if (history.isEmpty) return Duration.zero;

    final total = history.fold<int>(0, (sum, s) => sum + s.duration.inSeconds);
    return Duration(seconds: total ~/ history.length);
  }

  /// Calculate sleep consistency index (SCI) - 0-100 score.
  int getSleepConsistencyIndex() {
    final history = getSleepHistory(days: 30);
    if (history.isEmpty) return 0;

    final now = DateTime.now();
    int consistentDays = 0;
    int? prevEnd;

    for (final session in history) {
      if (prevEnd != null) {
        final gap = session.startDate.difference(prevEnd).inHours;
        if (gap <= 24) {
          consistentDays++;
        }
      }
      prevEnd = session.endDate;
    }

    // SCI = (consistentDays / totalDays) * 100
    final totalDays = history.length.toDouble();
    return (consistentDays / totalDays * 100).round().clamp(0, 100);
  }

  /// Get circadian alignment score (0-100).
  int getCircadianAlignmentScore() {
    final now = DateTime.now();
    final hour = now.hour + now.minute / 60.0;

    // Align with natural wake cycle (typically 6-8 AM)
    // Score higher when waking up during natural light cycles
    if (hour >= 6 && hour <= 9) {
      return 90;
    } else if (hour >= 5 && hour <= 10) {
      return 75;
    } else if (hour >= 4 && hour <= 11) {
      return 60;
    } else {
      return 40;
    }
  }

  /// Get the most recent sleep session.
  SleepSession? getLastSession() {
    final all = _box.values.cast<SleepSession>().toList();
    all.sort((a, b) => b.startDate.compareTo(a.startDate));
    return all.firstOrNull;
  }

  /// Delete a sleep session.
  Future<void> deleteSession(String id) async {
    await _box.delete(id);
  }
}
