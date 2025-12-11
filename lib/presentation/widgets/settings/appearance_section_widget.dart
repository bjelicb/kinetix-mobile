import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_feedback.dart';

/// Widget for appearance settings section
class AppearanceSectionWidget extends StatelessWidget {
  const AppearanceSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
    );
  }
}

