/// Hive type adapter for Task model.
import 'package:hive/hive.dart';
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
      ..writeNullableString(obj.completedAt?.toIso8601String());
  }

  @override
  Task read(BinaryReader reader) {
    return Task(
      id: reader.readString(),
      title: reader.readString(),
      emoji: reader.readString(),
      completed: reader.readBool(),
      completedAt: reader.readNullableString()?.let((s) => DateTime.parse(s)),
    );
  }
}

/// Extension to write nullable strings.
extension NullableStringWriter on BinaryWriter {
  void writeNullableString(String? value) {
    writeBool(value != null);
    if (value != null) {
      writeString(value);
    }
  }
}

/// Extension to read nullable strings.
extension NullableStringReader on BinaryReader {
  DateTime? readNullableString() {
    final isPresent = readBool();
    if (!isPresent) return null;
    return DateTime.parse(readString());
  }
}
