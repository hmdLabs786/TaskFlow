import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../services/rich_text_helper.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final Box<Task> _taskBox = Hive.box<Task>('tasks_box');

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Manual';

  bool _multiSelectMode = false;
  final Set<String> _selectedTaskIds = {};

  bool get multiSelectMode => _multiSelectMode;
  Set<String> get selectedTaskIds => Set.unmodifiable(_selectedTaskIds);
  int get selectedCount => _selectedTaskIds.length;

  int get pendingCount => _taskBox.values.where((t) => !t.isCompleted).length;
  int get completedCount => _taskBox.values.where((t) => t.isCompleted).length;

  int categoryCount(String category) {
    if (category == 'All') return _taskBox.values.length;
    return _taskBox.values.where((t) => t.category == category).length;
  }

  List<Task> get tasks {
    var list = _taskBox.values.toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((t) =>
        t.title.toLowerCase().contains(query) ||
        RichTextHelper.extractPlainText(t.note).toLowerCase().contains(query)
      ).toList();
    }

    if (_selectedCategory != 'All') {
      list = list.where((t) => t.category == _selectedCategory).toList();
    }

    if (_sortBy == 'Priority') {
      list.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    } else if (_sortBy == 'Due Date') {
      list.sort((a, b) {
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else {
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }

    return list;
  }

  void addTask(
    String title,
    String note, {
    TaskPriority priority = TaskPriority.medium,
    String category = 'General',
    DateTime? dueDate,
    RecurrenceType recurrence = RecurrenceType.none,
    List<String>? attachmentPaths,
    String subtasksJson = '',
  }) {
    final maxOrder = _taskBox.values.isEmpty
        ? 0
        : _taskBox.values.map((t) => t.orderIndex).reduce((a, b) => a > b ? a : b);

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      note: note,
      priority: priority,
      category: category,
      dueDate: dueDate,
      recurrence: recurrence,
      attachmentPaths: attachmentPaths ?? [],
      subtasksJson: subtasksJson,
      orderIndex: maxOrder + 1,
    );
    _taskBox.put(newTask.id, newTask);

    if (dueDate != null) {
      NotificationService.scheduleNotification(
        id: newTask.id.hashCode,
        title: 'Task Reminder',
        body: title,
        scheduledDate: dueDate,
      );
    }

    notifyListeners();
  }

  void updateTask(
    Task task,
    String newTitle,
    String newNote, {
    TaskPriority? priority,
    String? category,
    DateTime? dueDate,
    RecurrenceType? recurrence,
    List<String>? attachmentPaths,
    String? subtasksJson,
  }) {
    task.title = newTitle;
    task.note = newNote;
    if (priority != null) task.priority = priority;
    if (category != null) task.category = category;
    if (dueDate != null) task.dueDate = dueDate;
    if (recurrence != null) task.recurrence = recurrence;
    if (attachmentPaths != null) task.attachmentPaths = attachmentPaths;
    if (subtasksJson != null) task.subtasksJson = subtasksJson;
    task.save();

    NotificationService.cancelNotification(task.id.hashCode);
    if (task.dueDate != null && !task.isCompleted) {
      NotificationService.scheduleNotification(
        id: task.id.hashCode,
        title: 'Task Reminder',
        body: task.title,
        scheduledDate: task.dueDate!,
      );
    }

    notifyListeners();
  }

  void deleteTask(Task task) {
    NotificationService.cancelNotification(task.id.hashCode);
    task.delete();
    _selectedTaskIds.remove(task.id);
    if (_selectedTaskIds.isEmpty) _multiSelectMode = false;
    notifyListeners();
  }

  void toggleTaskPin(Task task) {
    task.isPinned = !task.isPinned;
    task.save();
    notifyListeners();
  }

  bool toggleTaskStatus(Task task, BuildContext context) {
    if (task.isCompleted && task.recurrence == RecurrenceType.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('One-time tasks cannot be uncompleted once marked done.'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    if (!task.isCompleted && task.dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final taskDueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      
      if (taskDueDate.isAfter(today)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This task is scheduled for ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}. You can only complete it on or after that date.'),
            duration: const Duration(seconds: 3),
          ),
        );
        return false;
      }
    }

    task.isCompleted = !task.isCompleted;

    if (task.isCompleted) {
      NotificationService.cancelNotification(task.id.hashCode);
    }

    if (task.isCompleted && task.recurrence != RecurrenceType.none && task.dueDate != null) {
      if (task.recurrence == RecurrenceType.daily) {
        task.dueDate = task.dueDate!.add(const Duration(days: 1));
      } else if (task.recurrence == RecurrenceType.weekly) {
        task.dueDate = task.dueDate!.add(const Duration(days: 7));
      } else if (task.recurrence == RecurrenceType.monthly) {
        final nextMonth = task.dueDate!.month + 1;
        final nextYear = nextMonth > 12 ? task.dueDate!.year + 1 : task.dueDate!.year;
        final adjustedMonth = nextMonth > 12 ? 1 : nextMonth;
        final lastDay = DateTime(nextYear, adjustedMonth + 1, 0).day;
        final adjustedDay = task.dueDate!.day > lastDay ? lastDay : task.dueDate!.day;
        task.dueDate = DateTime(nextYear, adjustedMonth, adjustedDay);
      }
      task.isCompleted = false;

      NotificationService.scheduleNotification(
        id: task.id.hashCode,
        title: 'Task Reminder',
        body: task.title,
        scheduledDate: task.dueDate!,
      );
    }

    task.save();
    notifyListeners();
    return true;
  }

  void reorderTask(int oldIndex, int newIndex) {
    final list = tasks;
    if (oldIndex < newIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    for (int i = 0; i < list.length; i++) {
      list[i].orderIndex = i;
      list[i].save();
    }
    notifyListeners();
  }

  void toggleMultiSelect() {
    _multiSelectMode = !_multiSelectMode;
    if (!_multiSelectMode) _selectedTaskIds.clear();
    notifyListeners();
  }

  void toggleTaskSelection(String taskId) {
    if (_selectedTaskIds.contains(taskId)) {
      _selectedTaskIds.remove(taskId);
    } else {
      _selectedTaskIds.add(taskId);
    }
    if (_selectedTaskIds.isEmpty) _multiSelectMode = false;
    notifyListeners();
  }

  void selectAll() {
    _selectedTaskIds.addAll(tasks.map((t) => t.id));
    notifyListeners();
  }

  void deleteSelected() {
    for (final id in _selectedTaskIds) {
      _taskBox.delete(id);
    }
    _selectedTaskIds.clear();
    _multiSelectMode = false;
    notifyListeners();
  }

  void completeSelected() {
    for (final id in _selectedTaskIds) {
      final task = _taskBox.get(id);
      if (task != null && !task.isCompleted) {
        task.isCompleted = true;
        task.save();
        NotificationService.cancelNotification(task.id.hashCode);
      }
    }
    _selectedTaskIds.clear();
    _multiSelectMode = false;
    notifyListeners();
  }

  void updateSubtasks(Task task, String subtasksJson) {
    task.subtasksJson = subtasksJson;
    task.save();
    notifyListeners();
  }

  void clearCompletedTasks() {
    final completedTasks = _taskBox.values.where((t) => t.isCompleted).toList();
    for (final task in completedTasks) {
      NotificationService.cancelNotification(task.id.hashCode);
      task.delete();
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void exitMultiSelect() {
    _multiSelectMode = false;
    _selectedTaskIds.clear();
    notifyListeners();
  }

  void addTaskFromTemplate(String title, String note, String subtasksJson,
      {TaskPriority priority = TaskPriority.medium,
      String category = 'General'}) {
    addTask(title, note, priority: priority, category: category, subtasksJson: subtasksJson);
  }
}
