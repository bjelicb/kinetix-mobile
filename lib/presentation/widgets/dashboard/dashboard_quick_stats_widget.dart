import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../controllers/theme_controller.dart';
import '../../pages/dashboard/utils/theme_utils.dart';
import 'dashboard_stat_card_widget.dart';

/// Quick stats section widget
class DashboardQuickStats extends ConsumerWidget {
  const DashboardQuickStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final themeGradient = ThemeUtils.getThemeGradient(theme);

    return Container(
      height: 105,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: DashboardStatCard(
              value: '12',
              label: 'Workouts\nThis Week',
              gradient: LinearGradient(
                colors: themeGradient.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: DashboardStatCard(
              value: '2.4k',
              label: 'Total\nVolume (kg)',
              gradient: AppGradients.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: DashboardStatCard(
              value: '85%',
              label: 'Completion\nRate',
              gradient: AppGradients.success,
            ),
          ),
        ],
      ),
    );
  }
}

