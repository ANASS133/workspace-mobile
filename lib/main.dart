import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'services/sync_manager.dart';
import 'widgets/task_editor_sheet.dart';
import 'widgets/habit_editor_sheet.dart';
import 'screens/today_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/objectives_screen.dart';
import 'screens/training_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/discipline_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await StorageService.init();
  final supabase = SupabaseService();
  final syncManager = SyncManager(storage: storage, supabase: supabase);

  final savedTheme = storage.loadThemeMode();
  AppTheme.themeModeNotifier.value = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: AppTheme.isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarColor: AppTheme.surface,
    systemNavigationBarIconBrightness: AppTheme.isDark ? Brightness.light : Brightness.dark,
  ));

  runApp(WorkspaceMobileApp(syncManager: syncManager));
}

class WorkspaceMobileApp extends StatelessWidget {
  final SyncManager syncManager;

  const WorkspaceMobileApp({super.key, required this.syncManager});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([syncManager, AppTheme.themeModeNotifier]),
      builder: (context, _) {
        final currentMode = AppTheme.themeModeNotifier.value;
        return MaterialApp(
          title: 'Workspace Mobile',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: MainShell(syncManager: syncManager),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  final SyncManager syncManager;

  const MainShell({super.key, required this.syncManager});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final sm = widget.syncManager;

    // Cloud status chip
    Color cloudDotColor = AppTheme.successGreen;
    String cloudLabel = 'Synced';
    if (sm.syncStatus == SyncStatus.syncing) {
      cloudDotColor = AppTheme.infoSky;
      cloudLabel = 'Syncing...';
    } else if (sm.syncStatus == SyncStatus.offline) {
      cloudDotColor = AppTheme.priorityMed;
      cloudLabel = 'Offline';
    } else if (sm.syncStatus == SyncStatus.error) {
      cloudDotColor = AppTheme.priorityHigh;
      cloudLabel = 'Error';
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.flameOrange.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flash_on, color: AppTheme.flameOrange, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'Workspace',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Discipline quick access (Code 9090)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => DisciplinePage(syncManager: sm),
                ),
              );
            },
            icon: const Icon(
              Icons.shield_outlined,
              size: 20,
              color: Color(0xFF38BDF8),
            ),
            tooltip: 'Discipline (Code 9090)',
          ),
          // Theme Toggle Button (Sun / Moon)
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              AppTheme.toggleTheme();
            },
            icon: Icon(
              AppTheme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: AppTheme.textSecondary,
            ),
            tooltip: AppTheme.isDark ? 'Switch to Light Mode' : 'Switch to Night Mode',
          ),
          // Supabase Sync status button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                sm.syncNow();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: cloudDotColor),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cloudLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cloudDotColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Settings button
          IconButton(
            icon: Icon(Icons.cloud_outlined, size: 22, color: AppTheme.textSecondary),
            tooltip: 'Cloud Database Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => SettingsScreen(syncManager: sm),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TodayScreen(syncManager: sm),
          TasksScreen(syncManager: sm),
          ObjectivesScreen(syncManager: sm),
          TrainingScreen(syncManager: sm),
          HabitsScreen(syncManager: sm),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on_outlined),
            activeIcon: Icon(Icons.flash_on),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_outlined),
            activeIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes),
            label: 'Roadmap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Training',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.repeat_outlined),
            activeIcon: Icon(Icons.repeat),
            label: 'Habits',
          ),
        ],
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? FloatingActionButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                TaskEditorSheet.show(
                  context,
                  defaultCategory: 'din',
                  onSave: (task) => sm.addTask(task),
                );
              },
              backgroundColor: AppTheme.flameOrange,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add, size: 26),
            )
          : (_currentIndex == 4)
              ? FloatingActionButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    HabitEditorSheet.show(
                      context,
                      objectives: sm.objectives,
                      onSave: (habit) => sm.addHabit(habit),
                    );
                  },
                  backgroundColor: AppTheme.flameOrange,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.add, size: 26),
                )
              : null,
    );
  }
}
