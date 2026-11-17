/// Hive type adapter for Streak model.
import 'package:hive/hive.dart';
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
      ..writeNullableString(obj.lastActive?.toIso8601String())
      ..writeString(obj.createdAt.toIso8601String());
  }

  @override
  Streak read(BinaryReader reader) {
    return Streak(
      userId: reader.readString(),
      currentStreak: reader.readInt(),
      longestStreak: reader.readInt(),
      lastActive: reader.readNullableString()?.let((s) => DateTime.parse(s)),
      createdAt: DateTime.parse(reader.readString()),
    );
  }
}
