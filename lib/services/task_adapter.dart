/// Hive type adapter for Task model.
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hypemotiv/models/task.dart';

class TaskAdapter extends TypeAdapter<Task> {
  @override
  int get typeId => 0;

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.emoji)
      ..writeBool(obj.completed)
      ..writeString(obj.completedAt?.toIso8601String() ?? '');
  }

  @override
  Task read(BinaryReader reader) {
    return Task(
      id: reader.readString(),
      title: reader.readString(),
      emoji: reader.readString(),
      completed: reader.readBool(),
      completedAt: reader.readString().isNotEmpty
          ? DateTime.parse(reader.readString())
          : null,
    );
  }
}
