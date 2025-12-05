import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/controllers/checkin_controller.dart';
import '../../core/utils/haptic_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
        // Premium Header
        SliverToBoxAdapter(
          child: _buildHeader(context, user),
        ),
        
        // Statistics
        SliverToBoxAdapter(
          child: _buildStatistics(context, ref),
        ),
        
        // Personal Info
        SliverToBoxAdapter(
          child: _buildPersonalInfo(context, user),
        ),
        
        // Settings
        SliverToBoxAdapter(
          child: _buildSettings(context, ref),
        ),
        
        // Logout
        SliverToBoxAdapter(
          child: _buildLogoutButton(context, ref),
        ),
        
        // Spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: user.role == 'TRAINER'
                  ? AppGradients.orangePink
                  : AppGradients.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(BuildContext context, WidgetRef ref) {
    final workoutsState = ref.watch(workoutControllerProvider);
    final checkInsState = ref.watch(checkInControllerProvider);
    
    return workoutsState.when(
      data: (workouts) {
        final totalWorkouts = workouts.length;
        final completedWorkouts = workouts.where((w) => w.isCompleted).length;
        
        // Calculate total volume
        double totalVolume = 0;
        for (final workout in workouts) {
          for (final exercise in workout.exercises) {
            for (final set in exercise.sets) {
              if (set.isCompleted) {
                totalVolume += set.weight * set.reps;
              }
            }
          }
        }
        
        // Calculate streak from check-ins
        int streak = 0;
        checkInsState.whenData((checkIns) {
          if (checkIns.isEmpty) return;
          final sortedCheckIns = List.from(checkIns)
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          DateTime? lastDate;
          for (final checkIn in sortedCheckIns) {
            final checkInDate = DateTime(
              checkIn.timestamp.year,
              checkIn.timestamp.month,
              checkIn.timestamp.day,
            );
            
            if (lastDate == null) {
              final today = DateTime.now();
              final todayDate = DateTime(today.year, today.month, today.day);
              if (checkInDate == todayDate || checkInDate == todayDate.subtract(const Duration(days: 1))) {
                streak = 1;
                lastDate = checkInDate;
              } else {
                break;
              }
            } else {
              final expectedDate = lastDate.subtract(const Duration(days: 1));
              if (checkInDate == expectedDate) {
                streak++;
                lastDate = checkInDate;
              } else {
                break;
              }
            }
          }
        });
        
        return Container(
          height: 120,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildStatCard(context, '$completedWorkouts', 'Completed\nWorkouts', AppGradients.primary),
              const SizedBox(width: 12),
              _buildStatCard(context, '$streak', 'Day\nStreak', AppGradients.secondary),
              const SizedBox(width: 12),
              _buildStatCard(context, '${(totalVolume / 1000).toStringAsFixed(1)}k', 'Total\nVolume (kg)', AppGradients.success),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            ShimmerCard(height: 100, width: 100),
            const SizedBox(width: 12),
            ShimmerCard(height: 100, width: 100),
            const SizedBox(width: 12),
            ShimmerCard(height: 100, width: 100),
          ],
        ),
      ),
      error: (_, __) => Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Center(
          child: Text('Error loading statistics'),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, Gradient gradient) {
    return GradientCard(
      gradient: gradient,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(BuildContext context, user) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          GradientCard(
            gradient: AppGradients.card,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(context, 'Name', user.name, Icons.person_rounded),
                const Divider(height: 32),
                _buildInfoRow(context, 'Email', user.email, Icons.email_rounded),
                const Divider(height: 32),
                _buildInfoRow(context, 'Role', user.role, Icons.badge_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;
    final isTrainer = user?.role == 'TRAINER';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          GradientCard(
            gradient: AppGradients.card,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingTile(
                  context,
                  'Check-In History',
                  Icons.history_rounded,
                  () {
                    context.go('/check-in/history');
                  },
                ),
                if (isTrainer) ...[
                  const Divider(height: 1),
                  _buildSettingTile(
                    context,
                    'Analytics',
                    Icons.analytics_rounded,
                    () {
                      context.go('/analytics');
                    },
                  ),
                ],
                const Divider(height: 1),
                _buildSettingTileWithToggle(
                  context,
                  'Notifications',
                  Icons.notifications_rounded,
                  true, // Mock value
                  (value) {
                    AppHaptic.selection();
                    // TODO: Save notification preference
                  },
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  context,
                  'Theme',
                  Icons.palette_rounded,
                  () {
                    // TODO: Open theme settings
                  },
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  context,
                  'Data & Sync',
                  Icons.sync_rounded,
                  () {
                    // TODO: Open sync settings
                  },
                ),
                const Divider(height: 1),
                _buildSettingTile(
                  context,
                  'About',
                  Icons.info_rounded,
                  () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
      ),
      onTap: () {
        AppHaptic.selection();
        onTap();
      },
    );
  }

  Widget _buildSettingTileWithToggle(
    BuildContext context,
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    AppHaptic.selection();
    final packageInfo = await PackageInfo.fromPlatform();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'About Kinetix',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version: ${packageInfo.version}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Build: ${packageInfo.buildNumber}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kinetix - Your personal fitness companion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: NeonButton(
        text: 'Logout',
        icon: Icons.logout_rounded,
        onPressed: () => _showLogoutConfirmation(context, ref),
        gradient: AppGradients.orangePink,
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context, WidgetRef ref) async {
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
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}
