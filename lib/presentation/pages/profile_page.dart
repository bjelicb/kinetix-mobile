import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../presentation/widgets/auth_overlay.dart';
import '../../presentation/widgets/progress_chart.dart';
import '../../presentation/widgets/pr_tracker.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/controllers/checkin_controller.dart';
import '../../domain/entities/workout.dart';
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
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.md),
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs/2),
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
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
        
        // Calculate volume progression (last 7 workouts)
        final sortedWorkouts = List.from(workouts)
          ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
        final recentWorkouts = sortedWorkouts.take(7).toList().reversed.toList();
        
        final volumeDataPoints = recentWorkouts.asMap().entries.map((entry) {
          final index = entry.key;
          final workout = entry.value;
          double volume = 0;
          for (final exercise in workout.exercises) {
            for (final set in exercise.sets) {
              if (set.isCompleted) {
                volume += set.weight * set.reps;
              }
            }
          }
          return ChartDataPoint(index.toDouble(), volume);
        }).toList();

        // Calculate personal records
        final prs = _calculatePersonalRecords(workouts);

        // Get best exercises (most frequently used)
        final exerciseCounts = <String, int>{};
        for (final workout in workouts) {
          for (final exercise in workout.exercises) {
            exerciseCounts[exercise.name] = (exerciseCounts[exercise.name] ?? 0) + 1;
          }
        }
        final bestExercises = exerciseCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(3);

        return Column(
          children: [
            // Quick Stats
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStatCard(context, '$completedWorkouts', 'Completed\nWorkouts', AppGradients.primary),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatCard(context, '$streak', 'Day\nStreak', AppGradients.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatCard(context, '${(totalVolume / 1000).toStringAsFixed(1)}k', 'Total\nVolume (kg)', AppGradients.success),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Volume Progression Chart
            if (volumeDataPoints.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ProgressChart(
                  dataPoints: volumeDataPoints,
                  title: 'Volume Progression (Last 7 Workouts)',
                  yAxisLabel: 'Volume (kg)',
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            
            // Personal Records
            if (prs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: PRTracker(personalRecords: prs),
              ),
            const SizedBox(height: AppSpacing.lg),
            
            // Best Exercises
            if (bestExercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GradientCard(
                gradient: AppGradients.card,
                padding: const EdgeInsets.all(20),
                pressEffect: true,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Best Exercises',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...bestExercises.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${entry.value}x',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            
            // View Full History Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: OutlinedButton.icon(
                onPressed: () {
                  AppHaptic.selection();
                  context.push('/workout-history');
                },
                icon: const Icon(Icons.history_rounded),
                label: const Text('View Full Workout History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
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
      error: (error, stackTrace) => Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Center(
          child: Text('Error loading statistics'),
        ),
      ),
    );
  }

  List<PersonalRecord> _calculatePersonalRecords(List<Workout> workouts) {
    final prs = <String, PersonalRecord>{};
    
    for (final workout in workouts) {
      if (!workout.isCompleted) continue;
      
      for (final exercise in workout.exercises) {
        for (final set in exercise.sets) {
          if (!set.isCompleted) continue;
          
          final key = '${exercise.id}_${set.reps}';
          final existingPR = prs[key];
          
          if (existingPR == null || set.weight > existingPR.weight) {
            prs[key] = PersonalRecord(
              exerciseId: exercise.id,
              exerciseName: exercise.name,
              weight: set.weight,
              reps: set.reps,
              date: workout.scheduledDate,
            );
          }
        }
      }
    }
    
    return prs.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Widget _buildStatCard(BuildContext context, String value, String label, Gradient gradient) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;
    final cardWidth = isSmallPhone ? 96.0 : 108.0;
    final cardHeight = isSmallPhone ? 96.0 : 108.0;
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: GradientCard(
        gradient: gradient,
        padding: const EdgeInsets.all(16),
        margin: EdgeInsets.zero,
        elevation: 6,
        pressEffect: true,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(BuildContext context, user) {
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
                _buildInfoRow(context, 'Name', user.name, Icons.person_rounded),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoRow(context, 'Email', user.email, Icons.email_rounded),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoRow(context, 'Role', user.role, Icons.badge_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }

  Widget _buildSettings(BuildContext context, WidgetRef ref) {
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
                _buildSettingTile(
                  context,
                  'Check-In History',
                  Icons.history_rounded,
                  () {
                    context.go('/check-in/history');
                  },
                ),
                if (isTrainer) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildSettingTile(
                    context,
                    'Analytics',
                    Icons.analytics_rounded,
                    () {
                      context.go('/analytics');
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _buildSettingTile(
                  context,
                  'Settings',
                  Icons.settings_rounded,
                  () {
                    AppHaptic.selection();
                    context.push('/settings');
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
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
    return SizedBox(
      height: 64,
      child: InkWell(
        onTap: () {
          AppHaptic.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Removed _buildSettingTileWithToggle - not used anymore (settings moved to SettingsPage)

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
      padding: const EdgeInsets.all(AppSpacing.lg),
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
