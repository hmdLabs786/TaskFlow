import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task.dart';
import '../models/task_template.dart';
import '../models/sub_task.dart';
import '../providers/task_provider.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_drawer.dart';
import 'add_task_screen.dart';
import 'pomodoro_screen.dart';
import 'task_detail_screen.dart';
import 'attachment_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  static const _categories = ['All', 'Work', 'Personal', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      context.read<TaskProvider>().setCategory(_categories[_tabController.index]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _buildTopBar(colorScheme),
          ),
          _buildTabBar(colorScheme),
          Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, _) {
                final tasks = provider.tasks;
                if (tasks.isEmpty) {
                  return _buildEmptyState(colorScheme);
                }
                return _buildTaskList(tasks, provider, colorScheme);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          if (provider.multiSelectMode) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () => _openAddTask(),
            tooltip: 'Add task',
            child: const Icon(Icons.add_rounded, size: 28),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(ColorScheme colorScheme) {
    final provider = context.watch<TaskProvider>();

    if (provider.multiSelectMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => provider.exitMultiSelect(),
            ),
            Text(
              '${provider.selectedCount} selected',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.select_all_rounded),
              tooltip: 'Select all',
              onPressed: () => provider.selectAll(),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded),
              tooltip: 'Complete selected',
              onPressed: () {
                provider.completeSelected();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selected tasks completed')),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
              tooltip: 'Delete selected',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    title: const Text('Delete tasks?'),
                    content: Text('${provider.selectedCount} tasks will be permanently deleted.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.deleteSelected();
                          Navigator.pop(ctx);
                        },
                        child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          if (_isSearching)
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) {
                  context.read<TaskProvider>().setSearchQuery(val);
                },
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search tasks',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      context.read<TaskProvider>().setSearchQuery('');
                      setState(() => _isSearching = false);
                    },
                  ),
                ),
              ),
            )
          else ...[
            const Expanded(
              child: Text(
                'Tasks',
                style: TextStyle(fontSize: 22),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(Icons.timer_outlined, size: 22),
              tooltip: 'Pomodoro',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const PomodoroScreen(),
                ));
              },
            ),
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_outlined,
                size: 22,
              ),
              onPressed: () => context.read<ThemeController>().toggleThemeMode(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3,
        indicatorColor: colorScheme.primary,
        dividerHeight: 0,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: _categories.map((c) => Tab(text: c)).toList(),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, TaskProvider provider, ColorScheme colorScheme) {
    final pending = tasks.where((t) => !t.isCompleted).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();

    final pinned = pending.where((t) => t.isPinned).toList();
    final unpinned = pending.where((t) => !t.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        if (pinned.isNotEmpty) ...[
          _buildSectionHeader('Pinned', colorScheme),
          ...List.generate(pinned.length, (i) => _buildTaskItem(pinned[i], provider, colorScheme, i)),
        ],
        if (unpinned.isNotEmpty) ...[
          _buildSectionHeader('Tasks', colorScheme),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: unpinned.length,
            onReorder: (oldIndex, newIndex) {
              provider.reorderTask(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              return _buildTaskItem(unpinned[index], provider, colorScheme, index);
            },
          ),
        ],
        if (completed.isNotEmpty) ...[
          _buildSectionHeader('Completed', colorScheme),
          ...completed.map((t) => _buildTaskItem(t, provider, colorScheme, 0)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    final provider = context.watch<TaskProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz_rounded, size: 20, color: colorScheme.onSurfaceVariant),
            onSelected: (value) {
              if (value == 'templates') _showTemplatesSheet(colorScheme);
              if (value == 'export') _exportTasks();
              if (value == 'import') _importTasks();
              if (value == 'sort_priority') provider.setSortBy('Priority');
              if (value == 'sort_date') provider.setSortBy('Due Date');
              if (value == 'sort_manual') provider.setSortBy('Manual');
              if (value == 'multi_select') provider.toggleMultiSelect();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'templates', child: Text('Templates')),
              const PopupMenuItem(value: 'export', child: Text('Export tasks')),
              const PopupMenuItem(value: 'import', child: Text('Import tasks')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'sort_manual', child: Text('Sort: Manual')),
              const PopupMenuItem(value: 'sort_priority', child: Text('Sort: Priority')),
              const PopupMenuItem(value: 'sort_date', child: Text('Sort: Due date')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'multi_select', child: Text('Multi-select')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task, TaskProvider provider, ColorScheme colorScheme, int index) {
    final isCompleted = task.isCompleted;
    final isSelected = provider.multiSelectMode && provider.selectedTaskIds.contains(task.id);
    final subtasks = SubTask.listFromJson(task.subtasksJson);
    final subtasksDone = subtasks.where((s) => s.isCompleted).length;

    return Dismissible(
      key: Key(task.id),
      direction: provider.multiSelectMode ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: colorScheme.error,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: const Text('Delete task?'),
            content: Text('"${task.title}" will be permanently deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete', style: TextStyle(color: colorScheme.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        provider.deleteTask(task);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Task deleted'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: colorScheme.primary,
              onPressed: () {
                provider.addTask(
                  task.title,
                  task.note,
                  priority: task.priority,
                  category: task.category,
                  dueDate: task.dueDate,
                  recurrence: task.recurrence,
                  attachmentPaths: task.attachmentPaths,
                  subtasksJson: task.subtasksJson,
                );
              },
            ),
          ),
        );
      },
      child: Material(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.12)
            : Colors.transparent,
        child: InkWell(
          onTap: () {
            if (provider.multiSelectMode) {
              provider.toggleTaskSelection(task.id);
              return;
            }
            _openTaskDetail(task);
          },
          onLongPress: () {
            if (!provider.multiSelectMode) {
              provider.toggleMultiSelect();
              provider.toggleTaskSelection(task.id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.multiSelectMode) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 1, right: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: _GoogleCheckbox(
                      value: isCompleted,
                      color: _getPriorityColor(task.priority),
                      onChanged: (_) => provider.toggleTaskStatus(task, context),
                    ),
                  ),
                ],
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (task.isPinned && !provider.multiSelectMode) ...[
                            Icon(Icons.push_pin_rounded, size: 14, color: colorScheme.primary),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: isCompleted
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (subtasks.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.checklist_rounded, size: 14, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Text(
                              '$subtasksDone/${subtasks.length} subtasks',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (task.dueDate != null || task.category != 'General' || task.attachmentPaths.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (task.dueDate != null)
                              _dateChip(
                                '${_monthName(task.dueDate!.month)} ${task.dueDate!.day}',
                                colorScheme,
                                isOverdue: task.dueDate!.isBefore(DateTime.now()) && !isCompleted,
                              ),
                            if (task.category != 'General')
                              _dateChip(task.category, colorScheme),
                            if (task.attachmentPaths.isNotEmpty)
                              _attachmentChip(colorScheme, onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AttachmentViewerScreen(
                                      attachmentPaths: task.attachmentPaths,
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!provider.multiSelectMode)
                  Icon(
                    Icons.drag_handle_rounded,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateChip(String label, ColorScheme colorScheme, {bool isOverdue = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOverdue
            ? colorScheme.error.withOpacity(0.1)
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
          fontWeight: isOverdue ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _attachmentChip(ColorScheme colorScheme, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file_rounded,
              size: 13,
              color: colorScheme.primary.withOpacity(0.8),
            ),
            const SizedBox(width: 2),
            Text(
              'file',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 72,
            color: colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 20,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a new task',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _openAddTask() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AddTaskSheet(),
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

  void _openTaskDetail(Task task) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => TaskDetailScreen(task: task),
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

  void _showTemplatesSheet(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TemplatesSheet(colorScheme: colorScheme),
    );
  }

  Future<void> _exportTasks() async {
    final provider = context.read<TaskProvider>();
    final tasks = provider.tasks;
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks to export')),
      );
      return;
    }
    try {
      final result = await ExportService.exportTasks(tasks);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tasks exported successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importTasks() async {
    try {
      final data = await ExportService.importTasks();
      if (data == null) return;
      final provider = context.read<TaskProvider>();
      for (final item in data) {
        final task = ExportService.taskFromImport(item);
        provider.addTask(task.title, task.note,
          priority: task.priority,
          category: task.category,
          dueDate: task.dueDate,
          recurrence: task.recurrence,
          subtasksJson: task.subtasksJson,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${data.length} tasks')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
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

class _GoogleCheckbox extends StatelessWidget {
  final bool value;
  final Color color;
  final ValueChanged<bool?>? onChanged;

  const _GoogleCheckbox({
    required this.value,
    required this.color,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: value ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: value ? color : colorScheme.onSurfaceVariant,
            width: 2,
          ),
        ),
        child: value
            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}

class _TemplatesSheet extends StatefulWidget {
  final ColorScheme colorScheme;
  const _TemplatesSheet({required this.colorScheme});

  @override
  State<_TemplatesSheet> createState() => _TemplatesSheetState();
}

class _TemplatesSheetState extends State<_TemplatesSheet> {
  List<TaskTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() {
    setState(() => _templates = TaskTemplate.getAll());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text('Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _showCreateTemplate(),
                ),
              ],
            ),
          ),
          if (_templates.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.dashboard_customize_rounded, size: 48,
                      color: widget.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text('No templates yet',
                      style: TextStyle(color: widget.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('Create reusable task templates',
                      style: TextStyle(fontSize: 12, color: widget.colorScheme.onSurfaceVariant.withOpacity(0.6))),
                ],
              ),
            )
          else
            ..._templates.map((t) => ListTile(
              leading: Icon(Icons.dashboard_customize_rounded,
                  color: widget.colorScheme.primary),
              title: Text(t.name),
              subtitle: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                    onPressed: () {
                      context.read<TaskProvider>().addTaskFromTemplate(
                        t.title, '', t.subtasksJson,
                        category: t.category,
                        priority: TaskPriority.values[t.priorityIndex],
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Task created from "${t.name}"')),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, size: 20,
                        color: widget.colorScheme.error.withOpacity(0.7)),
                    onPressed: () async {
                      await TaskTemplate.delete(t.id);
                      _loadTemplates();
                    },
                  ),
                ],
              ),
            )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCreateTemplate() {
    final nameController = TextEditingController();
    final titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Template', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Template name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Task title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty || titleController.text.trim().isEmpty) return;
                  final template = TaskTemplate(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    title: titleController.text.trim(),
                  );
                  await TaskTemplate.save(template);
                  _loadTemplates();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExportService {
  static Future<bool> exportTasks(List<Task> tasks) async {
    final file = await _getExportFile();
    final data = tasks.map((t) => {
      'id': t.id, 'title': t.title, 'note': t.note,
      'isCompleted': t.isCompleted, 'priority': t.priority.index,
      'category': t.category, 'dueDate': t.dueDate?.toIso8601String(),
      'recurrence': t.recurrence.index, 'subtasksJson': t.subtasksJson,
      'orderIndex': t.orderIndex,
    }).toList();
    final json = const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 1,
      'tasks': data,
    });
    await file.writeAsString(json);
    return true;
  }

  static Future<List<Map<String, dynamic>>?> importTasks() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.isEmpty) return null;
    final file = File(result.files.first.path!);
    final jsonStr = await file.readAsString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (json['tasks'] == null) return null;
    return (json['tasks'] as List).cast<Map<String, dynamic>>();
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

  static Future<File> _getExportFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/taskflow_backup_${DateTime.now().millisecondsSinceEpoch}.json');
  }
}
