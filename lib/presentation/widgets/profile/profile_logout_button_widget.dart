import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../presentation/widgets/neon_button.dart';
import '../modals/logout_confirmation_dialog.dart';

class ProfileLogoutButton extends ConsumerWidget {
  const ProfileLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: NeonButton(
        text: 'Logout',
        icon: Icons.logout_rounded,
        onPressed: () => LogoutConfirmationDialog.show(context, ref),
        gradient: AppGradients.orangePink,
      ),
    );
  }
}

