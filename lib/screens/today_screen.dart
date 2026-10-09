import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../services/sync_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/pomodoro_timer_widget.dart';
import '../widgets/task_tile.dart';
import '../widgets/task_editor_sheet.dart';

class TodayScreen extends StatefulWidget {
  final SyncManager syncManager;

  const TodayScreen({super.key, required this.syncManager});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _showTimer = false;

  @override
  Widget build(BuildContext context) {
    final sm = widget.syncManager;
    final todayTasks = sm.todayTasks;
    final totalCount = todayTasks.length;
    final completedCount = sm.completedTodayCount;
    final overdueCount = sm.overdueCount;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final progressPercent = (progress * 100).toInt();

    final mustDoTasks = todayTasks.where((t) => t.priorityEnum == TaskPriority.high).toList();
    final shouldDoTasks = todayTasks.where((t) => t.priorityEnum == TaskPriority.medium).toList();
    final optionalTasks = todayTasks.where((t) => t.priorityEnum == TaskPriority.low).toList();

    final nowStr = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () => sm.syncNow(),
      color: AppTheme.flameOrange,
      backgroundColor: AppTheme.surfaceElevated,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Greeting & Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'TODAY OVERVIEW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppTheme.flameOrange,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.flameOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hello, Anass 🔥',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    nowStr,
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.flameOrange.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.flameOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: AppTheme.flameOrange, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${sm.streakDays}-Day',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.flameOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daily Stats Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('Tasks Today', '$totalCount', AppTheme.infoSky),
                    _statItem('Completed', '$completedCount', AppTheme.successGreen),
                    _statItem('Overdue', '$overdueCount', AppTheme.priorityHigh),
                    _statItem('Progress', '$progressPercent%', AppTheme.flameOrange),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.surfaceElevated,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.flameOrange),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Focus Timer Toggle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Focus / Pomodoro Timer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showTimer = !_showTimer);
                },
                icon: Icon(
                  _showTimer ? Icons.keyboard_arrow_up : Icons.timer_outlined,
                  size: 16,
                  color: AppTheme.flameOrange,
                ),
                label: Text(
                  _showTimer ? 'Hide Timer' : 'Open Timer',
                  style: const TextStyle(fontSize: 12, color: AppTheme.flameOrange, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          if (_showTimer) ...[
            const PomodoroTimerWidget(),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 10),

          // Priority Section: MUST DO (High)
          _prioritySection(
            title: 'Must Do',
            badge: 'NON-NEGOTIABLE',
            dotColor: AppTheme.priorityHigh,
            tasks: mustDoTasks,
            defaultPriority: 'high',
          ),
          const SizedBox(height: 18),

          // Priority Section: SHOULD DO (Medium)
          _prioritySection(
            title: 'Should Do',
            badge: 'IMPORTANT',
            dotColor: AppTheme.priorityMed,
            tasks: shouldDoTasks,
            defaultPriority: 'medium',
          ),
          const SizedBox(height: 18),

          // Priority Section: OPTIONAL (Low)
          _prioritySection(
            title: 'Optional',
            badge: 'BONUS',
            dotColor: AppTheme.priorityLow,
            tasks: optionalTasks,
            defaultPriority: 'low',
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _prioritySection({
    required String title,
    required String badge,
    required Color dotColor,
    required List<TaskItem> tasks,
    required String defaultPriority,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: dotColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: dotColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline, size: 20, color: AppTheme.textSecondary),
              tooltip: 'Add to $title',
              onPressed: () {
                TaskEditorSheet.show(
                  context,
                  task: TaskItem(
                    id: 'task_${DateTime.now().millisecondsSinceEpoch}',
                    text: '',
                    category: 'din',
                    priority: defaultPriority,
                    recurrence: 'habit',
                    dueDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  ),
                  onSave: (t) => widget.syncManager.addTask(t),
                );
              },
            ),
          ],
        ),
        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceBorder.withOpacity(0.4), style: BorderStyle.solid),
            ),
            child: Text(
              'No $title tasks for today',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          )
        else
          ...tasks.map(
            (t) => TaskTile(
              task: t,
              isCompleted: widget.syncManager.completedOn(t, DateFormat('yyyy-MM-dd').format(DateTime.now())),
              onToggle: () => widget.syncManager.toggleTask(t),
              onTap: () {
                TaskEditorSheet.show(
                  context,
                  task: t,
                  onSave: (updated) => widget.syncManager.updateTask(updated),
                  onDelete: () => widget.syncManager.deleteTask(t),
                );
              },
              onDelete: () => widget.syncManager.deleteTask(t),
            ),
          ),
      ],
    );
  }
}
