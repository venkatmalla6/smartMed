import 'package:hive/hive.dart';

part 'study_task.g.dart';

@HiveType(typeId: 4)
class StudyTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime scheduledTime;

  @HiveField(4)
  bool isCompleted;

  StudyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledTime,
    this.isCompleted = false,
  });

  StudyTask copyWith({
    String? title,
    String? description,
    DateTime? scheduledTime,
    bool? isCompleted,
  }) {
    return StudyTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
