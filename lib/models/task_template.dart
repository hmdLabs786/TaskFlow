import 'dart:convert';
import 'package:hive/hive.dart';

class TaskTemplate {
  static const String _boxName = 'task_templates_box';

  final String id;
  final String name;
  final String title;
  final String note;
  final int priorityIndex;
  final String category;
  final String subtasksJson;

  TaskTemplate({
    required this.id,
    required this.name,
    required this.title,
    this.note = '',
    this.priorityIndex = 1,
    this.category = 'General',
    this.subtasksJson = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'note': note,
        'priorityIndex': priorityIndex,
        'category': category,
        'subtasksJson': subtasksJson,
      };

  factory TaskTemplate.fromJson(Map<String, dynamic> json) => TaskTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        title: json['title'] as String,
        note: json['note'] as String? ?? '',
        priorityIndex: json['priorityIndex'] as int? ?? 1,
        category: json['category'] as String? ?? 'General',
        subtasksJson: json['subtasksJson'] as String? ?? '',
      );

  static Box get _box => Hive.box(_boxName);

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static List<TaskTemplate> getAll() {
    final jsonList = _box.get('templates', defaultValue: '[]') as String;
    final list = jsonDecode(jsonList) as List;
    return list.map((e) => TaskTemplate.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> save(TaskTemplate template) async {
    final templates = getAll();
    final idx = templates.indexWhere((t) => t.id == template.id);
    if (idx >= 0) {
      templates[idx] = template;
    } else {
      templates.add(template);
    }
    await _box.put('templates', jsonEncode(templates.map((t) => t.toJson()).toList()));
  }

  static Future<void> delete(String id) async {
    final templates = getAll();
    templates.removeWhere((t) => t.id == id);
    await _box.put('templates', jsonEncode(templates.map((t) => t.toJson()).toList()));
  }
}
