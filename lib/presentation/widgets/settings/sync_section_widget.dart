import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_feedback.dart';
import 'settings_switch_tile_widget.dart';

/// Widget for sync settings section
class SyncSectionWidget extends StatelessWidget {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final bool autoSync;
  final VoidCallback onManualSync;
  final Function(bool) onAutoSyncChanged;

  const SyncSectionWidget({
    super.key,
    required this.isSyncing,
    required this.lastSyncTime,
    required this.autoSync,
    required this.onManualSync,
    required this.onAutoSyncChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Sync Status'),
          subtitle: Text(
            isSyncing
                ? 'Syncing...'
                : lastSyncTime != null
                    ? 'Last sync: ${DateFormat('MMM dd, yyyy HH:mm').format(lastSyncTime!)}'
                    : 'Never synced',
          ),
          trailing: isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_rounded, color: AppColors.success),
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Manual Sync'),
          subtitle: const Text('Sync data with server now'),
          trailing: IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: isSyncing ? null : () {
              AppHaptic.medium();
              onManualSync();
            },
          ),
        ),
        const Divider(height: 1),
        SettingsSwitchTileWidget(
          title: 'Auto Sync',
          value: autoSync,
          onChanged: (value) {
            AppHaptic.selection();
            onAutoSyncChanged(value);
          },
        ),
      ],
    );
  }
}

