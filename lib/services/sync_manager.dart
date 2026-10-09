import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/task_item.dart';
import '../models/objective_item.dart';
import '../models/habit_item.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

enum SyncStatus { synced, syncing, offline, error }

class SyncManager extends ChangeNotifier {
  final StorageService storage;
  final SupabaseService supabase;

  Map<String, List<TaskItem>> _tasks = {};
  DashboardObjectives _objectives = DashboardObjectives();
  List<String> _productivityDates = [];
  int _nofapStartTime = 0;
  List<String> _nofapHistory = [];
  Map<String, bool> _academyProgress = {};
  Map<String, dynamic> _activeSession = {};
  List<dynamic> _trainingHistory = [];
  List<dynamic> _habits = [];
  Map<String, dynamic> _deletedTasks = {};
  Map<String, dynamic> _deletedObjectives = {};
  Map<String, dynamic> _deletedHabits = {};
  SyncStatus _syncStatus = SyncStatus.synced;
  DateTime? _lastSyncTime;
  String? _lastError;
  Timer? _periodicTimer;
  Future<void>? _activeSyncFuture;
  bool _pendingSyncQueued = false;
  static const _categoryOrder = ['lang', 'cyber', 'train', 'din', 'work', 'proj'];

  SyncManager({
    required this.storage,
    required this.supabase,
  }) {
    _loadFromLocal();
    supabase.startRealtime(_syncFromRealtime);
    syncNow();
    // Realtime is the immediate path. This is a recovery path for networks
    // that temporarily block WebSockets.
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_syncStatus != SyncStatus.syncing) {
        syncNow();
      }
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    supabase.dispose();
    super.dispose();
  }

  // Getters
  Map<String, List<TaskItem>> get tasks => _tasks;
  DashboardObjectives get objectives => _objectives;
  List<String> get productivityDates => _productivityDates;
  int get nofapStartTime => _nofapStartTime;
  List<String> get nofapHistory => _nofapHistory;
  Map<String, bool> get academyProgress => _academyProgress;
  Map<String, dynamic> get activeSession => _activeSession;
  List<dynamic> get trainingHistory => _trainingHistory;
  List<dynamic> get habits => _habits;
  List<HabitItem> get habitItems {
    return _habits.map((h) {
      if (h is HabitItem) return h;
      if (h is Map) return HabitItem.fromJson(Map<String, dynamic>.from(h));
      return null;
    }).whereType<HabitItem>().toList();
  }
  Map<String, dynamic> get deletedHabits => _deletedHabits;
  SyncStatus get syncStatus => _syncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;

  List<TaskItem> get allTasks {
    final list = <TaskItem>[];
    for (final category in _categoryOrder) {
      list.addAll(_tasks[category] ?? const <TaskItem>[]);
    }
    // Preserve unknown legacy categories without changing their stored data.
    _tasks.forEach((category, tasks) {
      if (!_categoryOrder.contains(category)) list.addAll(tasks);
    });
    return list;
  }

  List<TaskItem> get todayTasks {
    final today = _formatDate(DateTime.now());
    return allTasks.where((t) {
      return occursOn(t, today) || (t.recurrence == 'habit' && (t.dueDate == null || t.dueDate!.isEmpty));
    }).toList();
  }

  int get completedTodayCount {
    final today = _formatDate(DateTime.now());
    return todayTasks.where((t) => completedOn(t, today)).length;
  }

  int get overdueCount {
    final today = _formatDate(DateTime.now());
    return allTasks.where((t) {
      if (t.completed) return false;
      if (t.recurrence == 'habit') return false;
      if (t.dueDate == null) return false;
      return t.dueDate!.compareTo(today) < 0;
    }).length;
  }

  int get streakDays {
    if (_productivityDates.isEmpty) return 0;
    final sorted = List<String>.from(_productivityDates)..sort();
    final today = _formatDate(DateTime.now());
    final yesterday = _formatDate(DateTime.now().subtract(const Duration(days: 1)));

    if (!sorted.contains(today) && !sorted.contains(yesterday)) {
      return 0;
    }

    int count = 0;
    DateTime check = sorted.contains(today) ? DateTime.now() : DateTime.now().subtract(const Duration(days: 1));

    while (sorted.contains(_formatDate(check))) {
      count++;
      check = check.subtract(const Duration(days: 1));
    }
    return count;
  }

  void _loadFromLocal() {
    _deletedTasks = storage.loadDeletedTasks();
    _deletedObjectives = storage.loadDeletedObjectives();
    _deletedHabits = storage.loadDeletedHabits();
    _tasks = _deduplicateMap(storage.loadTasks());
    // Prune any locally stored tasks that match tombstones by ID only
    _tasks.forEach((cat, list) {
      list.removeWhere((t) => _deletedTasks.containsKey(t.id));
    });
    _objectives = storage.loadObjectives();
    _pruneDeletedObjectives();
    _productivityDates = storage.loadProductivityDates();
    _nofapStartTime = storage.loadNofapStartTime();
    _nofapHistory = storage.loadNofapHistory();
    _academyProgress = storage.loadAcademyProgress();
    _activeSession = storage.loadActiveSession();
    _trainingHistory = storage.loadTrainingHistory();
    _habits = storage.loadHabits();
    _pruneDeletedHabits();
    final lastSyncStr = storage.getLastSyncTime();
    if (lastSyncStr != null) {
      _lastSyncTime = DateTime.tryParse(lastSyncStr);
    }
    notifyListeners();
  }

  void _pruneDeletedHabits() {
    _habits.removeWhere((h) {
      final id = (h is Map) ? h['id']?.toString() : (h is HabitItem ? h.id : null);
      return id != null && _deletedHabits.containsKey(id);
    });
  }

  Map<String, List<TaskItem>> _deduplicateMap(Map<String, List<TaskItem>> input) {
    final result = <String, List<TaskItem>>{};
    input.forEach((cat, list) {
      final seen = <String, TaskItem>{};
      for (final t in list) {
        final norm = t.text.trim().toLowerCase();
        if (norm.isEmpty) continue;
        if (!seen.containsKey(norm)) {
          seen[norm] = t;
        } else if (t.updatedAt > seen[norm]!.updatedAt) {
          seen[norm] = t;
        }
      }
      result[cat] = seen.values.toList();
    });
    return result;
  }

  bool occursOn(TaskItem task, String date) {
    final dueDate = task.dueDate;
    if (dueDate == null || dueDate.isEmpty) return false;
    if (task.recurrence == 'once') return date == dueDate;
    final start = task.scheduleStart?.isNotEmpty == true ? task.scheduleStart! : dueDate;
    if (date.compareTo(start) < 0) return false;
    if (task.recurrence == 'habit' || task.recurrence == 'daily') return true;
    final anchor = DateTime.tryParse('${start}T12:00:00');
    final occurrence = DateTime.tryParse('${date}T12:00:00');
    if (anchor == null || occurrence == null) return date == dueDate;
    if (task.recurrence == 'weekly') return anchor.weekday == occurrence.weekday;
    if (task.recurrence == 'monthly') {
      final day = anchor.day;
      final lastDay = DateTime(occurrence.year, occurrence.month + 1, 0).day;
      return occurrence.day == (day > lastDay ? lastDay : day);
    }
    return date == dueDate;
  }

  bool completedOn(TaskItem task, String date) {
    return task.recurrence == 'once' || date == task.dueDate
        ? task.completed
        : task.completedDates.contains(date);
  }

  void _syncFromRealtime() {
    unawaited(syncNow());
  }

  // --- Two-Way Supabase Sync ---
  Future<void> syncNow() async {
    if (_activeSyncFuture != null) {
      _pendingSyncQueued = true;
      await _activeSyncFuture;
      if (_pendingSyncQueued) {
        return syncNow();
      }
      return;
    }

    final future = _performSync();
    _activeSyncFuture = future;
    try {
      await future;
    } finally {
      _activeSyncFuture = null;
    }
  }

  Future<void> _performSync() async {
    _pendingSyncQueued = false;
    _syncStatus = SyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final remoteRecords = await supabase.fetchAll();
      if (remoteRecords == null) {
        _syncStatus = SyncStatus.offline;
        notifyListeners();
        return;
      }

      final remoteMap = <String, dynamic>{};
      for (final r in remoteRecords) {
        remoteMap[r.key] = r.value;
      }

      // 0. Reconcile Deleted Tasks Tombstones FIRST
      if (remoteMap.containsKey('dashboard_deleted_tasks') && remoteMap['dashboard_deleted_tasks'] is Map) {
        final remDeleted = Map<String, dynamic>.from(remoteMap['dashboard_deleted_tasks'] as Map);
        _deletedTasks.addAll(remDeleted);
        // Prune any legacy text keys (like titles with spaces or 'test') so they don't block new tasks
        _deletedTasks.removeWhere((key, _) => key.contains(' ') || key == 'test');
        await storage.saveDeletedTasks(_deletedTasks);
      }

      // 0b. Reconcile Deleted Habits Tombstones
      if (remoteMap.containsKey('dashboard_deleted_habits') && remoteMap['dashboard_deleted_habits'] is Map) {
        final remDeletedHabits = Map<String, dynamic>.from(remoteMap['dashboard_deleted_habits'] as Map);
        _deletedHabits.addAll(remDeletedHabits);
        _pruneDeletedHabits();
        await storage.saveDeletedHabits(_deletedHabits);
      }

      // 1. Reconcile Tasks with intelligent title + ID deduplication and tombstone pruning
      if (remoteMap.containsKey('dashboard_todos') && remoteMap['dashboard_todos'] is Map) {
        final remoteTodos = remoteMap['dashboard_todos'] as Map<String, dynamic>;
        const categories = ['din', 'lang', 'cyber', 'train', 'work', 'proj'];
        bool hasLocalChangesToPush = false;

        for (final cat in categories) {
          final localList = _tasks[cat] ?? [];
          final remoteListRaw = remoteTodos[cat];
          final remoteList = (remoteListRaw is List)
              ? remoteListRaw.map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e as Map), defaultCategory: cat)).toList()
              : <TaskItem>[];

          final mergedMap = <String, TaskItem>{};

          // 1. Seed with remote items (exclude tombstones by ID only)
          for (final remoteItem in remoteList) {
            if (_deletedTasks.containsKey(remoteItem.id)) {
              continue; // DELETED! Do not resurrect!
            }
            mergedMap[remoteItem.id] = remoteItem;
          }

          // 2. Reconcile local items
          for (final localItem in localList) {
            // A deletion from Desktop may arrive before this device has
            // discarded its local copy. Do not remove the tombstone here: it
            // would resurrect the stale task on the next push. New tasks get
            // new IDs and clear only their own tombstone in addTask().
            if (_deletedTasks.containsKey(localItem.id)) {
              continue;
            }

            if (!mergedMap.containsKey(localItem.id)) {
              // Local-only task (created locally while offline)
              mergedMap[localItem.id] = localItem;
              hasLocalChangesToPush = true;
            } else {
              final remoteItem = mergedMap[localItem.id]!;
              if (localItem.updatedAt > remoteItem.updatedAt) {
                // Local is strictly newer -> local wins!
                mergedMap[localItem.id] = localItem;
                hasLocalChangesToPush = true;
              } else {
                // Remote is newer or equal: remote item already in mergedMap[localItem.id]
              }
            }
          }

          // Strict deduplication by normalized text within category
          final seen = <String, TaskItem>{};
          for (final item in mergedMap.values) {
            final norm = item.text.trim().toLowerCase();
            if (norm.isEmpty) continue;
            if (!seen.containsKey(norm)) {
              seen[norm] = item;
            } else if (item.updatedAt > seen[norm]!.updatedAt) {
              seen[norm] = item;
            }
          }

          _tasks[cat] = seen.values.toList();
        }
        await storage.saveTasks(_tasks);
        if (hasLocalChangesToPush) {
          await _pushTasksToRemote();
        }
      } else {
        await _pushTasksToRemote();
      }

      // 2. Reconcile Objectives
      if (remoteMap.containsKey('dashboard_deleted_objectives') && remoteMap['dashboard_deleted_objectives'] is Map) {
        _deletedObjectives.addAll(Map<String, dynamic>.from(remoteMap['dashboard_deleted_objectives'] as Map));
        _pruneDeletedObjectives();
        await storage.saveDeletedObjectives(_deletedObjectives);
        await storage.saveObjectives(_objectives);
      }
      if (remoteMap.containsKey('dashboard_objectives') && remoteMap['dashboard_objectives'] is Map) {
        final remoteObj = DashboardObjectives.fromJson(Map<String, dynamic>.from(remoteMap['dashboard_objectives'] as Map));
        // Goals/targets use the same per-record updatedAt conflict rule as
        // tasks.  Replacing local objectives with a non-empty remote blob was
        // dropping valid mobile edits made while another client was open.
        final mergedObjectives = _mergeObjectives(_objectives, remoteObj);
        final needsObjectivePush = jsonEncode(mergedObjectives.toJson()) != jsonEncode(remoteObj.toJson());
        _objectives = mergedObjectives;
        await storage.saveObjectives(_objectives);
        if (needsObjectivePush) await _pushObjectivesToRemote();
      } else {
        await _pushObjectivesToRemote();
      }

      // 3. NoFap Start Date
      if (remoteMap.containsKey('nofap_start_date') && remoteMap['nofap_start_date'] != null) {
        final remoteVal = remoteMap['nofap_start_date'];
        if (remoteVal is num && remoteVal > 0) {
          _nofapStartTime = remoteVal.toInt();
          await storage.saveNofapStartTime(_nofapStartTime);
        }
      }

      // 4. Productivity Dates
      if (remoteMap.containsKey('productivity_completion_dates') && remoteMap['productivity_completion_dates'] is List) {
        final remoteDates = (remoteMap['productivity_completion_dates'] as List).map((e) => e.toString()).toSet();
        final localDates = _productivityDates.toSet();
        _productivityDates = remoteDates.union(localDates).toList()..sort();
        await storage.saveProductivityDates(_productivityDates);
      }

      // 5. Academy progress
      if (remoteMap.containsKey('academy_progress_v1') && remoteMap['academy_progress_v1'] is Map) {
        final remoteProg = (remoteMap['academy_progress_v1'] as Map).map((k, v) => MapEntry(k.toString(), v == true));
        _academyProgress.addAll(remoteProg);
        await storage.saveAcademyProgress(_academyProgress);
      }

      // 6. Calisthenics Active Session
      if (remoteMap.containsKey('calisthenics_active_session_v1') && remoteMap['calisthenics_active_session_v1'] is Map) {
        final remSess = Map<String, dynamic>.from(remoteMap['calisthenics_active_session_v1'] as Map);
        final locTime = (_activeSession['updatedAt'] ?? _activeSession['startedAt'] ?? 0) as num;
        final remTime = (remSess['updatedAt'] ?? remSess['startedAt'] ?? 0) as num;
        if (remTime >= locTime) {
          _activeSession = remSess;
          await storage.saveActiveSession(_activeSession);
        }
      }

      // 7. Calisthenics History
      if (remoteMap.containsKey('calisthenics_history_v1') && remoteMap['calisthenics_history_v1'] is List) {
        final remHist = remoteMap['calisthenics_history_v1'] as List;
        final histMap = <String, dynamic>{};
        for (final item in remHist) {
          if (item is Map) {
            final k = item['id']?.toString() ?? item['date']?.toString() ?? item.hashCode.toString();
            histMap[k] = item;
          }
        }
        for (final item in _trainingHistory) {
          if (item is Map) {
            final k = item['id']?.toString() ?? item['date']?.toString() ?? item.hashCode.toString();
            histMap.putIfAbsent(k, () => item);
          }
        }
        _trainingHistory = histMap.values.toList();
        await storage.saveTrainingHistory(_trainingHistory);
      }

      // 8. Habits with history merge
      if (remoteMap.containsKey('dashboard_habits') && remoteMap['dashboard_habits'] is List) {
        final remHabits = remoteMap['dashboard_habits'] as List;
        _habits = _mergeHabitsList(_habits, remHabits);
        _pruneDeletedHabits();
        await storage.saveHabits(_habits);
      }

      // 9. NoFap Streak History
      if (remoteMap.containsKey('nofap_streak_history') && remoteMap['nofap_streak_history'] is List) {
        final remStreak = (remoteMap['nofap_streak_history'] as List).map((e) => e.toString()).toSet();
        final locStreak = _nofapHistory.toSet();
        _nofapHistory = remStreak.union(locStreak).toList()..sort();
        await storage.saveNofapHistory(_nofapHistory);
      }

      _lastSyncTime = DateTime.now();
      await storage.setLastSyncTime(_lastSyncTime!.toIso8601String());
      _syncStatus = SyncStatus.synced;
    } catch (e) {
      _syncStatus = SyncStatus.error;
      _lastError = e.toString();
    } finally {
      notifyListeners();
    }
  }

  DashboardObjectives _mergeObjectives(DashboardObjectives local, DashboardObjectives remote) {
    List<ObjectiveItem> mergeList(List<ObjectiveItem> locList, List<ObjectiveItem> remList) {
      final map = <String, ObjectiveItem>{};
      for (final item in remList) {
        if (!_deletedObjectives.containsKey(item.id)) map[item.id] = item;
      }
      for (final item in locList) {
        if (_deletedObjectives.containsKey(item.id)) continue;
        if (!map.containsKey(item.id)) {
          map[item.id] = item;
        } else {
          final ex = map[item.id]!;
          if (item.updatedAt > ex.updatedAt) {
            map[item.id] = item;
          } else {
            map[item.id] = ex;
          }
        }
      }
      return map.values.toList();
    }

    return DashboardObjectives(
      yearly: mergeList(local.yearly, remote.yearly),
      monthly: mergeList(local.monthly, remote.monthly),
      weekly: mergeList(local.weekly, remote.weekly),
    );
  }

  Future<void> _pushTasksToRemote() async {
    final payload = <String, dynamic>{};
    _tasks.forEach((cat, list) {
      payload[cat] = list.map((t) => t.toJson()).toList();
    });
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final ok = await supabase.upsertKeys([
      {
        'key': 'dashboard_todos',
        'value': payload,
        'updated_at': nowIso,
      },
      {
        'key': 'dashboard_deleted_tasks',
        'value': _deletedTasks,
        'updated_at': nowIso,
      }
    ]);
    if (ok) {
      _lastSyncTime = DateTime.now();
      await storage.setLastSyncTime(_lastSyncTime!.toIso8601String());
      _syncStatus = SyncStatus.synced;
      notifyListeners();
    }
  }

  Future<void> _pushObjectivesToRemote() async {
    await supabase.upsertKeys([
      {'key': 'dashboard_objectives', 'value': _objectives.toJson()},
      {'key': 'dashboard_deleted_objectives', 'value': _deletedObjectives},
    ]);
  }

  void _pruneDeletedObjectives() {
    _objectives.yearly.removeWhere((item) => _deletedObjectives.containsKey(item.id));
    _objectives.monthly.removeWhere((item) => _deletedObjectives.containsKey(item.id));
    _objectives.weekly.removeWhere((item) => _deletedObjectives.containsKey(item.id));
  }

  // --- Task Mutators ---
  Future<void> toggleTask(TaskItem task) async {
    final today = _formatDate(DateTime.now());
    final nextCompleted = !completedOn(task, today);
    // Repeating occurrences have per-day completion. Keep the task-level
    // flag for one-off/current-due tasks, exactly as desktop does.
    if (task.dueDate == null || task.dueDate!.isEmpty || task.dueDate == today || task.recurrence == 'once') {
      task.completed = nextCompleted;
    }
    task.updatedAt = DateTime.now().millisecondsSinceEpoch;

    if (nextCompleted) {
      if (!task.completedDates.contains(today)) {
        task.completedDates.add(today);
      }
    } else {
      task.completedDates.remove(today);
    }

    // Check if all today's tasks completed -> mark productivity date
    final dueToday = todayTasks;
    if (dueToday.isNotEmpty && dueToday.every((t) => completedOn(t, today))) {
      if (!_productivityDates.contains(today)) {
        _productivityDates.add(today);
        await storage.saveProductivityDates(_productivityDates);
        await supabase.upsertSingle('productivity_completion_dates', _productivityDates);
      }
    } else {
      if (_productivityDates.contains(today)) {
        _productivityDates.remove(today);
        await storage.saveProductivityDates(_productivityDates);
        await supabase.upsertSingle('productivity_completion_dates', _productivityDates);
      }
    }

    await storage.saveTasks(_tasks);
    notifyListeners();

    await _pushTasksToRemote();
  }

  Future<void> addTask(TaskItem task) async {
    final cat = task.category;
    final norm = task.text.trim().toLowerCase();
    task.updatedAt = DateTime.now().millisecondsSinceEpoch;
    if (task.id.isNotEmpty) _deletedTasks.remove(task.id);
    if (norm.isNotEmpty) _deletedTasks.remove(norm);
    await storage.saveDeletedTasks(_deletedTasks);

    final tasks = _tasks.putIfAbsent(cat, () => []);
    final priorityRank = {'high': 0, 'medium': 1, 'low': 2};
    final taskRank = priorityRank[task.priority] ?? 1;
    final insertionIndex = tasks.indexWhere((item) => (priorityRank[item.priority] ?? 1) > taskRank);
    if (insertionIndex == -1) {
      tasks.add(task);
    } else {
      tasks.insert(insertionIndex, task);
    }
    await storage.saveTasks(_tasks);
    notifyListeners();
    await _pushTasksToRemote();
  }

  Future<void> updateTask(TaskItem updated) async {
    final cat = updated.category;
    updated.updatedAt = DateTime.now().millisecondsSinceEpoch;
    var originalIndex = -1;
    String? originalCategory;
    for (final c in _tasks.keys) {
      final list = _tasks[c];
      final index = list?.indexWhere((t) => t.id == updated.id) ?? -1;
      if (index >= 0) {
        originalCategory ??= c;
        originalIndex = index;
        list!.removeAt(index);
      }
    }
    final target = _tasks.putIfAbsent(cat, () => []);
    if (originalCategory == cat && originalIndex >= 0) {
      target.insert(originalIndex > target.length ? target.length : originalIndex, updated);
    } else {
      target.add(updated);
    }
    await storage.saveTasks(_tasks);
    notifyListeners();
    await _pushTasksToRemote();
  }

  Future<void> deleteTask(TaskItem task) async {
    final cat = task.category;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (task.id.isNotEmpty) _deletedTasks[task.id] = now;
    await storage.saveDeletedTasks(_deletedTasks);

    _tasks[cat]?.removeWhere((t) => t.id == task.id);
    await storage.saveTasks(_tasks);
    notifyListeners();
    await _pushTasksToRemote();
  }

  // --- Objective Mutators ---
  Future<void> toggleObjective(ObjectiveItem item, String type) async {
    item.completed = !item.completed;
    item.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await storage.saveObjectives(_objectives);
    notifyListeners();
    await _pushObjectivesToRemote();
  }

  Future<void> addObjective(String text, String type) async {
    final newObj = ObjectiveItem(
      id: 'obj_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      completed: false,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _deletedObjectives.remove(newObj.id);
    await storage.saveDeletedObjectives(_deletedObjectives);
    if (type == 'yearly') _objectives.yearly.add(newObj);
    if (type == 'monthly') _objectives.monthly.add(newObj);
    if (type == 'weekly') _objectives.weekly.add(newObj);

    await storage.saveObjectives(_objectives);
    notifyListeners();
    await _pushObjectivesToRemote();
  }

  Future<void> deleteObjective(String id, String type) async {
    _deletedObjectives[id] = DateTime.now().millisecondsSinceEpoch;
    await storage.saveDeletedObjectives(_deletedObjectives);
    if (type == 'yearly') _objectives.yearly.removeWhere((o) => o.id == id);
    if (type == 'monthly') _objectives.monthly.removeWhere((o) => o.id == id);
    if (type == 'weekly') _objectives.weekly.removeWhere((o) => o.id == id);

    await storage.saveObjectives(_objectives);
    notifyListeners();
    await _pushObjectivesToRemote();
  }

  // --- NoFap & Mindset Mutators ---
  Future<void> resetNofap() async {
    _nofapStartTime = DateTime.now().millisecondsSinceEpoch;
    await storage.saveNofapStartTime(_nofapStartTime);
    notifyListeners();
    await supabase.upsertSingle('nofap_start_date', _nofapStartTime);
  }

  // --- Habit Mutators ---
  List<dynamic> _mergeHabitsList(List<dynamic> localRaw, List<dynamic> remoteRaw) {
    final habitMap = <String, Map<String, dynamic>>{};
    for (final h in remoteRaw) {
      if (h is Map) {
        final map = Map<String, dynamic>.from(h);
        final id = map['id']?.toString() ?? '';
        if (id.isEmpty || _deletedHabits.containsKey(id)) continue;
        habitMap[id] = map;
      }
    }
    for (final h in localRaw) {
      if (h is Map) {
        final map = Map<String, dynamic>.from(h);
        final id = map['id']?.toString() ?? '';
        if (id.isEmpty || _deletedHabits.containsKey(id)) continue;
        if (!habitMap.containsKey(id)) {
          habitMap[id] = map;
        } else {
          final existing = habitMap[id]!;
          final localTime = (map['updatedAt'] is num) ? (map['updatedAt'] as num).toInt() : 0;
          final remoteTime = (existing['updatedAt'] is num) ? (existing['updatedAt'] as num).toInt() : 0;

          final newer = localTime > remoteTime ? map : existing;
          final older = localTime > remoteTime ? existing : map;

          final mergedHistory = Map<String, dynamic>.from((older['history'] as Map?) ?? {});
          final newerHistory = (newer['history'] as Map?) ?? {};
          newerHistory.forEach((k, v) {
            mergedHistory[k.toString()] = v;
          });

          habitMap[id] = {
            ...older,
            ...newer,
            'history': mergedHistory,
            'updatedAt': math.max(localTime, remoteTime) > 0 ? math.max(localTime, remoteTime) : DateTime.now().millisecondsSinceEpoch,
          };
        }
      }
    }
    return habitMap.values.toList();
  }

  Future<void> toggleHabitDay(String habitId, String dateKey) async {
    final list = habitItems;
    final index = list.indexWhere((h) => h.id == habitId);
    if (index < 0) return;

    final habit = list[index];
    final isDone = habit.isCompletedOn(dateKey);
    final newHistory = Map<String, int>.from(habit.history);
    if (isDone) {
      newHistory[dateKey] = 0;
    } else {
      newHistory[dateKey] = habit.target > 0 ? habit.target : 1;
    }
    habit.history = newHistory;
    habit.updatedAt = DateTime.now().millisecondsSinceEpoch;
    _habits = list.map((h) => h.toJson()).toList();
    await storage.saveHabits(_habits);
    notifyListeners();
    await supabase.upsertSingle('dashboard_habits', _habits);
  }

  Future<void> updateHabitQuantity(String habitId, String dateKey, int delta) async {
    final list = habitItems;
    final index = list.indexWhere((h) => h.id == habitId);
    if (index < 0) return;

    final habit = list[index];
    final current = habit.countOn(dateKey);
    final next = (current + delta).clamp(0, 999999);
    final newHistory = Map<String, int>.from(habit.history);
    newHistory[dateKey] = next;
    habit.history = newHistory;
    habit.updatedAt = DateTime.now().millisecondsSinceEpoch;
    _habits = list.map((h) => h.toJson()).toList();
    await storage.saveHabits(_habits);
    notifyListeners();
    await supabase.upsertSingle('dashboard_habits', _habits);
  }

  Future<void> addHabit(HabitItem habit) async {
    habit.updatedAt = DateTime.now().millisecondsSinceEpoch;
    if (habit.id.isNotEmpty) {
      _deletedHabits.remove(habit.id);
      await storage.saveDeletedHabits(_deletedHabits);
    }
    final list = habitItems;
    list.add(habit);
    _habits = list.map((h) => h.toJson()).toList();
    await storage.saveHabits(_habits);
    notifyListeners();
    await supabase.upsertKeys([
      {'key': 'dashboard_habits', 'value': _habits},
      {'key': 'dashboard_deleted_habits', 'value': _deletedHabits},
    ]);
  }

  Future<void> updateHabit(HabitItem updated) async {
    updated.updatedAt = DateTime.now().millisecondsSinceEpoch;
    if (updated.id.isNotEmpty) {
      _deletedHabits.remove(updated.id);
      await storage.saveDeletedHabits(_deletedHabits);
    }
    final list = habitItems;
    final index = list.indexWhere((h) => h.id == updated.id);
    if (index >= 0) {
      list[index] = updated;
    } else {
      list.add(updated);
    }
    _habits = list.map((h) => h.toJson()).toList();
    await storage.saveHabits(_habits);
    notifyListeners();
    await supabase.upsertKeys([
      {'key': 'dashboard_habits', 'value': _habits},
      {'key': 'dashboard_deleted_habits', 'value': _deletedHabits},
    ]);
  }

  Future<void> deleteHabit(String habitId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (habitId.isNotEmpty) {
      _deletedHabits[habitId] = now;
      await storage.saveDeletedHabits(_deletedHabits);
    }
    final list = habitItems;
    list.removeWhere((h) => h.id == habitId);
    _habits = list.map((h) => h.toJson()).toList();
    await storage.saveHabits(_habits);
    notifyListeners();
    await supabase.upsertKeys([
      {'key': 'dashboard_habits', 'value': _habits},
      {'key': 'dashboard_deleted_habits', 'value': _deletedHabits},
    ]);
  }

  Future<void> toggleArchiveHabit(String habitId) async {
    final list = habitItems;
    final index = list.indexWhere((h) => h.id == habitId);
    if (index >= 0) {
      list[index].archived = !list[index].archived;
      list[index].updatedAt = DateTime.now().millisecondsSinceEpoch;
      _habits = list.map((h) => h.toJson()).toList();
      await storage.saveHabits(_habits);
      notifyListeners();
      await supabase.upsertSingle('dashboard_habits', _habits);
    }
  }

  // --- Training Hub (Calisthenics) Mutators ---
  Future<void> updateActiveSessionSet(String exerciseId, int setIndex, bool completed) async {
    final setsRaw = _activeSession['completedSets'];
    final sets = Map<String, dynamic>.from(setsRaw is Map ? setsRaw : {});
    final exerciseSets = List<int>.from((sets[exerciseId] as List?) ?? []);

    if (completed) {
      if (!exerciseSets.contains(setIndex)) exerciseSets.add(setIndex);
    } else {
      exerciseSets.remove(setIndex);
    }
    sets[exerciseId] = exerciseSets;

    _activeSession['completedSets'] = sets;
    _activeSession['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await storage.saveActiveSession(_activeSession);
    notifyListeners();
    await supabase.upsertSingle('calisthenics_active_session_v1', _activeSession);
  }

  Future<void> recordCompletedWorkout(Map<String, dynamic> summary) async {
    _trainingHistory.insert(0, summary);
    await storage.saveTrainingHistory(_trainingHistory);
    _activeSession = {
      'completedSets': {},
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await storage.saveActiveSession(_activeSession);
    notifyListeners();
    await supabase.upsertSingle('calisthenics_history_v1', _trainingHistory);
    await supabase.upsertSingle('calisthenics_active_session_v1', _activeSession);
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
