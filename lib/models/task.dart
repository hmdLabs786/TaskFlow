import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum TaskPriority {
  @HiveField(0) low,
  @HiveField(1) medium,
  @HiveField(2) high,
}

@HiveType(typeId: 1)
enum RecurrenceType {
  @HiveField(0) none,
  @HiveField(1) daily,
  @HiveField(2) weekly,
  @HiveField(3) monthly,
}

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) String note;
  @HiveField(3) bool isCompleted;
  @HiveField(4) TaskPriority priority;
  @HiveField(5) String category;
  @HiveField(6) DateTime? dueDate;
  @HiveField(7) RecurrenceType recurrence;
  @HiveField(8) List<String> attachmentPaths;
  @HiveField(9) String subtasksJson;
  @HiveField(10) int orderIndex;
  @HiveField(11) bool isPinned;

  Task({
    required this.id,
    required this.title,
    this.note = '',
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.category = 'General',
    this.dueDate,
    this.recurrence = RecurrenceType.none,
    List<String>? attachmentPaths,
    this.subtasksJson = '',
    this.orderIndex = 0,
    this.isPinned = false,
  }) : attachmentPaths = attachmentPaths ?? [];
}
