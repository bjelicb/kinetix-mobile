import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../domain/entities/user.dart';
import '../gradient_card.dart';
import 'profile_info_row_widget.dart';

class ProfilePersonalInfo extends StatelessWidget {
  final User user;

  const ProfilePersonalInfo({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          GradientCard(
            gradient: AppGradients.card,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                ProfileInfoRow(
                  label: 'Name',
                  value: user.name,
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),
                ProfileInfoRow(
                  label: 'Email',
                  value: user.email,
                  icon: Icons.email_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),
                ProfileInfoRow(
                  label: 'Role',
                  value: user.role,
                  icon: Icons.badge_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

