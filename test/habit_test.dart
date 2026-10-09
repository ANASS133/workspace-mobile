import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versionmobile/models/habit_item.dart';
import 'package:versionmobile/services/storage_service.dart';
import 'package:versionmobile/services/supabase_service.dart';
import 'package:versionmobile/services/sync_manager.dart';

class FakeSupabaseService extends SupabaseService {
  @override
  void startRealtime(void Function() onChange) {}

  @override
  Future<List<SupabaseRecord>?> fetchAll() async => null;

  @override
  Future<bool> upsertSingle(String key, dynamic value) async => true;

  @override
  Future<bool> upsertKeys(List<Map<String, dynamic>> entries) async => true;
}

void main() {
  test('HabitItem JSON serialization and streak test', () {
    final habit = HabitItem(
      id: 'h_test_1',
      name: 'Morning Dhikr',
      days: [1, 2, 3, 4, 5], // Mon to Fri
      kind: 'check',
      target: 1,
      unit: '',
      history: {
        '2026-10-08': 1,
        '2026-10-09': 1,
      },
    );

    expect(habit.isScheduledOn('2026-10-09'), isTrue); // Friday is day 5
    expect(habit.isCompletedOn('2026-10-09'), isTrue);
    expect(habit.countOn('2026-10-09'), equals(1));

    final json = habit.toJson();
    expect(json['id'], equals('h_test_1'));
    expect(json['name'], equals('Morning Dhikr'));
    expect(json['days'], equals([1, 2, 3, 4, 5]));

    final reconstructed = HabitItem.fromJson(json);
    expect(reconstructed.id, equals('h_test_1'));
    expect(reconstructed.name, equals('Morning Dhikr'));
    expect(reconstructed.history['2026-10-09'], equals(1));
  });

  test('SyncManager habits mutators test', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final supabase = FakeSupabaseService();
    final manager = SyncManager(storage: storage, supabase: supabase);

    final habit = HabitItem(
      id: 'h_test_read',
      name: 'Read Quran 10 pages',
      days: [0, 1, 2, 3, 4, 5, 6],
      kind: 'quantity',
      target: 10,
      unit: 'pages',
    );

    await manager.addHabit(habit);
    expect(manager.habitItems.any((h) => h.id == 'h_test_read'), isTrue);

    // Update quantity
    await manager.updateHabitQuantity('h_test_read', '2026-10-09', 10);
    final updated = manager.habitItems.firstWhere((h) => h.id == 'h_test_read');
    expect(updated.countOn('2026-10-09'), equals(10));
    expect(updated.isCompletedOn('2026-10-09'), isTrue);

    // Toggle day for check habit
    final checkHabit = HabitItem(
      id: 'h_test_fajr',
      name: 'Fajr in Mosque',
      days: [0, 1, 2, 3, 4, 5, 6],
      kind: 'check',
    );
    await manager.addHabit(checkHabit);
    await manager.toggleHabitDay('h_test_fajr', '2026-10-09');
    final fajrUpdated = manager.habitItems.firstWhere((h) => h.id == 'h_test_fajr');
    expect(fajrUpdated.isCompletedOn('2026-10-09'), isTrue);

    // Toggle off
    await manager.toggleHabitDay('h_test_fajr', '2026-10-09');
    final fajrToggledOff = manager.habitItems.firstWhere((h) => h.id == 'h_test_fajr');
    // Delete habit test
    await manager.deleteHabit('h_test_fajr');
    expect(manager.habitItems.any((h) => h.id == 'h_test_fajr'), isFalse);
    expect(manager.deletedHabits.containsKey('h_test_fajr'), isTrue);

    // Re-add habit clears tombstone
    final recreatedHabit = HabitItem(
      id: 'h_test_fajr',
      name: 'Fajr in Mosque',
      days: [0, 1, 2, 3, 4, 5, 6],
      kind: 'check',
    );
    await manager.addHabit(recreatedHabit);
    expect(manager.habitItems.any((h) => h.id == 'h_test_fajr'), isTrue);
    expect(manager.deletedHabits.containsKey('h_test_fajr'), isFalse);

    manager.dispose();
  });

  test('Habit reconciliation ignores deleted tombstones and respects updatedAt', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    // Seed local deleted habits
    await storage.saveDeletedHabits({'deleted_remote_habit': 1000});

    // Remote returns deleted habit and an active habit
    final testSupabase = ConfigurableFakeSupabaseService([
      SupabaseRecord(
        key: 'dashboard_habits',
        value: [
          {
            'id': 'deleted_remote_habit',
            'name': 'Should Not Appear',
            'days': [0, 1, 2, 3, 4, 5, 6],
            'kind': 'check',
            'updatedAt': 500,
          },
          {
            'id': 'active_pushups',
            'name': '100 push ups',
            'days': [0, 1, 2, 3, 4, 5, 6],
            'kind': 'check',
            'history': {'2026-10-08': 1, '2026-10-09': 1},
            'updatedAt': 500,
          }
        ],
      ),
      SupabaseRecord(
        key: 'dashboard_deleted_habits',
        value: {'deleted_remote_habit': 1000},
      ),
    ]);

    final manager = SyncManager(storage: storage, supabase: testSupabase);
    await manager.syncNow();

    // Deleted habit was pruned and not added
    expect(manager.habitItems.any((h) => h.id == 'deleted_remote_habit'), isFalse);
    // Active habit is present
    expect(manager.habitItems.any((h) => h.id == 'active_pushups'), isTrue);

    // Test unchecking does not get overwritten when remote is older
    final pushups = manager.habitItems.firstWhere((h) => h.id == 'active_pushups');
    expect(pushups.isCompletedOn('2026-10-09'), isTrue);

    await manager.toggleHabitDay('active_pushups', '2026-10-09');
    expect(manager.habitItems.firstWhere((h) => h.id == 'active_pushups').isCompletedOn('2026-10-09'), isFalse);

    // Re-sync with older remote record
    await manager.syncNow();

    // Local change must persist because local updatedAt is newer than remote updatedAt (500)
    final afterResync = manager.habitItems.firstWhere((h) => h.id == 'active_pushups');
    expect(afterResync.isCompletedOn('2026-10-09'), isFalse);
    expect(afterResync.isCompletedOn('2026-10-08'), isTrue);

    manager.dispose();
  });
}

class ConfigurableFakeSupabaseService extends SupabaseService {
  final List<SupabaseRecord> records;
  ConfigurableFakeSupabaseService(this.records);

  @override
  void startRealtime(void Function() onChange) {}

  @override
  Future<List<SupabaseRecord>?> fetchAll() async => records;

  @override
  Future<bool> upsertSingle(String key, dynamic value) async => true;

  @override
  Future<bool> upsertKeys(List<Map<String, dynamic>> entries) async => true;
}
