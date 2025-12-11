import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../presentation/widgets/profile/profile_header_widget.dart';
import '../../presentation/widgets/profile/profile_statistics_widget.dart';
import '../../presentation/widgets/profile/profile_personal_info_widget.dart';
import '../../presentation/widgets/profile/profile_settings_widget.dart';
import '../../presentation/widgets/profile/profile_logout_button_widget.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: authState.when(
            data: (user) => user == null
                ? _buildNotLoggedIn(context)
                : _buildProfileContent(context, ref, user),
            loading: () => const Center(
              child: ShimmerCard(height: 200),
            ),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_rounded,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Not logged in',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, user) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: ProfileHeader(user: user),
        ),
        
        // Statistics
        SliverToBoxAdapter(
          child: const ProfileStatistics(),
        ),
        
        // Personal Info
        SliverToBoxAdapter(
          child: ProfilePersonalInfo(user: user),
        ),
        
        // Settings
        SliverToBoxAdapter(
          child: const ProfileSettings(),
        ),
        
        // Logout
        SliverToBoxAdapter(
          child: const ProfileLogoutButton(),
        ),
        
        // Spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }
}
