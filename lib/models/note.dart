import 'package:hive/hive.dart';

part 'note.g.dart'; 

@HiveType(typeId: 0) // Unique ID for this class
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late DateTime date;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
  });
}