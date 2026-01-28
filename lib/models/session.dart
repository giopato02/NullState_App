import 'package:hive/hive.dart';

class Session {
  final DateTime date;
  final int durationMinutes;
  final bool isBreak; // true = break, false = focus

  Session({
    required this.date,
    required this.durationMinutes,
    required this.isBreak,
  });
}

// Manual Adapter to avoid running complex generator commands
class SessionAdapter extends TypeAdapter<Session> {
  @override
  final int typeId = 1; // Unique ID for this data type

  @override
  Session read(BinaryReader reader) {
    final dateMillis = reader.readInt();
    final duration = reader.readInt();
    final isBreak = reader.readBool();
    return Session(
      date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
      durationMinutes: duration,
      isBreak: isBreak,
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeInt(obj.durationMinutes);
    writer.writeBool(obj.isBreak);
  }
}