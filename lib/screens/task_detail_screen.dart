import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/sub_task.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/rich_text_helper.dart';
import 'add_task_screen.dart';
import 'attachment_viewer_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    context.watch<TaskProvider>();

    final box = Hive.box<Task>('tasks_box');
    final task = box.get(widget.task.id) ?? widget.task;
    final isCompleted = task.isCompleted;
    final subtasks = SubTask.listFromJson(task.subtasksJson);

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 16,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildHeader(colorScheme, task),
              Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleRow(colorScheme, task, isCompleted),
                      const SizedBox(height: 12),
                      _buildMetaChips(colorScheme, task),
                      if (task.note.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildNoteSection(colorScheme, task),
                      ],
                      if (subtasks.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSubtasksSection(colorScheme, task, subtasks),
                      ],
                      if (task.attachmentPaths.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildAttachmentsSection(colorScheme, task),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 24),
          ),
          const Spacer(),
          Text(
            'Task details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (!task.isCompleted)
            TextButton.icon(
              onPressed: () => _openEdit(task),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                'Edit',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(ColorScheme colorScheme, Task task, bool isCompleted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.read<TaskProvider>().toggleTaskStatus(task, context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isCompleted ? _getPriorityColor(task.priority) : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isCompleted
                    ? _getPriorityColor(task.priority)
                    : colorScheme.onSurfaceVariant,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            task.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
              color: isCompleted ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaChips(ColorScheme colorScheme, Task task) {
    final overdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _metaChip(
          icon: Icons.flag_outlined,
          label: task.priority.name[0].toUpperCase() + task.priority.name.substring(1),
          iconColor: _getPriorityColor(task.priority),
          colorScheme: colorScheme,
        ),
        if (task.category != 'General')
          _metaChip(
            icon: Icons.label_outline_rounded,
            label: task.category,
            colorScheme: colorScheme,
          ),
        if (task.dueDate != null)
          _metaChip(
            icon: overdue ? Icons.warning_amber_rounded : Icons.calendar_today_rounded,
            label: '${_monthName(task.dueDate!.month)} ${task.dueDate!.day}, ${task.dueDate!.year}',
            colorScheme: colorScheme,
            highlight: overdue,
          ),
        if (task.recurrence != RecurrenceType.none)
          _metaChip(
            icon: Icons.repeat_rounded,
            label: task.recurrence.name[0].toUpperCase() + task.recurrence.name.substring(1),
            colorScheme: colorScheme,
          ),
        if (task.attachmentPaths.isNotEmpty)
          _metaChip(
            icon: Icons.attach_file_rounded,
            label: '${task.attachmentPaths.length} attachment(s)',
            colorScheme: colorScheme,
          ),
      ],
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    Color? iconColor,
    bool highlight = false,
  }) {
    final accent = highlight ? colorScheme.error : (iconColor ?? colorScheme.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (highlight ? colorScheme.error : accent).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(ColorScheme colorScheme, Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        if (RichTextHelper.isRichText(task.note))
          _buildRichNote(task.note, colorScheme)
        else
          Text(
            task.note,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
      ],
    );
  }

  Widget _buildRichNote(String note, ColorScheme colorScheme) {
    try {
      final controller = quill.QuillController(
        document: quill.Document.fromJson(jsonDecode(note) as List),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: quill.QuillEditor.basic(
          controller: controller,
          config: quill.QuillEditorConfig(
            padding: EdgeInsets.zero,
            autoFocus: false,
            enableInteractiveSelection: false,
            scrollable: false,
            expands: false,
          ),
          scrollController: ScrollController(),
        ),
      );
    } catch (_) {
      return Text(
        RichTextHelper.extractPlainText(note),
        style: const TextStyle(fontSize: 15, height: 1.5),
      );
    }
  }

  Widget _buildSubtasksSection(ColorScheme colorScheme, Task task, List<SubTask> subtasks) {
    final doneCount = subtasks.where((s) => s.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subtasks  ($doneCount/${subtasks.length})',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...subtasks.map((sub) => InkWell(
              onTap: () {
                if (!sub.isCompleted && task.dueDate != null) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final taskDueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
                  
                  if (taskDueDate.isAfter(today)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('This task is scheduled for ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}. Subtasks cannot be completed before that date.'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                }
                setState(() => sub.isCompleted = !sub.isCompleted);
                context.read<TaskProvider>().updateSubtasks(task, SubTask.listToJson(subtasks));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: sub.isCompleted ? colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: sub.isCompleted ? colorScheme.primary : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: sub.isCompleted
                          ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sub.title,
                        style: TextStyle(
                          fontSize: 15,
                          decoration: sub.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: sub.isCompleted
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildAttachmentsSection(ColorScheme colorScheme, Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments  (${task.attachmentPaths.length})',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: task.attachmentPaths.map((path) {
            final isImage = path.toLowerCase().endsWith('.jpg') ||
                path.toLowerCase().endsWith('.jpeg') ||
                path.toLowerCase().endsWith('.png') ||
                path.toLowerCase().endsWith('.webp');
            return GestureDetector(
              onTap: () {
                final index = task.attachmentPaths.indexOf(path);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AttachmentViewerScreen(
                      attachmentPaths: task.attachmentPaths,
                      initialIndex: index >= 0 ? index : 0,
                    ),
                  ),
                );
              },
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(path), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insert_drive_file_rounded,
                              size: 28, color: colorScheme.primary),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              p.basename(path),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _openEdit(Task task) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AddTaskSheet(existingTask: task),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        opaque: false,
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFD93025);
      case TaskPriority.medium:
        return const Color(0xFFF9AB00);
      case TaskPriority.low:
        return const Color(0xFF1E8E3E);
    }
  }

  String _monthName(int month) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month];
  }
}