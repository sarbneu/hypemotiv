library;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hypemotiv/models/alarm.dart';

class AlarmAdapter extends TypeAdapter<Alarm> {
  @override
  int get typeId => 1;

  @override
  void write(BinaryWriter writer, Alarm obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.scheduledTime.toIso8601String())
      ..writeString(obj.audioUrl)
      ..writeBool(obj.enabled)
      ..writeString(obj.createdAt.toIso8601String());
  }

  @override
  Alarm read(BinaryReader reader) {
    return Alarm(
      id: reader.readString(),
      title: reader.readString(),
      scheduledTime: DateTime.parse(reader.readString()),
      audioUrl: reader.readString(),
      enabled: reader.readBool(),
      createdAt: DateTime.parse(reader.readString()),
    );
  }
}
