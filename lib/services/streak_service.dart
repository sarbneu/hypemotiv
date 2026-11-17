/// Streak service - tracks consecutive active days.
import 'package:hypemotiv/models/streak.dart';
import 'package:hive/hive';

class StreakService {
  static const String boxName = 'streaks';
  final _box = Hive.box<Streak>(boxName);

  String _currentUserId() => 'default_user';

  /// Get or create the streak for the current user.
  Streak getOrInitStreak() {
    final userId = _currentUserId();
    final existing = _box.get(userId);
    if (existing != null) {
      return existing;
    }

    final newStreak = Streak(userId: userId);
    _box.put(userId, newStreak);
    return newStreak;
  }

  /// Update streak for the current day (called at app open).
  Future<Streak> updateStreak() async {
    final streak = getOrInitStreak();
    final today = DateTime.now();

    // Check if we need to increment the streak
    if (streak.lastActive == null) {
      // First time ever
      final updated = streak.copyWith(
        currentStreak: 1,
        longestStreak: 1,
        lastActive: today,
      );
      _box.put(streak.userId, updated);
      return updated;
    }

    final daysSinceLast = today.difference(streak.lastActive!).inDays;

    Streak updatedStreak;
    if (daysSinceLast == 1) {
      // Consecutive day
      updatedStreak = streak.copyWith(
        currentStreak: streak.currentStreak + 1,
        longestStreak: streak.currentStreak + 1 > streak.longestStreak
            ? streak.currentStreak + 1
            : streak.longestStreak,
        lastActive: today,
      );
    } else if (daysSinceLast > 1) {
      // Streak broken
      updatedStreak = streak.copyWith(
        currentStreak: 1,
        lastActive: today,
      );
    } else {
      // Same day, just update
      updatedStreak = streak.copyWith(lastActive: today);
    }

    await _box.put(streak.userId, updatedStreak);
    return updatedStreak;
  }

  /// Get the current streak count.
  int get currentStreak => getOrInitStreak().currentStreak;

  /// Get the longest streak.
  int get longestStreak => getOrInitStreak().longestStreak;
}
