part of 'task.dart';

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 2;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      note: fields[2] as String,
      isCompleted: fields[3] as bool,
      priority: fields[4] as TaskPriority,
      category: fields[5] as String,
      dueDate: fields[6] as DateTime?,
      recurrence: fields[7] as RecurrenceType,
      attachmentPaths: (fields[8] as List?)?.cast<String>(),
      subtasksJson: fields[9] as String? ?? '',
      orderIndex: fields[10] as int? ?? 0,
      isPinned: fields[11] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.note)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.dueDate)
      ..writeByte(7)
      ..write(obj.recurrence)
      ..writeByte(8)
      ..write(obj.attachmentPaths)
      ..writeByte(9)
      ..write(obj.subtasksJson)
      ..writeByte(10)
      ..write(obj.orderIndex)
      ..writeByte(11)
      ..write(obj.isPinned);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 0;

  @override
  TaskPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskPriority.low;
      case 1:
        return TaskPriority.medium;
      case 2:
        return TaskPriority.high;
      default:
        return TaskPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    switch (obj) {
      case TaskPriority.low:
        writer.writeByte(0);
        break;
      case TaskPriority.medium:
        writer.writeByte(1);
        break;
      case TaskPriority.high:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceTypeAdapter extends TypeAdapter<RecurrenceType> {
  @override
  final int typeId = 1;

  @override
  RecurrenceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceType.none;
      case 1:
        return RecurrenceType.daily;
      case 2:
        return RecurrenceType.weekly;
      case 3:
        return RecurrenceType.monthly;
      default:
        return RecurrenceType.none;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceType obj) {
    switch (obj) {
      case RecurrenceType.none:
        writer.writeByte(0);
        break;
      case RecurrenceType.daily:
        writer.writeByte(1);
        break;
      case RecurrenceType.weekly:
        writer.writeByte(2);
        break;
      case RecurrenceType.monthly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
