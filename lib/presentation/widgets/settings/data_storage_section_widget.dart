import 'package:flutter/material.dart';
import '../../pages/settings/utils/format_utils.dart';
import 'clear_cache_dialog.dart';

/// Widget for data & storage settings section
class DataStorageSectionWidget extends StatelessWidget {
  final int cacheSize;
  final Map<String, int> storageUsage;
  final VoidCallback onClearCache;
  final Function(String) onExport;

  const DataStorageSectionWidget({
    super.key,
    required this.cacheSize,
    required this.storageUsage,
    required this.onClearCache,
    required this.onExport,
  });

  Future<void> _handleClearCache(BuildContext context) async {
    final confirmed = await ClearCacheDialog.show(context);
    if (confirmed) {
      onClearCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Cache Size'),
          subtitle: Text(FormatUtils.formatBytes(cacheSize)),
          trailing: TextButton(
            onPressed: () => _handleClearCache(context),
            child: const Text('Clear'),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Storage Usage'),
          subtitle: Text(
            'Workouts: ${storageUsage['workouts'] ?? 0}\n'
            'Check-ins: ${storageUsage['checkIns'] ?? 0}\n'
            'Users: ${storageUsage['users'] ?? 0}',
          ),
        ),
        const Divider(height: 1),
        ListTile(
          title: const Text('Export Data'),
          subtitle: const Text('Export workouts to CSV or JSON'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.file_download_rounded),
                onPressed: () => onExport('CSV'),
                tooltip: 'Export CSV',
              ),
              IconButton(
                icon: const Icon(Icons.code_rounded),
                onPressed: () => onExport('JSON'),
                tooltip: 'Export JSON',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

