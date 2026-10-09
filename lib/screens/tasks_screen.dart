import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../services/sync_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import '../widgets/task_editor_sheet.dart';

class TasksScreen extends StatefulWidget {
  final SyncManager syncManager;

  const TasksScreen({super.key, required this.syncManager});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _selectedCategory = 'all';
  String _statusFilter = 'active'; // 'today', 'week', 'active', 'completed', 'all'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TaskItem> _getFilteredTasks() {
    final sm = widget.syncManager;
    var list = sm.allTasks;

    // 1. Category filter
    if (_selectedCategory != 'all') {
      list = list.where((t) => t.category == _selectedCategory).toList();
    }

    // 2. Status / Time filter
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_statusFilter == 'today') {
      list = list.where((t) => sm.occursOn(t, today) || (t.recurrence == 'habit' && (t.dueDate == null || t.dueDate!.isEmpty))).toList();
    } else if (_statusFilter == 'active') {
      list = list.where((t) => !t.completed).toList();
    } else if (_statusFilter == 'completed') {
      list = list.where((t) => t.completed).toList();
    }

    // 3. Search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((t) => t.text.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    return Column(
      children: [
        // Top Search Bar & Filters
        Container(
          color: AppTheme.background,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              // Search text field
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search tasks, cyber, languages...',
                  prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              // Status tabs (Active, Today, Completed, All)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statusTab('active', 'Active'),
                    _statusTab('today', 'Today'),
                    _statusTab('completed', 'Completed'),
                    _statusTab('all', 'All Tasks'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Category horizontal chip selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _categoryChip('all', 'All Pillars', Icons.grid_view, AppTheme.flameOrange),
                    ...TaskCategoryMeta.all.map((c) => _categoryChip(c.id, c.shortTitle, c.icon, c.color)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Task List
        Expanded(
          child: filteredTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist, size: 54, color: AppTheme.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No tasks matching "$_searchQuery"'
                            : 'No tasks found in this view',
                        style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          TaskEditorSheet.show(
                            context,
                            defaultCategory: _selectedCategory == 'all' ? 'din' : _selectedCategory,
                            onSave: (t) => widget.syncManager.addTask(t),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create New Task'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: filteredTasks.length,
                  itemBuilder: (ctx, idx) {
                    final task = filteredTasks[idx];
                    return TaskTile(
                      task: task,
                      onToggle: () => widget.syncManager.toggleTask(task),
                      onTap: () {
                        TaskEditorSheet.show(
                          context,
                          task: task,
                          onSave: (updated) => widget.syncManager.updateTask(updated),
                          onDelete: () => widget.syncManager.deleteTask(task),
                        );
                      },
                      onDelete: () => widget.syncManager.deleteTask(task),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _statusTab(String key, String label) {
    final isSel = _statusFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _statusFilter = key);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSel ? AppTheme.flameOrange.withOpacity(0.18) : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSel ? AppTheme.flameOrange : AppTheme.surfaceBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
              color: isSel ? AppTheme.flameOrange : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String id, String label, IconData icon, Color color) {
    final isSel = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedCategory = id);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSel ? color : AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? color : AppTheme.surfaceBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: isSel ? Colors.white : color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
