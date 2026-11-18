/// Hive type adapter for Streak model.
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hypemotiv/models/streak.dart';

class StreakAdapter extends TypeAdapter<Streak> {
  @override
  int get typeId => 2;

  @override
  void write(BinaryWriter writer, Streak obj) {
    writer
      ..writeString(obj.userId)
      ..writeInt(obj.currentStreak)
      ..writeInt(obj.longestStreak)
      ..writeString(obj.lastActive?.toIso8601String() ?? '')
      ..writeString(obj.createdAt.toIso8601String());
  }

  @override
  Streak read(BinaryReader reader) {
    final userId = reader.readString();
    final currentStreak = reader.readInt();
    final longestStreak = reader.readInt();
    final lastActiveStr = reader.readString();
    final createdAtStr = reader.readString();
    return Streak(
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastActive: lastActiveStr.isNotEmpty ? DateTime.parse(lastActiveStr) : null,
      createdAt: DateTime.parse(createdAtStr),
    );
  }
}
