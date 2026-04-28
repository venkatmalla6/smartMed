import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final List<String>? tags;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    List<String>? tags,
  }) : tags = tags ?? const [];

  Note copyWith({
    String? title,
    String? content,
    List<String>? tags,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      tags: tags ?? this.tags,
    );
  }
}
