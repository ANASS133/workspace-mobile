import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/sync_manager.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final SyncManager syncManager;

  const SettingsScreen({super.key, required this.syncManager});

  @override
  Widget build(BuildContext context) {
    final sm = syncManager;

    Color statusColor;
    String statusText;
    switch (sm.syncStatus) {
      case SyncStatus.synced:
        statusColor = AppTheme.successGreen;
        statusText = 'Connected & Synced';
        break;
      case SyncStatus.syncing:
        statusColor = AppTheme.infoSky;
        statusText = 'Syncing data...';
        break;
      case SyncStatus.offline:
        statusColor = AppTheme.priorityMed;
        statusText = 'Offline (cached locally)';
        break;
      case SyncStatus.error:
        statusColor = AppTheme.priorityHigh;
        statusText = 'Sync Error';
        break;
    }

    final lastSyncFormatted = sm.lastSyncTime != null
        ? DateFormat('MMM d, h:mm:ss a').format(sm.lastSyncTime!)
        : 'Never';

    return AnimatedBuilder(
      animation: AppTheme.themeModeNotifier,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings & Cloud Sync'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance & Theme Mode Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              AppTheme.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                              color: AppTheme.flameOrange,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Appearance & Theme',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: Text(
                            AppTheme.isDark ? 'Night Mode' : 'Light Mode',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              AppTheme.setThemeMode(ThemeMode.dark);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.isDark ? AppTheme.surfaceElevated : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.isDark ? AppTheme.flameOrange : AppTheme.surfaceBorder,
                                  width: AppTheme.isDark ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dark_mode,
                                    size: 16,
                                    color: AppTheme.isDark ? AppTheme.flameOrange : AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Night Mode',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: AppTheme.isDark ? FontWeight.w700 : FontWeight.w500,
                                      color: AppTheme.isDark ? AppTheme.textPrimary : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              AppTheme.setThemeMode(ThemeMode.light);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !AppTheme.isDark ? AppTheme.surfaceElevated : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !AppTheme.isDark ? AppTheme.flameOrange : AppTheme.surfaceBorder,
                                  width: !AppTheme.isDark ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.light_mode,
                                    size: 16,
                                    color: !AppTheme.isDark ? AppTheme.flameOrange : AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Light Mode',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: !AppTheme.isDark ? FontWeight.w700 : FontWeight.w500,
                                      color: !AppTheme.isDark ? AppTheme.textPrimary : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Supabase Status Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud_done, color: AppTheme.infoSky, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Supabase Cloud Database',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last Synced: $lastSyncFormatted',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    if (sm.lastError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${sm.lastError}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.priorityHigh),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: sm.syncStatus == SyncStatus.syncing
                          ? null
                          : () => sm.syncNow(),
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('Synchronize Cloud Now'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.flameOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Database & Environment Details
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Details',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    _detailRow('Project URL', 'https://cpagjchpwbsqjwnjnigk.supabase.co'),
                    _detailRow('Table Name', 'workspace_state'),
                    _detailRow('Architecture', 'Local-First + Cloud Reconciler'),
                    _detailRow('Total Local Tasks', '${sm.allTasks.length} items'),
                    _detailRow('Yearly Goals', '${sm.objectives.yearly.length} items'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Workspace Info Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Workspace Mobile',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Designed and tailored specifically for Anass\'s high-performance daily operations. Fully synchronized between your desktop dashboard and your mobile device with offline capabilities.',
                      style: TextStyle(fontSize: 12.5, height: 1.5, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version 1.0.0 • Mobile Edition',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
