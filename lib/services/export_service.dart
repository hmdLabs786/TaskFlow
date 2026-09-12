import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task.dart';

class ExportService {
  static Future<bool> exportTasks(List<Task> tasks) async {
    final data = tasks.map((t) => {
      'id': t.id,
      'title': t.title,
      'note': t.note,
      'isCompleted': t.isCompleted,
      'priority': t.priority.index,
      'category': t.category,
      'dueDate': t.dueDate?.toIso8601String(),
      'recurrence': t.recurrence.index,
      'subtasksJson': t.subtasksJson,
      'orderIndex': t.orderIndex,
    }).toList();

    final json = const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 1,
      'tasks': data,
    });

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/taskflow_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(json);

    return true;
  }

  static Future<List<Map<String, dynamic>>?> importTasks() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return null;

    final file = File(result.files.first.path!);
    final jsonStr = await file.readAsString();
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    if (data['tasks'] == null) return null;

    return (data['tasks'] as List).cast<Map<String, dynamic>>();
  }

  static Task taskFromImport(Map<String, dynamic> data) {
    return Task(
      id: data['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] as String? ?? '',
      note: data['note'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
      priority: TaskPriority.values[data['priority'] as int? ?? 1],
      category: data['category'] as String? ?? 'General',
      dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate'] as String) : null,
      recurrence: RecurrenceType.values[data['recurrence'] as int? ?? 0],
      subtasksJson: data['subtasksJson'] as String? ?? '',
      orderIndex: data['orderIndex'] as int? ?? 0,
    );
  }
}
