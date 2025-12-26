import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user.dart';
import '../../controllers/theme_controller.dart';
import '../../pages/dashboard/utils/theme_utils.dart';

/// Dashboard header widget with greeting, user info, avatar, and streak
class DashboardHeader extends ConsumerWidget {
  final User? user;

  const DashboardHeader({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ThemeUtils.getGreeting();
    final userName = user?.name ?? 'User';
    final theme = ref.watch(themeControllerProvider);
    final themeGradient = ThemeUtils.getThemeGradient(theme);
    final themeColor = ThemeUtils.getThemeColor(theme);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      foreground: Paint()
                        ..shader = themeGradient.createShader(
                          const Rect.fromLTWH(0, 0, 200, 70),
                        ),
                    ),
                  ),
                ],
              ),
              // Profile Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: themeGradient as Gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

