library;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hypemotiv/models/streak.dart';

class StreakService {
  static const String boxName = 'streaks';
  late Box<Streak> _box;

  StreakService() {
    _box = Hive.box<Streak>(boxName);
  }

  String _currentUserId() => 'default_user';

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

  Future<Streak> updateStreak() async {
    final streak = getOrInitStreak();
    final today = DateTime.now();

    if (streak.lastActive == null) {
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
      updatedStreak = streak.copyWith(
        currentStreak: streak.currentStreak + 1,
        longestStreak: streak.currentStreak + 1 > streak.longestStreak
            ? streak.currentStreak + 1
            : streak.longestStreak,
        lastActive: today,
      );
    } else if (daysSinceLast > 1) {
      updatedStreak = streak.copyWith(
        currentStreak: 1,
        lastActive: today,
      );
    } else {
      updatedStreak = streak.copyWith(lastActive: today);
    }

    await _box.put(streak.userId, updatedStreak);
    return updatedStreak;
  }

  int get currentStreak => getOrInitStreak().currentStreak;

  int get longestStreak => getOrInitStreak().longestStreak;
}
