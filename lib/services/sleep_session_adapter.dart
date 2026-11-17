/// Hive type adapter for SleepSession model.
import 'package:hive/hive.dart';
import 'package:hypemotiv/models/sleep_session.dart';

class SleepSessionAdapter extends TypeAdapter<SleepSession> {
  @override
  int get typeId => 3;

  @override
  void write(BinaryWriter writer, SleepSession obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.startDate.toIso8601String())
      ..writeString(obj.endDate.toIso8601String())
      ..writeInt(obj.duration.inSeconds)
      ..writeInt(obj.sleepStages)
      ..writeBool(obj.restless)
      ..writeString(obj.notes)
      ..writeString(obj.createdAt.toIso8601String());
  }

  @override
  SleepSession read(BinaryReader reader) {
    return SleepSession(
      id: reader.readString(),
      startDate: DateTime.parse(reader.readString()),
      endDate: DateTime.parse(reader.readString()),
      duration: Duration(seconds: reader.readInt()),
      sleepStages: reader.readInt(),
      restless: reader.readBool(),
      notes: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
    );
  }
}
