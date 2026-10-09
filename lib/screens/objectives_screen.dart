import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/objective_item.dart';
import '../services/sync_manager.dart';
import '../theme/app_theme.dart';

class ObjectivesScreen extends StatefulWidget {
  final SyncManager syncManager;

  const ObjectivesScreen({super.key, required this.syncManager});

  @override
  State<ObjectivesScreen> createState() => _ObjectivesScreenState();
}

class _ObjectivesScreenState extends State<ObjectivesScreen> {
  void _promptAddObjective(String type, String title) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add $title', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter milestone or target...',
          ),
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              widget.syncManager.addObjective(controller.text.trim(), type);
              Navigator.of(ctx).pop();
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.syncManager.addObjective(controller.text.trim(), type);
                Navigator.of(ctx).pop();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.flameOrange),
            child: const Text('Add Target'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sm = widget.syncManager;
    final obj = sm.objectives;

    return RefreshIndicator(
      onRefresh: () => sm.syncNow(),
      color: AppTheme.flameOrange,
      backgroundColor: AppTheme.surfaceElevated,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes, color: AppTheme.flameOrange, size: 24),
              const SizedBox(width: 8),
              Text(
                'Objectives & Roadmap',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Keep your long-term vision, monthly targets, and weekly sprint aligned.',
            style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),

          // 1. Yearly Goals Card
          _objectiveSection(
            type: 'yearly',
            title: 'Yearly Goals',
            subtitle: 'Major Milestones',
            icon: Icons.flag,
            color: const Color(0xFF6366F1), // Indigo
            items: obj.yearly,
          ),
          const SizedBox(height: 16),

          // 2. Monthly Objectives Card
          _objectiveSection(
            type: 'monthly',
            title: 'Monthly Objectives',
            subtitle: 'Current Month Focus',
            icon: Icons.calendar_month,
            color: const Color(0xFF06B6D4), // Cyan
            items: obj.monthly,
          ),
          const SizedBox(height: 16),

          // 3. Weekly Targets Card
          _objectiveSection(
            type: 'weekly',
            title: 'Weekly Targets',
            subtitle: '7-Day Sprint',
            icon: Icons.bolt,
            color: AppTheme.flameOrange,
            items: obj.weekly,
          ),
        ],
      ),
    );
  }

  Widget _objectiveSection({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<ObjectiveItem> items,
  }) {
    final total = items.length;
    final completed = items.where((i) => i.completed).length;
    final progress = total == 0 ? 0.0 : completed / total;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percent%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),

          // Items list
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No $title added yet.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
              ),
            )
          else
            ...items.map((item) => _itemRow(item, type, color)),

          const SizedBox(height: 10),
          // Add button
          OutlinedButton.icon(
            onPressed: () => _promptAddObjective(type, title),
            icon: const Icon(Icons.add, size: 16),
            label: Text('Add $title Target'),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withOpacity(0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(ObjectiveItem item, String type, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceBorder.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.syncManager.toggleObjective(item, type);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: item.completed ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.completed ? color : AppTheme.textMuted,
                  width: 1.6,
                ),
              ),
              child: item.completed
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.text,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: item.completed ? AppTheme.textMuted : AppTheme.textPrimary,
                decoration: item.completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: AppTheme.textMuted),
            tooltip: 'Remove',
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.syncManager.deleteObjective(item.id, type);
            },
          ),
        ],
      ),
    );
  }
}
