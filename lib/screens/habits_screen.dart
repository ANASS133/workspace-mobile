import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit_item.dart';
import '../services/sync_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_editor_sheet.dart';

class HabitsScreen extends StatefulWidget {
  final SyncManager syncManager;

  const HabitsScreen({super.key, required this.syncManager});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  bool _showArchived = false;

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static DateTime _mondayOfCurrentWeek() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Mon .. 7 = Sun
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
  }

  static String _dateKeyOffset(DateTime base, int dayOffset) {
    final dt = base.add(Duration(days: dayOffset));
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sm = widget.syncManager;
    final allHabits = sm.habitItems;
    final today = _todayKey();

    final activeHabits = allHabits.where((h) => !h.archived).toList();
    final archivedHabits = allHabits.where((h) => h.archived).toList();

    final currentList = _showArchived ? archivedHabits : activeHabits;

    // Daily summary
    final scheduledToday = activeHabits.where((h) => h.isScheduledOn(today)).toList();
    final doneToday = scheduledToday.where((h) => h.isCompletedOn(today)).toList();
    final progress = scheduledToday.isEmpty ? 0.0 : doneToday.length / scheduledToday.length;

    return RefreshIndicator(
      onRefresh: () => sm.syncNow(),
      color: AppTheme.flameOrange,
      backgroundColor: AppTheme.surfaceElevated,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Header Card
          _buildHeaderCard(context, scheduledToday.length, doneToday.length, progress),
          const SizedBox(height: 16),

          // Tab Selector & Add button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filter tabs
              Row(
                children: [
                  _buildTabChip(
                    label: 'Active (${activeHabits.length})',
                    isSelected: !_showArchived,
                    onTap: () => setState(() => _showArchived = false),
                  ),
                  const SizedBox(width: 8),
                  _buildTabChip(
                    label: 'Archived (${archivedHabits.length})',
                    isSelected: _showArchived,
                    onTap: () => setState(() => _showArchived = true),
                  ),
                ],
              ),
              // Add habit button
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  HabitEditorSheet.show(
                    context,
                    objectives: sm.objectives,
                    onSave: (habit) => sm.addHabit(habit),
                  );
                },
                icon: const Icon(Icons.add, size: 18, color: AppTheme.flameOrange),
                label: const Text(
                  'Add Habit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.flameOrange,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.flameOrange.withOpacity(0.12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Habit Cards List
          if (currentList.isEmpty)
            _buildEmptyState(context, _showArchived)
          else
            ...currentList.map((habit) => _buildHabitCard(context, habit, today, sm)),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, int totalScheduled, int totalDone, double progress) {
    final allDone = totalScheduled > 0 && totalDone == totalScheduled;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppTheme.isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'HABIT TRACKER',
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
                    'Daily Momentum 🔥',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              // Daily count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: allDone
                      ? AppTheme.successGreen.withOpacity(0.18)
                      : AppTheme.flameOrange.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: allDone
                        ? AppTheme.successGreen.withOpacity(0.4)
                        : AppTheme.flameOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      allDone ? Icons.check_circle : Icons.repeat,
                      size: 15,
                      color: allDone ? AppTheme.successGreen : AppTheme.flameOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      allDone
                          ? 'All Done! 🎉'
                          : totalScheduled == 0
                              ? 'No habits today'
                              : '$totalDone / $totalScheduled done',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: allDone ? AppTheme.successGreen : AppTheme.flameOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppTheme.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone ? AppTheme.successGreen : AppTheme.flameOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.surfaceBorder : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isArchived) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.flameOrange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.repeat, size: 36, color: AppTheme.flameOrange),
          ),
          const SizedBox(height: 14),
          Text(
            isArchived ? 'No archived habits' : 'No habits created yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isArchived
                ? 'Habits you archive will be kept safe here.'
                : 'Consistency compounds. Add your first habit today!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(
    BuildContext context,
    HabitItem habit,
    String today,
    SyncManager sm,
  ) {
    final isDoneToday = habit.isCompletedOn(today);
    final isScheduledToday = habit.isScheduledOn(today);
    final streak = habit.getStreak(today);
    final monday = _mondayOfCurrentWeek();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDoneToday
              ? AppTheme.successGreen.withOpacity(0.28)
              : AppTheme.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Check button + Habit Title + Streak badge + Popup Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Check / Action Button
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  sm.toggleHabitDay(habit.id, today);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDoneToday
                        ? AppTheme.successGreen
                        : !isScheduledToday
                            ? AppTheme.surfaceElevated
                            : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDoneToday
                          ? AppTheme.successGreen
                          : AppTheme.surfaceBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isDoneToday
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : !isScheduledToday
                            ? Text(
                                'Zz',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMuted,
                                ),
                              )
                            : Icon(
                                Icons.circle_outlined,
                                color: AppTheme.textMuted,
                                size: 18,
                              ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and frequency details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDoneToday ? AppTheme.textPrimary : AppTheme.textPrimary,
                        decoration: isDoneToday ? TextDecoration.lineThrough : null,
                        decorationColor: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          !isScheduledToday ? 'Rest day today' : habit.frequencyDescription,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: !isScheduledToday ? AppTheme.textMuted : AppTheme.flameOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (habit.objective != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.infoSky.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '🎯 Goal',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.infoSky),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: streak > 0
                      ? AppTheme.flameOrange.withOpacity(0.16)
                      : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: streak > 0
                        ? AppTheme.flameOrange.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      streak > 0 ? '🔥' : '⚡',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$streak',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: streak > 0 ? AppTheme.flameOrange : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Popup menu (Edit, Archive, Delete)
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert, size: 18, color: AppTheme.textMuted),
                onSelected: (action) {
                  if (action == 'edit') {
                    HabitEditorSheet.show(
                      context,
                      habit: habit,
                      objectives: sm.objectives,
                      onSave: (updated) => sm.updateHabit(updated),
                      onDelete: () => sm.deleteHabit(habit.id),
                    );
                  } else if (action == 'archive') {
                    sm.toggleArchiveHabit(habit.id);
                  } else if (action == 'delete') {
                    sm.deleteHabit(habit.id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(habit.archived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text(habit.archived ? 'Restore' : 'Archive', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: AppTheme.priorityHigh),
                        const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(fontSize: 13, color: AppTheme.priorityHigh)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Quantity Stepper (if kind == 'quantity')
          if (habit.kind == 'quantity') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily progress: ${habit.countOn(today)} / ${habit.target} ${habit.unit}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                        onPressed: () => sm.updateHabitQuantity(habit.id, today, -1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16, color: AppTheme.flameOrange),
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: EdgeInsets.zero,
                        onPressed: () => sm.updateHabitQuantity(habit.id, today, 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Divider(height: 1, thickness: 0.7, color: AppTheme.surfaceBorder),
          const SizedBox(height: 10),

          // 7-Day Interactive Week Heatmap Row (Monday to Sunday)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final dateKey = _dateKeyOffset(monday, i);
              final isDayScheduled = habit.isScheduledOn(dateKey);
              final isDayDone = habit.isCompletedOn(dateKey);
              final isDayToday = dateKey == today;
              final isFuture = dateKey.compareTo(today) > 0;

              const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final label = dayLabels[i];

              return InkWell(
                onTap: isFuture
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        sm.toggleHabitDay(habit.id, dateKey);
                      },
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isDayToday ? FontWeight.w800 : FontWeight.w600,
                        color: isDayToday ? AppTheme.flameOrange : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDayDone
                            ? AppTheme.successGreen
                            : !isDayScheduled
                                ? Colors.transparent
                                : isFuture
                                    ? AppTheme.surfaceElevated.withOpacity(0.4)
                                    : AppTheme.surfaceElevated,
                        border: Border.all(
                          color: isDayToday
                              ? AppTheme.flameOrange
                              : isDayDone
                                  ? AppTheme.successGreen
                                  : isDayScheduled
                                      ? AppTheme.surfaceBorder
                                      : AppTheme.surfaceBorder.withOpacity(0.3),
                          width: isDayToday ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: isDayDone
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : !isDayScheduled
                                ? Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.textMuted.withOpacity(0.3),
                                    ),
                                  )
                                : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
