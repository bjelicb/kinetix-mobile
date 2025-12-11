import 'package:flutter/material.dart';
import '../../pages/settings/services/settings_service.dart';
import '../../../core/utils/haptic_feedback.dart';
import 'settings_switch_tile_widget.dart';

/// Widget for notifications settings section
class NotificationsSectionWidget extends StatelessWidget {
  final SettingsData settings;
  final Function(String, bool) onSettingChanged;

  const NotificationsSectionWidget({
    super.key,
    required this.settings,
    required this.onSettingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsSwitchTileWidget(
          title: 'Workout Reminders',
          value: settings.workoutReminders,
          onChanged: (value) {
            AppHaptic.selection();
            onSettingChanged('workout_reminders', value);
          },
        ),
        SettingsSwitchTileWidget(
          title: 'Check-in Reminders',
          value: settings.checkInReminders,
          onChanged: (value) {
            AppHaptic.selection();
            onSettingChanged('check_in_reminders', value);
          },
        ),
        SettingsSwitchTileWidget(
          title: 'Push Notifications',
          value: settings.pushNotifications,
          onChanged: (value) {
            AppHaptic.selection();
            onSettingChanged('push_notifications', value);
          },
        ),
      ],
    );
  }
}

