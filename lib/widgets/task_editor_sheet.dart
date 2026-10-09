import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';

class TaskEditorSheet extends StatefulWidget {
  final TaskItem? initialTask;
  final String? defaultCategory;
  final Function(TaskItem) onSave;
  final VoidCallback? onDelete;

  const TaskEditorSheet({
    super.key,
    this.initialTask,
    this.defaultCategory,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    TaskItem? task,
    String? defaultCategory,
    required Function(TaskItem) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => TaskEditorSheet(
        initialTask: task,
        defaultCategory: defaultCategory,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late TextEditingController _titleController;
  late String _category;
  late String _priority;
  late String _recurrence;
  String? _dueDate;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTask;
    _titleController = TextEditingController(text: t?.text ?? '');
    _category = t?.category ?? widget.defaultCategory ?? 'din';
    _priority = t?.priority ?? 'medium';
    _recurrence = t?.recurrence ?? 'once';
    _dueDate = t?.dueDate ?? _todayStr();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _titleController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    final initial = widget.initialTask;
    final scheduleChanged = initial != null &&
        (initial.dueDate != _dueDate || initial.recurrence != _recurrence);
    final item = initial?.copyWith(
          text: text,
          category: _category,
          priority: _priority,
          recurrence: _recurrence,
          dueDate: _dueDate,
          // Desktop anchors weekly/monthly recurrences when their schedule is
          // edited. Keeping that same anchor prevents different "Today" sets.
          scheduleStart: scheduleChanged ? _dueDate : initial.scheduleStart,
          completedDates: scheduleChanged ? <String>[] : initial.completedDates,
        ) ??
        TaskItem(
          id: 'task_${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          category: _category,
          priority: _priority,
          recurrence: _recurrence,
          dueDate: _dueDate,
          scheduleStart: _dueDate,
        );

    widget.onSave(item);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTask != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Task' : 'New Task',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  if (isEditing && widget.onDelete != null)
                    IconButton(
                      onPressed: () {
                        widget.onDelete!();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_outline, color: AppTheme.priorityHigh, size: 22),
                      tooltip: 'Delete task',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Title textfield
              TextField(
                controller: _titleController,
                autofocus: !isEditing,
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  prefixIcon: Icon(Icons.edit_note, color: AppTheme.textMuted),
                  suffixIcon: _titleController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _titleController.clear(),
                        )
                      : null,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 18),
              // Category selector
              Text('Category Pillar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskCategoryMeta.all.map((c) {
                  final isSel = _category == c.id;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 13, color: isSel ? Colors.white : c.color),
                        const SizedBox(width: 5),
                        Text(c.shortTitle),
                      ],
                    ),
                    selected: isSel,
                    selectedColor: c.color,
                    backgroundColor: AppTheme.surfaceElevated,
                    side: BorderSide(color: isSel ? c.color : AppTheme.surfaceBorder),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? Colors.white : AppTheme.textPrimary,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _category = c.id);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              // Priority selector
              Text('Priority Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _priorityChip('high', 'High (Must)', AppTheme.priorityHigh),
                  const SizedBox(width: 8),
                  _priorityChip('medium', 'Medium', AppTheme.priorityMed),
                  const SizedBox(width: 8),
                  _priorityChip('low', 'Low', AppTheme.priorityLow),
                ],
              ),
              const SizedBox(height: 18),
              // Recurrence & Date row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recurrence', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _recurrence,
                              isExpanded: true,
                              dropdownColor: AppTheme.surfaceElevated,
                              items: const [
                                DropdownMenuItem(value: 'once', child: Text('Once', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'habit', child: Text('Daily Habit', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'weekly', child: Text('Weekly', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 'monthly', child: Text('Monthly', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _recurrence = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Due Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() {
                                _dueDate = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 8),
                                Text(
                                  _dueDate ?? 'Select date',
                                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Save button
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.flameOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Create Task',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityChip(String val, String label, Color color) {
    final isSel = _priority == val;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _priority = val),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? color.withOpacity(0.2) : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? color : AppTheme.surfaceBorder,
              width: isSel ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
              color: isSel ? color : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
