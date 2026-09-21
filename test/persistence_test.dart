import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../lib/models/task.dart';

void main() {
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(RecurrenceTypeAdapter());
  Hive.registerAdapter(TaskAdapter());

  late Directory tempDir;
  late Box<Task> box;

  Future<void> startApp() async {
    Hive.init(tempDir.path);
    box = await Hive.openBox<Task>('tasks_box');
  }

  Future<void> stopApp() async {
    await Hive.close();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('taskflow_test');
    await startApp();
  });

  tearDown(() async {
    await stopApp();
    await tempDir.delete(recursive: true);
  });

  test('a saved task survives force-close and reopen with all fields intact',
      () async {
    final task = Task(
      id: 'task-1',
      title: 'Ship release notes',
      note: '[{"insert":"Important details here"}]',
      isCompleted: false,
      priority: TaskPriority.high,
      category: 'Work',
      dueDate: DateTime(2026, 10, 5, 9, 30),
      recurrence: RecurrenceType.weekly,
      attachmentPaths: ['/data/images/one.jpg'],
      subtasksJson: '[{"title":"Draft","isCompleted":true}]',
      orderIndex: 3,
      isPinned: true,
    );
    box.put(task.id, task);

    await stopApp();
    await startApp();

    final restored = box.get('task-1');
    expect(restored, isNotNull);
    expect(restored!.id, 'task-1');
    expect(restored.title, 'Ship release notes');
    expect(restored.note, '[{"insert":"Important details here"}]');
    expect(restored.isCompleted, false);
    expect(restored.priority, TaskPriority.high);
    expect(restored.category, 'Work');
    expect(restored.dueDate, DateTime(2026, 10, 5, 9, 30));
    expect(restored.recurrence, RecurrenceType.weekly);
    expect(restored.attachmentPaths, ['/data/images/one.jpg']);
    expect(restored.subtasksJson, '[{"title":"Draft","isCompleted":true}]');
    expect(restored.orderIndex, 3);
    expect(restored.isPinned, true);
  });

  test('a completed state survives force-close and reopen', () async {
    box.put('task-2', Task(id: 'task-2', title: 'Complete onboarding'));

    final t = box.get('task-2')!;
    t.isCompleted = true;
    t.save();

    await stopApp();
    await startApp();

    expect(box.get('task-2')!.isCompleted, isTrue);
  });

  test('a deleted task stays deleted after force-close and reopen', () async {
    box.put('task-3', Task(id: 'task-3', title: 'Delete me'));
    box.delete('task-3');

    await stopApp();
    await startApp();

    expect(box.get('task-3'), isNull);
    expect(box.values, isEmpty);
  });

  test('multiple tasks all survive force-close and reopen', () async {
    for (var i = 0; i < 50; i++) {
      box.put('task-$i', Task(id: 'task-$i', title: 'Task number $i'));
    }

    await stopApp();
    await startApp();

    expect(box.length, 50);
    expect(box.get('task-49')!.title, 'Task number 49');
  });
}