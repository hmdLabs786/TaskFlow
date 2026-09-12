import 'dart:convert';

class SubTask {
  String title;
  bool isCompleted;

  SubTask({required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
        'title': title,
        'isCompleted': isCompleted,
      };

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  static List<SubTask> listFromJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => SubTask.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<SubTask> subtasks) {
    return jsonEncode(subtasks.map((s) => s.toJson()).toList());
  }
}
