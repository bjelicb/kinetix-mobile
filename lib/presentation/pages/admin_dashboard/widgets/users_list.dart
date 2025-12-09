import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../../../domain/entities/user.dart';
import 'user_list_item.dart';

class UsersList extends StatelessWidget {
  final List<User> users;
  final String searchQuery;
  final String roleFilter;
  final ValueChanged<User> onUserTap;

  const UsersList({
    super.key,
    required this.users,
    required this.searchQuery,
    required this.roleFilter,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          searchQuery.isNotEmpty || roleFilter != 'ALL'
              ? 'No users found'
              : 'No users yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return UserListItem(
            user: user,
            onTap: () => onUserTap(user),
          );
        },
      ),
    );
  }
}

