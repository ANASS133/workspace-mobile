import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';

class TaskTile extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool? isCompleted;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    this.onDelete,
    this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final meta = task.categoryMeta;
    final isDone = isCompleted ?? task.completed;

    Color priorityColor;
    switch (task.priorityEnum) {
      case TaskPriority.high:
        priorityColor = AppTheme.priorityHigh;
        break;
      case TaskPriority.low:
        priorityColor = AppTheme.priorityLow;
        break;
      default:
        priorityColor = AppTheme.priorityMed;
    }

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppTheme.priorityHigh.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.priorityHigh),
      ),
      confirmDismiss: (dir) async {
        HapticFeedback.lightImpact();
        if (onDelete != null) {
          onDelete!();
          return false; // Handled by onDelete
        }
        return true;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isDone ? AppTheme.surface.withOpacity(0.6) : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone ? AppTheme.surfaceBorder.withOpacity(0.5) : AppTheme.surfaceBorder,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Custom check button
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onToggle();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDone ? meta.color : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: isDone ? meta.color : AppTheme.textMuted.withOpacity(0.5),
                        width: 1.8,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Task details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.text,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDone ? AppTheme.textMuted : AppTheme.textPrimary,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: meta.color.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(meta.icon, size: 10, color: meta.color),
                                const SizedBox(width: 4),
                                Text(
                                  meta.shortTitle,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: meta.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Priority dot
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: priorityColor,
                              ),
                            ),
                          ),
                          // Recurrence
                          if (task.recurrence != 'once')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.repeat, size: 10, color: AppTheme.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(
                                    task.recurrence == 'habit' ? 'Daily' : task.recurrence,
                                    style: TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          // Due Date
                          if (task.dueDate != null && task.dueDate!.isNotEmpty)
                            Text(
                              task.dueDate!,
                              style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
