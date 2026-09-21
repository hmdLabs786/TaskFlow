import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/task.dart';
import '../models/sub_task.dart';
import '../providers/task_provider.dart';
import '../services/rich_text_helper.dart';
import '../services/smart_date_parser.dart';

class AddTaskSheet extends StatefulWidget {
  final Task? existingTask;

  const AddTaskSheet({super.key, this.existingTask});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _quillController = quill.QuillController.basic();
  final _quillFocus = FocusNode();
  final _titleFocus = FocusNode();

  TaskPriority _priority = TaskPriority.medium;
  String _category = 'General';
  DateTime? _dueDate;
  RecurrenceType _recurrence = RecurrenceType.none;
  final List<String> _attachmentPaths = [];
  final List<SubTask> _subtasks = [];
  bool _showRichEditor = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _titleController.text = task.title;
      _priority = task.priority;
      _category = task.category;
      _dueDate = task.dueDate;
      _recurrence = task.recurrence;
      _attachmentPaths.addAll(task.attachmentPaths);
      _subtasks.addAll(SubTask.listFromJson(task.subtasksJson));
      if (RichTextHelper.isRichText(task.note)) {
        _showRichEditor = true;
        try {
          _quillController.document =
              quill.Document.fromJson(jsonDecode(task.note) as List);
        } catch (_) {
          _notesController.text = task.note;
          _showRichEditor = false;
        }
      } else {
        _notesController.text = task.note;
      }
    }
    _titleController.addListener(_onTitleChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocus.requestFocus();
    });
  }

  void _onTitleChanged() {
    final text = _titleController.text;
    final parsedDate = SmartDateParser.parse(text);
    if (parsedDate != null && _dueDate == null) {
      setState(() {
        _dueDate = parsedDate;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _notesController.dispose();
    _quillController.dispose();
    _quillFocus.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_titleController.text.trim().isEmpty) return;

    String title = _titleController.text.trim();
    final smartDate = SmartDateParser.parse(title);
    if (smartDate != null && _dueDate == smartDate) {
      title = SmartDateParser.cleanTitle(title);
      if (title.isEmpty) title = _titleController.text.trim();
    }

    String note;
    if (_showRichEditor) {
      final delta = _quillController.document.toDelta().toJson();
      note = delta.isEmpty ? '' : jsonEncode(delta);
    } else {
      note = _notesController.text.trim();
    }
    final subtasksJson = SubTask.listToJson(_subtasks);

    final provider = context.read<TaskProvider>();
    if (widget.existingTask != null) {
      provider.updateTask(
        widget.existingTask!,
        title,
        note,
        priority: _priority,
        category: _category,
        dueDate: _dueDate,
        recurrence: _recurrence,
        attachmentPaths: _attachmentPaths,
        subtasksJson: subtasksJson,
      );
    } else {
      provider.addTask(
        title,
        note,
        priority: _priority,
        category: _category,
        dueDate: _dueDate,
        recurrence: _recurrence,
        attachmentPaths: _attachmentPaths,
        subtasksJson: subtasksJson,
      );
    }
    Navigator.pop(context);
  }

  void _toggleRichEditor() {
    setState(() {
      if (_showRichEditor) {
        _notesController.text = _quillController.document.toPlainText();
        _showRichEditor = false;
      } else {
        _quillController.document = quill.Document()
          ..insert(0, _notesController.text);
        _showRichEditor = true;
      }
    });
  }

  Widget _buildRichEditor(ColorScheme colorScheme) {
    final selectionStyle = _quillController.getSelectionStyle();
    final attrs = selectionStyle.attributes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Wrap(
          spacing: 18,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            _formatButtonGroup(
              colorScheme,
              'Text',
              [
                _richButton(
                  colorScheme,
                  Icons.text_fields_rounded,
                  'Bold',
                  quill.Attribute.bold,
                  attrs,
                  onFormat: () {
                    final isActive = attrs.containsKey(quill.Attribute.bold.key);
                    setState(() {
                      _quillController.formatSelection(
                        isActive ? quill.Attribute.clone(quill.Attribute.bold, null) : quill.Attribute.bold,
                      );
                    });
                  },
                ),
                _richButton(
                  colorScheme,
                  Icons.format_italic_rounded,
                  'Italic',
                  quill.Attribute.italic,
                  attrs,
                  onFormat: () {
                    final isActive = attrs.containsKey(quill.Attribute.italic.key);
                    setState(() {
                      _quillController.formatSelection(
                        isActive ? quill.Attribute.clone(quill.Attribute.italic, null) : quill.Attribute.italic,
                      );
                    });
                  },
                ),
                _richButton(
                  colorScheme,
                  Icons.format_underlined_rounded,
                  'Underline',
                  quill.Attribute.underline,
                  attrs,
                  onFormat: () {
                    final isActive = attrs.containsKey(quill.Attribute.underline.key);
                    setState(() {
                      _quillController.formatSelection(
                        isActive ? quill.Attribute.clone(quill.Attribute.underline, null) : quill.Attribute.underline,
                      );
                    });
                  },
                ),
                _richButton(
                  colorScheme,
                  Icons.format_strikethrough_rounded,
                  'Strikethrough',
                  quill.Attribute.strikeThrough,
                  attrs,
                  onFormat: () {
                    final isActive = attrs.containsKey(quill.Attribute.strikeThrough.key);
                    setState(() {
                      _quillController.formatSelection(
                        isActive ? quill.Attribute.clone(quill.Attribute.strikeThrough, null) : quill.Attribute.strikeThrough,
                      );
                    });
                  },
                ),
              ],
            ),
            _formatButtonGroup(
              colorScheme,
              'List',
              [
                _richButton(
                  colorScheme,
                  Icons.list_rounded,
                  'Bullet list',
                  quill.Attribute.ul,
                  attrs,
                  onFormat: () {
                    final isActive = attrs.containsKey(quill.Attribute.ul.key);
                    setState(() {
                      _quillController.formatSelection(
                        isActive ? quill.Attribute.clone(quill.Attribute.ul, null) : quill.Attribute.ul,
                      );
                    });
                  },
                ),
                _richButton(
                  colorScheme,
                  Icons.format_list_numbered_rounded,
                  'Numbered list',
                  quill.Attribute.ol,
                  attrs,
                  onFormat: () {
                    final isActive = attrs.containsKey(quill.Attribute.ol.key);
                    setState(() {
                      _quillController.formatSelection(
                        isActive ? quill.Attribute.clone(quill.Attribute.ol, null) : quill.Attribute.ol,
                      );
                    });
                  },
                ),
              ],
            ),
            _formatButtonGroup(
              colorScheme,
              'Insert',
              [
                _richButton(
                  colorScheme,
                  Icons.link_rounded,
                  'Link',
                  quill.Attribute.link,
                  attrs,
                  onFormat: () {
                    final isActive = attrs.containsKey(quill.Attribute.link.key);
                    setState(() {
                      _quillController.formatSelection(
                        isActive ? quill.Attribute.clone(quill.Attribute.link, null) : quill.Attribute.link,
                      );
                    });
                  },
                ),
              ],
            ),
            _historyButtons(colorScheme),
          ],
        ),
        const SizedBox(height: 2),
        Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(minHeight: 200, maxHeight: 260),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: quill.QuillEditor.basic(
            controller: _quillController,
            config: quill.QuillEditorConfig(
              padding: EdgeInsets.zero,
              autoFocus: false,
              placeholder: 'Add notes…',
              expands: true,
            ),
            focusNode: _quillFocus,
          ),
        ),
      ],
    );
  }

  Widget _formatButtonGroup(
    ColorScheme colorScheme,
    String label,
    List<Widget> buttons,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final b in buttons) ...[
              b,
              if (b != buttons.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _richButton(
    ColorScheme colorScheme,
    IconData icon,
    String tooltip,
    dynamic attr,
    Map attrs, {
    required VoidCallback onFormat,
  }) {
    final isActive = attrs.containsKey(attr.key);
    final activeColor = colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onFormat,
        radius: 18,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? activeColor.withOpacity(0.4)
                  : colorScheme.outline.withOpacity(0.12),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? activeColor : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _historyButtons(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _quillController.hasUndo
                  ? () => _quillController.undo()
                  : null,
              icon: const Icon(Icons.undo_rounded, size: 19),
              tooltip: 'Undo',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: _quillController.hasRedo
                  ? () => _quillController.redo()
                  : null,
              icon: const Icon(Icons.redo_rounded, size: 19),
              tooltip: 'Redo',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(picked.path)}';
      final savedFile = await File(picked.path).copy('${appDir.path}/$fileName');
      setState(() => _attachmentPaths.add(savedFile.path));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      for (final file in result.files) {
        if (file.path != null) {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path!)}';
          final savedFile = await File(file.path!).copy('${appDir.path}/$fileName');
          setState(() => _attachmentPaths.add(savedFile.path));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.existingTask != null;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              _buildHeader(colorScheme, isEditing),
              Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocus,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                        decoration: InputDecoration(
                          hintText: 'Title (try "tomorrow" or "next week")',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        ),
                        maxLines: null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _showRichEditor ? 'Rich text' : 'Notes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _toggleRichEditor,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _showRichEditor
                                    ? colorScheme.primary.withOpacity(0.1)
                                    : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showRichEditor
                                        ? Icons.format_color_text_rounded
                                        : Icons.notes_rounded,
                                    size: 14,
                                    color: _showRichEditor
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _showRichEditor ? 'Switch to plain' : 'Format',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _showRichEditor
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_showRichEditor)
                        _buildRichEditor(colorScheme)
                      else
                        TextField(
                          controller: _notesController,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Add notes',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          maxLines: null,
                          minLines: 3,
                        ),
                      if (_subtasks.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSubtasksSection(colorScheme),
                      ],
                      if (_attachmentPaths.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildAttachmentPreview(colorScheme),
                      ],
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: colorScheme.outline.withOpacity(0.3)),
              _buildBottomToolbar(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, bool isEditing) {
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
            isEditing ? 'Edit task' : 'New task',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _saveTask,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtasksSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subtasks',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_subtasks.length, (index) {
          final sub = _subtasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => sub.isCompleted = !sub.isCompleted);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: sub.isCompleted ? colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sub.isCompleted ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        width: 2,
                      ),
                    ),
                    child: sub.isCompleted
                        ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: sub.title),
                    onChanged: (val) => sub.title = val,
                    style: TextStyle(
                      fontSize: 15,
                      decoration: sub.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      color: sub.isCompleted ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Subtask',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => setState(() => _subtasks.removeAt(index)),
                ),
              ],
            ),
          );
        }),
        InkWell(
          onTap: () {
            setState(() => _subtasks.add(SubTask(title: '')));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.add_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Add subtask',
                  style: TextStyle(fontSize: 14, color: colorScheme.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentPreview(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _attachmentPaths.asMap().entries.map((entry) {
            final index = entry.key;
            final path = entry.value;
            final isImage = path.toLowerCase().endsWith('.jpg') ||
                path.toLowerCase().endsWith('.jpeg') ||
                path.toLowerCase().endsWith('.png');

            return Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
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
                            Text(
                              p.basename(path),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => setState(() => _attachmentPaths.removeAt(index)),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomToolbar(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        4,
        8,
        MediaQuery.of(context).padding.bottom + 4,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolbarButton(
              icon: Icons.add_circle_outline_rounded,
              tooltip: 'Add subtask',
              colorScheme: colorScheme,
              onPressed: () {
                setState(() => _subtasks.add(SubTask(title: '')));
              },
            ),
            _toolbarButton(
              icon: Icons.calendar_today_rounded,
              tooltip: 'Set date',
              colorScheme: colorScheme,
              isActive: _dueDate != null,
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            _toolbarButton(
              icon: Icons.flag_outlined,
              tooltip: 'Priority',
              colorScheme: colorScheme,
              isActive: _priority != TaskPriority.medium,
              onPressed: () => _showPrioritySheet(colorScheme),
            ),
            _toolbarButton(
              icon: Icons.label_outline_rounded,
              tooltip: 'List',
              colorScheme: colorScheme,
              isActive: _category != 'General',
              onPressed: () => _showCategorySheet(colorScheme),
            ),
            _toolbarButton(
              icon: Icons.photo_camera_back_rounded,
              tooltip: 'Image',
              colorScheme: colorScheme,
              isActive: _attachmentPaths.isNotEmpty,
              onPressed: () => _showAttachSheet(colorScheme),
            ),
            _toolbarButton(
              icon: Icons.repeat_rounded,
              tooltip: 'Repeat',
              colorScheme: colorScheme,
              isActive: _recurrence != RecurrenceType.none,
              onPressed: () => _showRecurrenceSheet(colorScheme),
            ),
            if (_dueDate != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _dueDate = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_monthName(_dueDate!.month)} ${_dueDate!.day}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.close, size: 14, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String tooltip,
    required ColorScheme colorScheme,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 22,
        color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      tooltip: tooltip,
      padding: const EdgeInsets.all(10),
    );
  }

  void _showPrioritySheet(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Priority', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...TaskPriority.values.map((p) => ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(p),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                  trailing: _priority == p
                      ? Icon(Icons.check_rounded, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _priority = p);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(ColorScheme colorScheme) {
    const categories = ['General', 'Work', 'Personal', 'Urgent'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...categories.map((c) => ListTile(
                  title: Text(c),
                  trailing: _category == c
                      ? Icon(Icons.check_rounded, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _category = c);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRecurrenceSheet(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Repeat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...RecurrenceType.values.map((r) => ListTile(
                  leading: Icon(
                    r == RecurrenceType.none ? Icons.cancel_outlined : Icons.repeat_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(r.name[0].toUpperCase() + r.name.substring(1)),
                  trailing: _recurrence == r
                      ? Icon(Icons.check_rounded, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _recurrence = r);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAttachSheet(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Attach', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_rounded),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFile();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
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
