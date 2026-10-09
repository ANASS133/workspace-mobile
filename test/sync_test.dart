import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versionmobile/models/task_item.dart';
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
}

void main() {
  test('Unchecking a task does not revert to checked during reconciliation', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final supabase = FakeSupabaseService();

    final manager = SyncManager(storage: storage, supabase: supabase);

    final task = TaskItem(
      id: 'test_toggle_1',
      text: 'Test Toggle Task',
      category: 'din',
      completed: true,
      updatedAt: 1000,
    );
    await manager.addTask(task);

    final stored = manager.allTasks.firstWhere((t) => t.id == 'test_toggle_1');
    expect(stored.completed, isTrue);

    await manager.toggleTask(stored);
    expect(stored.completed, isFalse);
    expect(stored.updatedAt > 1000, isTrue);

    final afterToggle = manager.allTasks.firstWhere((t) => t.id == 'test_toggle_1');
    expect(afterToggle.completed, isFalse);

    manager.dispose();
  });
}
