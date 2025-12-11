import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../core/utils/export_service.dart';
import 'settings/services/settings_service.dart';
import 'settings/services/cache_service.dart';
import 'settings/services/settings_sync_service.dart';
import 'settings/services/settings_export_service.dart';
import '../../presentation/widgets/settings/settings_section_widget.dart';
import '../../presentation/widgets/settings/notifications_section_widget.dart';
import '../../presentation/widgets/settings/appearance_section_widget.dart';
import '../../presentation/widgets/settings/data_storage_section_widget.dart';
import '../../presentation/widgets/settings/sync_section_widget.dart';
import '../../presentation/widgets/settings/about_section_widget.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  SettingsData _settings = SettingsData(
    workoutReminders: false,
    checkInReminders: false,
    pushNotifications: true,
    autoSync: true,
  );
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
    final settings = await SettingsService.loadSettings();
    setState(() {
      _settings = settings;
    });
  }

  Future<void> _loadCacheSize() async {
    final size = await CacheService.getCacheSize();
    setState(() {
      _cacheSize = size;
    });
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

  Future<void> _handleSettingChanged(String key, bool value) async {
    await SettingsService.saveSetting(key, value);
    await _loadSettings();
  }

  Future<void> _handleClearCache() async {
    final success = await CacheService.clearCache();
    if (success) {
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

  Future<void> _handleExport(String format) async {
    AppHaptic.medium();
    ExportResult result;
    if (format == 'CSV') {
      result = await SettingsExportService.exportToCSV();
    } else {
      result = await SettingsExportService.exportToJSON();
    }

    if (result.success && mounted) {
      AppHaptic.heavy();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.successMessage ?? 'Export successful'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: ${result.error}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleManualSync() async {
    setState(() {
      _isSyncing = true;
    });

    final result = await SettingsSyncService.performManualSync();

    setState(() {
      _lastSyncTime = result.lastSyncTime;
      _isSyncing = false;
    });

    if (result.success && mounted) {
      AppHaptic.heavy();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync completed successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (!result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync error: ${result.error}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
              SettingsSectionWidget(
                title: 'Notifications',
                icon: Icons.notifications_rounded,
                children: [
                  NotificationsSectionWidget(
                    settings: _settings,
                    onSettingChanged: _handleSettingChanged,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Appearance Section
              SettingsSectionWidget(
                title: 'Appearance',
                icon: Icons.palette_rounded,
                children: [
                  const AppearanceSectionWidget(),
                ],
              ),
              const SizedBox(height: 16),

              // Data & Storage Section
              SettingsSectionWidget(
                title: 'Data & Storage',
                icon: Icons.storage_rounded,
                children: [
                  DataStorageSectionWidget(
                    cacheSize: _cacheSize,
                    storageUsage: _storageUsage,
                    onClearCache: _handleClearCache,
                    onExport: _handleExport,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sync Section
              SettingsSectionWidget(
                title: 'Sync',
                icon: Icons.sync_rounded,
                children: [
                  SyncSectionWidget(
                    isSyncing: _isSyncing,
                    lastSyncTime: _lastSyncTime,
                    autoSync: _settings.autoSync,
                    onManualSync: _handleManualSync,
                    onAutoSyncChanged: (value) => _handleSettingChanged('auto_sync', value),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // About Section
              SettingsSectionWidget(
                title: 'About',
                icon: Icons.info_rounded,
                children: [
                  const AboutSectionWidget(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
