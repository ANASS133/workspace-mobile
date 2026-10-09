import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/workout_models.dart';
import '../services/sync_manager.dart';
import '../theme/app_theme.dart';

class TrainingScreen extends StatefulWidget {
  final SyncManager syncManager;

  const TrainingScreen({super.key, required this.syncManager});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late WorkoutDay _selectedDay;
  final Map<String, Set<int>> _completedSets = {}; // exerciseId -> completed set indices
  int _stopwatchSeconds = 0;
  bool _isWorkoutActive = false;
  Timer? _stopwatchTimer;

  // Rest timer
  int _restSecondsRemaining = 0;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _selectedDay = CalisthenicsProgram.getDayForDateTime(DateTime.now());
    _loadFromSyncManager();
  }

  void _loadFromSyncManager() {
    final setsRaw = widget.syncManager.activeSession['completedSets'];
    if (setsRaw is Map) {
      setsRaw.forEach((k, v) {
        if (v is List) {
          _completedSets[k.toString()] = v.map((e) => (e as num).toInt()).toSet();
        }
      });
    }
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  void _toggleStopwatch() {
    HapticFeedback.mediumImpact();
    if (_isWorkoutActive) {
      _stopwatchTimer?.cancel();
      setState(() => _isWorkoutActive = false);
    } else {
      setState(() => _isWorkoutActive = true);
      _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _stopwatchSeconds++);
      });
    }
  }

  void _startRestTimer(int seconds) {
    HapticFeedback.lightImpact();
    _restTimer?.cancel();
    setState(() => _restSecondsRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        setState(() => _restSecondsRemaining--);
      } else {
        timer.cancel();
        HapticFeedback.vibrate();
      }
    });
  }

  String get _formatStopwatch {
    final m = (_stopwatchSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_stopwatchSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final todayWeekday = DateTime.now().weekday;

    int totalSetsInDay = 0;
    int completedSetsInDay = 0;
    for (final ex in _selectedDay.exercises) {
      totalSetsInDay += ex.sets;
      completedSetsInDay += (_completedSets[ex.id]?.length ?? 0);
    }
    final workoutProgress = totalSetsInDay == 0 ? 0.0 : completedSetsInDay / totalSetsInDay;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('CALISTHENICS COACH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppTheme.trainColor)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.trainColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('🌅 Post-Fajr', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.trainColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedDay.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            // Stopwatch badge
            InkWell(
              onTap: _toggleStopwatch,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isWorkoutActive ? AppTheme.trainColor.withOpacity(0.2) : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isWorkoutActive ? AppTheme.trainColor : AppTheme.surfaceBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isWorkoutActive ? Icons.pause : Icons.timer,
                      size: 16,
                      color: _isWorkoutActive ? AppTheme.trainColor : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatStopwatch,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isWorkoutActive ? AppTheme.trainColor : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Day of week selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: CalisthenicsProgram.weeklyProgram.map((day) {
              final isSelected = _selectedDay.id == day.id;
              final isToday = day.dayIndex == todayWeekday;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDay = day);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.trainColor : AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppTheme.trainColor : (isToday ? AppTheme.trainColor.withOpacity(0.5) : AppTheme.surfaceBorder),
                        width: isToday ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          day.dayName.substring(0, 3).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : (isToday ? AppTheme.trainColor : AppTheme.textMuted),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          day.type == 'workout' ? Icons.fitness_center : Icons.self_improvement,
                          size: 16,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Focus & Overview Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'FOCUS: ${_selectedDay.focus}',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$completedSetsInDay / $totalSetsInDay sets',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.trainColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: workoutProgress,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.trainColor),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),

        // Quick Rest Timer Row
        if (_restSecondsRemaining > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.flameOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.flameOrange.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hourglass_top, size: 16, color: AppTheme.flameOrange),
                    const SizedBox(width: 8),
                    Text('Resting:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  ],
                ),
                Text(
                  '${_restSecondsRemaining}s',
                  style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.flameOrange),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                  onPressed: () {
                    _restTimer?.cancel();
                    setState(() => _restSecondsRemaining = 0);
                  },
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Exercises list
        ..._selectedDay.exercises.map((exercise) {
          final completed = _completedSets[exercise.id] ?? <int>{};

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.trainColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exercise.targetSummary,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.trainColor),
                      ),
                    ),
                  ],
                ),
                if (exercise.note != null && exercise.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    exercise.note!,
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                  ),
                ],
                const SizedBox(height: 12),

                // Set checkmarks
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(exercise.sets, (index) {
                            final setNum = index + 1;
                            final isDone = completed.contains(setNum);

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  final set = _completedSets.putIfAbsent(exercise.id, () => <int>{});
                                  final bool willBeDone = !set.contains(setNum);
                                  setState(() {
                                    if (willBeDone) {
                                      set.add(setNum);
                                      _startRestTimer(60);
                                    } else {
                                      set.remove(setNum);
                                    }
                                  });
                                  widget.syncManager.updateActiveSessionSet(exercise.id, setNum, willBeDone);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 44,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDone ? AppTheme.trainColor : AppTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDone ? AppTheme.trainColor : AppTheme.surfaceBorder,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'S$setNum',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDone ? Colors.white : AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rest button quick trigger
                    InkWell(
                      onTap: () => _startRestTimer(90),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 12, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text('90s rest', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            final now = DateTime.now();
            final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

            widget.syncManager.recordCompletedWorkout({
              'id': 'sess_${now.millisecondsSinceEpoch}',
              'date': dateStr,
              'dayKey': _selectedDay.id,
              'durationSeconds': _stopwatchSeconds,
              'completedSets': completedSetsInDay,
              'timestamp': now.toIso8601String(),
            });

            setState(() {
              _completedSets.clear();
              _isWorkoutActive = false;
              _stopwatchSeconds = 0;
            });
            _stopwatchTimer?.cancel();

            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.emoji_events, color: AppTheme.flameOrange),
                    SizedBox(width: 8),
                    Text('Session Complete!'),
                  ],
                ),
                content: Text(
                  'Great job! You executed $completedSetsInDay sets for ${_selectedDay.title}. Synced to cloud and recorded in training history.',
                  style: const TextStyle(fontSize: 13.5),
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.flameOrange),
                    child: const Text('Awesome'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Complete Workout Session'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.trainColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}
