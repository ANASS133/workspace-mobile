import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';
import '../models/objective_item.dart';

class StorageService {
  static const String keyTodos = 'dashboard_todos';
  static const String keyObjectives = 'dashboard_objectives';
  static const String keyProductivityDates = 'productivity_completion_dates';
  static const String keyNofapStart = 'nofap_start_date';
  static const String keyNofapHistory = 'nofap_streak_history';
  static const String keyAcademyProgress = 'academy_progress_v1';
  static const String keyActiveSession = 'calisthenics_active_session_v1';
  static const String keyTrainingHistory = 'calisthenics_history_v1';
  static const String keyHabits = 'dashboard_habits';
  static const String keyLastSync = 'supabase_last_sync_time';
  static const String keyDeletedTasks = 'dashboard_deleted_tasks';
  static const String keyDeletedObjectives = 'dashboard_deleted_objectives';
  static const String keyDeletedHabits = 'dashboard_deleted_habits';

  static const String keyThemeMode = 'app_theme_mode';

  final SharedPreferences _prefs;
  static StorageService? _instance;
  static StorageService get instance => _instance!;

  StorageService(this._prefs) {
    _instance = this;
  }

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    _instance = service;
    return service;
  }

  // --- Theme Mode ---
  String loadThemeMode() {
    return _prefs.getString(keyThemeMode) ?? 'dark';
  }

  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(keyThemeMode, mode);
  }

  // --- Tasks ---
  Map<String, List<TaskItem>> loadTasks() {
    final raw = _prefs.getString(keyTodos);
    if (raw == null || raw.isEmpty) {
      // Supabase is canonical. A fresh install must not manufacture the old
      // sample dataset and merge it into an existing Desktop workspace.
      return {
        'din': [], 'lang': [], 'cyber': [], 'train': [], 'work': [], 'proj': [],
      };
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, List<TaskItem>>{};
      const categories = ['din', 'lang', 'cyber', 'train', 'work', 'proj'];
      for (final cat in categories) {
        if (decoded.containsKey(cat) && decoded[cat] is List) {
          result[cat] = (decoded[cat] as List)
              .map((item) => TaskItem.fromJson(Map<String, dynamic>.from(item as Map), defaultCategory: cat))
              .toList();
        } else {
          result[cat] = [];
        }
      }
      return result;
    } catch (_) {
      return {'din': [], 'lang': [], 'cyber': [], 'train': [], 'work': [], 'proj': []};
    }
  }

  Future<void> saveTasks(Map<String, List<TaskItem>> tasks) async {
    final encoded = <String, dynamic>{};
    tasks.forEach((cat, list) {
      encoded[cat] = list.map((t) => t.toJson()).toList();
    });
    await _prefs.setString(keyTodos, jsonEncode(encoded));
  }

  // --- Deleted Tasks (Tombstones) ---
  Map<String, dynamic> loadDeletedTasks() {
    final raw = _prefs.getString(keyDeletedTasks);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDeletedTasks(Map<String, dynamic> deleted) async {
    await _prefs.setString(keyDeletedTasks, jsonEncode(deleted));
  }

  Map<String, dynamic> loadDeletedObjectives() {
    final raw = _prefs.getString(keyDeletedObjectives);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDeletedObjectives(Map<String, dynamic> deleted) async {
    await _prefs.setString(keyDeletedObjectives, jsonEncode(deleted));
  }

  // --- Deleted Habits (Tombstones) ---
  Map<String, dynamic> loadDeletedHabits() {
    final raw = _prefs.getString(keyDeletedHabits);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDeletedHabits(Map<String, dynamic> deleted) async {
    await _prefs.setString(keyDeletedHabits, jsonEncode(deleted));
  }

  // --- Objectives ---
  DashboardObjectives loadObjectives() {
    final raw = _prefs.getString(keyObjectives);
    if (raw == null || raw.isEmpty) {
      return DashboardObjectives();
    }
    try {
      return DashboardObjectives.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return DashboardObjectives();
    }
  }

  Future<void> saveObjectives(DashboardObjectives objectives) async {
    await _prefs.setString(keyObjectives, jsonEncode(objectives.toJson()));
  }

  // --- Streak & Productivity ---
  List<String> loadProductivityDates() {
    final list = _prefs.getStringList(keyProductivityDates);
    return list ?? [];
  }

  Future<void> saveProductivityDates(List<String> dates) async {
    await _prefs.setStringList(keyProductivityDates, dates);
  }

  // --- NoFap & Mindset Start Date ---
  int loadNofapStartTime() {
    final val = _prefs.getInt(keyNofapStart);
    // If not set, default to 7 days ago so counter starts meaningfully
    return val ?? DateTime.now().subtract(const Duration(days: 6, hours: 14)).millisecondsSinceEpoch;
  }

  Future<void> saveNofapStartTime(int millis) async {
    await _prefs.setInt(keyNofapStart, millis);
  }

  // --- Academy Progress ---
  Map<String, bool> loadAcademyProgress() {
    final raw = _prefs.getString(keyAcademyProgress);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v == true));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveAcademyProgress(Map<String, bool> progress) async {
    await _prefs.setString(keyAcademyProgress, jsonEncode(progress));
  }

  // --- Training Hub (Calisthenics) ---
  Map<String, dynamic> loadActiveSession() {
    final raw = _prefs.getString(keyActiveSession);
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveActiveSession(Map<String, dynamic> session) async {
    await _prefs.setString(keyActiveSession, jsonEncode(session));
  }

  List<dynamic> loadTrainingHistory() {
    final raw = _prefs.getString(keyTrainingHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      return list is List ? list : [];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTrainingHistory(List<dynamic> history) async {
    await _prefs.setString(keyTrainingHistory, jsonEncode(history));
  }

  // --- Habits ---
  List<dynamic> loadHabits() {
    final raw = _prefs.getString(keyHabits);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      return list is List ? list : [];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHabits(List<dynamic> habits) async {
    await _prefs.setString(keyHabits, jsonEncode(habits));
  }

  // --- NoFap History ---
  List<String> loadNofapHistory() {
    return _prefs.getStringList(keyNofapHistory) ?? [];
  }

  Future<void> saveNofapHistory(List<String> dates) async {
    await _prefs.setStringList(keyNofapHistory, dates);
  }

  // --- Last Sync ---
  String? getLastSyncTime() => _prefs.getString(keyLastSync);

  Future<void> setLastSyncTime(String timeIso) async {
    await _prefs.setString(keyLastSync, timeIso);
  }

}
