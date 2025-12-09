import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../core/theme/gradients.dart';
import '../../../widgets/cyber_loader.dart';
import '../../../widgets/gradient_card.dart';
import '../../../widgets/neon_button.dart';
import '../../../widgets/search_bar.dart' as kinetix_search;
import 'filter_chip.dart';

class UserManagementCard extends StatelessWidget {
  final VoidCallback onCreateUser;
  final ValueChanged<String> onSearchChanged;
  final String roleFilter;
  final ValueChanged<String> onRoleFilterChanged;
  final bool isLoading;
  final Widget usersList;

  const UserManagementCard({
    super.key,
    required this.onCreateUser,
    required this.onSearchChanged,
    required this.roleFilter,
    required this.onRoleFilterChanged,
    required this.isLoading,
    required this.usersList,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      showCyberBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people_rounded,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'User Manage',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
              NeonButton(
                text: 'Create',
                icon: Icons.add_rounded,
                onPressed: onCreateUser,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          kinetix_search.SearchBar(
            hintText: 'Search users...',
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                DashboardFilterChip(
                  label: 'All',
                  selected: roleFilter == 'ALL',
                  onSelected: (_) => onRoleFilterChanged('ALL'),
                ),
                const SizedBox(width: AppSpacing.xs),
                DashboardFilterChip(
                  label: 'Clients',
                  selected: roleFilter == 'CLIENT',
                  onSelected: (_) => onRoleFilterChanged('CLIENT'),
                ),
                const SizedBox(width: AppSpacing.xs),
                DashboardFilterChip(
                  label: 'Trainers',
                  selected: roleFilter == 'TRAINER',
                  onSelected: (_) => onRoleFilterChanged('TRAINER'),
                ),
                const SizedBox(width: AppSpacing.xs),
                DashboardFilterChip(
                  label: 'Admins',
                  selected: roleFilter == 'ADMIN',
                  onSelected: (_) => onRoleFilterChanged('ADMIN'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AnimatedCyberLoader(size: 40),
              ),
            )
          else
            usersList,
        ],
      ),
    );
  }
}

