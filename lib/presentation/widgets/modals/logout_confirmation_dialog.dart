import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptic_feedback.dart';
import '../../../presentation/controllers/auth_controller.dart';
import '../../../presentation/widgets/auth_overlay.dart';

class LogoutConfirmationDialog {
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    AppHaptic.light();
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Logout',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      AppHaptic.medium();
      
      // Show full-screen overlay during logout
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          builder: (BuildContext context) {
            return const AuthOverlay(
              statusText: 'Logging out...',
              loaderSize: 80,
            );
          },
        );
      }
      
      // Perform logout
      await ref.read(authControllerProvider.notifier).logout();
      
      // Navigate to login after a brief delay for smooth transition
      if (context.mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.go('/login');
        }
      }
    }
  }
}

