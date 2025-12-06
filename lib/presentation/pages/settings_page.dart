import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../core/utils/export_service.dart';
import '../../core/utils/image_cache_manager.dart';
import '../../services/sync_manager.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/datasources/remote_data_source.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _workoutReminders = false;
  bool _checkInReminders = false;
  bool _pushNotifications = true;
  bool _autoSync = true;
  int _cacheSize = 0;
  Map<String, int> _storageUsage = {};
  DateTime? _lastSyncTime;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCacheSize();
    _loadStorageUsage();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _workoutReminders = prefs.getBool('workout_reminders') ?? false;
      _checkInReminders = prefs.getBool('check_in_reminders') ?? false;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _autoSync = prefs.getBool('auto_sync') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    AppHaptic.selection();
  }

  Future<void> _loadCacheSize() async {
    try {
      final size = await ImageCacheManager.instance.getCacheSize();
      setState(() {
        _cacheSize = size;
      });
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _loadStorageUsage() async {
    try {
      final usage = await ExportService.instance.getStorageUsage();
      setState(() {
        _storageUsage = usage;
      });
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _clearCache() async {
    AppHaptic.medium();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Clear Cache?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: const Text('This will clear all cached images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              AppHaptic.medium();
              Navigator.of(context).pop(true);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ImageCacheManager.instance.clearCache();
      await _loadCacheSize();
      AppHaptic.heavy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _exportData(String format) async {
    AppHaptic.medium();
    try {
      if (format == 'CSV') {
        final csvData = await ExportService.instance.exportWorkoutsToCSV();
        if (csvData != null) {
          await ExportService.instance.shareExportedData(
            csvData,
            'kinetix_workouts_${DateTime.now().millisecondsSinceEpoch}.csv',
            'text/csv',
          );
          AppHaptic.heavy();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workouts exported to CSV'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } else if (format == 'JSON') {
        final jsonData = await ExportService.instance.exportWorkoutsToJSON();
        if (jsonData != null) {
          await ExportService.instance.shareJSONData(
            jsonData,
            'kinetix_workouts_${DateTime.now().millisecondsSinceEpoch}.json',
          );
          AppHaptic.heavy();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Workouts exported to JSON'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _manualSync() async {
    AppHaptic.medium();
    setState(() {
      _isSyncing = true;
    });

    try {
      final storage = FlutterSecureStorage();
      final localDataSource = LocalDataSource();
      final dio = Dio();
      final remoteDataSource = RemoteDataSource(dio, storage);
      final syncManager = SyncManager(localDataSource, remoteDataSource);

      await syncManager.sync();
      
      setState(() {
        _lastSyncTime = DateTime.now();
        _isSyncing = false;
      });

      AppHaptic.heavy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () {
              AppHaptic.light();
              context.pop();
            },
          ),
          title: Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Notifications Section
              GradientCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  title: const Text('Notifications'),
                  leading: const Icon(Icons.notifications_rounded, color: AppColors.primary),
                  children: [
                    _buildSwitchTile(
                      'Workout Reminders',
                      _workoutReminders,
                      (value) {
                        setState(() => _workoutReminders = value);
                        _saveSetting('workout_reminders', value);
                      },
                    ),
                    _buildSwitchTile(
                      'Check-in Reminders',
                      _checkInReminders,
                      (value) {
                        setState(() => _checkInReminders = value);
                        _saveSetting('check_in_reminders', value);
                      },
                    ),
                    _buildSwitchTile(
                      'Push Notifications',
                      _pushNotifications,
                      (value) {
                        setState(() => _pushNotifications = value);
                        _saveSetting('push_notifications', value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Appearance Section
              GradientCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  title: const Text('Appearance'),
                  leading: const Icon(Icons.palette_rounded, color: AppColors.primary),
                  children: [
                    ListTile(
                      title: const Text('Theme'),
                      subtitle: const Text('Dark (Light coming soon)'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        AppHaptic.selection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Light theme coming soon'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Data & Storage Section
              GradientCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  title: const Text('Data & Storage'),
                  leading: const Icon(Icons.storage_rounded, color: AppColors.primary),
                  children: [
                    ListTile(
                      title: const Text('Cache Size'),
                      subtitle: Text(_formatBytes(_cacheSize)),
                      trailing: TextButton(
                        onPressed: _clearCache,
                        child: const Text('Clear'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Storage Usage'),
                      subtitle: Text(
                        'Workouts: ${_storageUsage['workouts'] ?? 0}\n'
                        'Check-ins: ${_storageUsage['checkIns'] ?? 0}\n'
                        'Users: ${_storageUsage['users'] ?? 0}',
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
                            onPressed: () => _exportData('CSV'),
                            tooltip: 'Export CSV',
                          ),
                          IconButton(
                            icon: const Icon(Icons.code_rounded),
                            onPressed: () => _exportData('JSON'),
                            tooltip: 'Export JSON',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sync Section
              GradientCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  title: const Text('Sync'),
                  leading: const Icon(Icons.sync_rounded, color: AppColors.primary),
                  children: [
                    ListTile(
                      title: const Text('Sync Status'),
                      subtitle: Text(
                        _isSyncing
                            ? 'Syncing...'
                            : _lastSyncTime != null
                                ? 'Last sync: ${DateFormat('MMM dd, yyyy HH:mm').format(_lastSyncTime!)}'
                                : 'Never synced',
                      ),
                      trailing: _isSyncing
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
                        onPressed: _isSyncing ? null : _manualSync,
                      ),
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      'Auto Sync',
                      _autoSync,
                      (value) {
                        setState(() => _autoSync = value);
                        _saveSetting('auto_sync', value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // About Section
              GradientCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  title: const Text('About'),
                  leading: const Icon(Icons.info_rounded, color: AppColors.primary),
                  children: [
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return ListTile(
                            title: const Text('App Version'),
                            subtitle: Text('${snapshot.data!.version} (${snapshot.data!.buildNumber})'),
                          );
                        }
                        return const ListTile(
                          title: Text('App Version'),
                          subtitle: Text('Loading...'),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        AppHaptic.selection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Privacy Policy coming soon'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        AppHaptic.selection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Terms of Service coming soon'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Contact Support'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        AppHaptic.selection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contact support coming soon'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Open Source Licenses'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        AppHaptic.selection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Licenses coming soon'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
