import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit_item.dart';
import '../models/objective_item.dart';
import '../theme/app_theme.dart';

class HabitEditorSheet extends StatefulWidget {
  final HabitItem? initialHabit;
  final DashboardObjectives? objectives;
  final Function(HabitItem) onSave;
  final VoidCallback? onDelete;

  const HabitEditorSheet({
    super.key,
    this.initialHabit,
    this.objectives,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    HabitItem? habit,
    DashboardObjectives? objectives,
    required Function(HabitItem) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HabitEditorSheet(
        initialHabit: habit,
        objectives: objectives,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<HabitEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _unitController;
  late String _kind;
  late List<int> _selectedDays;
  String? _selectedObjective;

  static const List<Map<String, dynamic>> _weekdays = [
    {'index': 1, 'label': 'Mon'},
    {'index': 2, 'label': 'Tue'},
    {'index': 3, 'label': 'Wed'},
    {'index': 4, 'label': 'Thu'},
    {'index': 5, 'label': 'Fri'},
    {'index': 6, 'label': 'Sat'},
    {'index': 0, 'label': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.initialHabit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _kind = h?.kind ?? 'check';
    _targetController = TextEditingController(text: (h?.target ?? 1).toString());
    _unitController = TextEditingController(text: h?.unit ?? '');
    _selectedDays = List<int>.from(h?.days ?? [0, 1, 2, 3, 4, 5, 6]);
    _selectedObjective = h?.objective;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a habit title')),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day per week')),
      );
      return;
    }

    final targetVal = int.tryParse(_targetController.text.trim()) ?? 1;

    final habit = (widget.initialHabit ?? HabitItem(
      id: 'habit_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
    )).copyWith(
      name: name,
      kind: _kind,
      target: _kind == 'quantity' ? targetVal : 1,
      unit: _kind == 'quantity' ? _unitController.text.trim() : '',
      days: _selectedDays,
      objective: _selectedObjective,
    );

    widget.onSave(habit);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialHabit != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.flameOrange.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note : Icons.auto_awesome,
                        color: AppTheme.flameOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing ? 'Edit Habit' : 'New Habit',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (isEditing && widget.onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: AppTheme.priorityHigh, size: 22),
                    tooltip: 'Delete Habit',
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDelete!();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Habit Name Input
            TextField(
              controller: _nameController,
              autofocus: !isEditing,
              decoration: InputDecoration(
                labelText: 'Habit Title',
                hintText: 'e.g. Read Quran, 100 Pushups, German Vocab...',
                prefixIcon: const Icon(Icons.title, size: 20),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppTheme.surfaceBorder),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Tracking Type Selector
            Text(
              'TRACKING TYPE',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _kind = 'check');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _kind == 'check' ? AppTheme.flameOrange.withOpacity(0.14) : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _kind == 'check' ? AppTheme.flameOrange : AppTheme.surfaceBorder,
                          width: _kind == 'check' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: _kind == 'check' ? AppTheme.flameOrange : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Yes / No Check',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _kind == 'check' ? FontWeight.w700 : FontWeight.w500,
                              color: _kind == 'check' ? AppTheme.flameOrange : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _kind = 'quantity');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _kind == 'quantity' ? AppTheme.flameOrange.withOpacity(0.14) : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _kind == 'quantity' ? AppTheme.flameOrange : AppTheme.surfaceBorder,
                          width: _kind == 'quantity' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.numbers,
                            size: 18,
                            color: _kind == 'quantity' ? AppTheme.flameOrange : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Numeric Target',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _kind == 'quantity' ? FontWeight.w700 : FontWeight.w500,
                              color: _kind == 'quantity' ? AppTheme.flameOrange : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // If numeric target: Target + Unit fields
            if (_kind == 'quantity') ...[
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Daily Goal',
                        hintText: 'e.g. 100',
                        filled: true,
                        fillColor: AppTheme.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.surfaceBorder),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        hintText: 'e.g. reps, pages, min',
                        filled: true,
                        fillColor: AppTheme.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.surfaceBorder),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Frequency & Days of Week
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FREQUENCY',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppTheme.textMuted,
                  ),
                ),
                Row(
                  children: [
                    _buildPresetChip('Daily', [0, 1, 2, 3, 4, 5, 6]),
                    const SizedBox(width: 6),
                    _buildPresetChip('Weekdays', [1, 2, 3, 4, 5]),
                    const SizedBox(width: 6),
                    _buildPresetChip('Weekends', [6, 0]),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Weekday Chips Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weekdays.map((item) {
                final dayIdx = item['index'] as int;
                final label = item['label'] as String;
                final isSelected = _selectedDays.contains(dayIdx);

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        if (_selectedDays.length > 1) {
                          _selectedDays.remove(dayIdx);
                        }
                      } else {
                        _selectedDays.add(dayIdx);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.flameOrange : AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.flameOrange : AppTheme.surfaceBorder,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Optional Linked Objective
            if (widget.objectives != null) ...[
              Text(
                'LINK TO OBJECTIVE (OPTIONAL)',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedObjective,
                    isExpanded: true,
                    hint: Text('None', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No linked objective', style: TextStyle(fontSize: 13)),
                      ),
                      ...widget.objectives!.yearly.map((o) => DropdownMenuItem<String?>(
                            value: 'yearly:${o.id}',
                            child: Text('🎯 Yearly: ${o.text}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          )),
                      ...widget.objectives!.monthly.map((o) => DropdownMenuItem<String?>(
                            value: 'monthly:${o.id}',
                            child: Text('📅 Monthly: ${o.text}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          )),
                      ...widget.objectives!.weekly.map((o) => DropdownMenuItem<String?>(
                            value: 'weekly:${o.id}',
                            child: Text('⚡ Weekly: ${o.text}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          )),
                    ],
                    onChanged: (val) => setState(() => _selectedObjective = val),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check, size: 20),
                label: Text(
                  isEditing ? 'Save Changes' : 'Create Habit',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.flameOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, List<int> days) {
    final isSelected = _selectedDays.length == days.length &&
        _selectedDays.every(days.contains);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDays = List<int>.from(days));
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.flameOrange.withOpacity(0.18) : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.flameOrange : AppTheme.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.flameOrange : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
