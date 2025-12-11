import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../presentation/controllers/auth_controller.dart';
import '../gradient_card.dart';
import '../modals/about_dialog.dart' as custom;
import 'profile_setting_tile_widget.dart';

class ProfileSettings extends ConsumerWidget {
  const ProfileSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;
    final isTrainer = user?.role == 'TRAINER';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          GradientCard(
            gradient: AppGradients.card,
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                ProfileSettingTile(
                  title: 'Check-In History',
                  icon: Icons.history_rounded,
                  onTap: () {
                    context.go('/check-in/history');
                  },
                ),
                if (isTrainer) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ProfileSettingTile(
                    title: 'Analytics',
                    icon: Icons.analytics_rounded,
                    onTap: () {
                      context.go('/analytics');
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                ProfileSettingTile(
                  title: 'Settings',
                  icon: Icons.settings_rounded,
                  onTap: () {
                    AppHaptic.selection();
                    context.push('/settings');
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                ProfileSettingTile(
                  title: 'About',
                  icon: Icons.info_rounded,
                  onTap: () => custom.AboutDialog.show(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

