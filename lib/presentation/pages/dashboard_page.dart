import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart' show AppColors, AppSpacing, TrainerThemes;
import '../../core/theme/gradients.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/theme_controller.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../presentation/widgets/empty_state.dart';
import '../../presentation/widgets/nutrition_summary_card.dart';
import '../../presentation/widgets/client_alerts_card.dart';
import '../../presentation/widgets/appointments_card.dart';
import '../../presentation/widgets/search_bar.dart' as kinetix_search;
import '../../presentation/widgets/filter_bottom_sheet.dart';
import '../../presentation/widgets/plans/current_plan_card.dart';
import '../../presentation/widgets/balance_card.dart';
import '../../presentation/widgets/weigh_in_card.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../services/exercise_library_service.dart';
import '../../data/datasources/remote_data_source.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String? _searchQuery;
  FilterOptions _filterOptions = FilterOptions();
  List<String> _availableMuscleGroups = [];
  Map<String, dynamic>? _balanceData;
  bool _loadingBalance = false;
  Map<String, dynamic>? _weighInData;
  bool _loadingWeighIn = false;

  @override
  void initState() {
    super.initState();
    _loadMuscleGroups();
    _loadBalance();
    _loadWeighIn();
  }

  Future<void> _loadBalance() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user?.role != 'CLIENT') {
      debugPrint('[DashboardPage] Skipping balance load - user is not CLIENT (role: ${user?.role})');
      return;
    }

    debugPrint('[DashboardPage] _loadBalance START - Loading balance for client');

    setState(() {
      _loadingBalance = true;
    });

    try {
      final storage = FlutterSecureStorage();
      final dio = Dio();
      final remoteDataSource = RemoteDataSource(dio, storage);
      
      debugPrint('[DashboardPage] Calling getGamificationStatus API...');
      // Get balance from gamification status (includes balance info)
      final status = await remoteDataSource.getGamificationStatus();
      
      debugPrint('[DashboardPage] API Response: $status');
      debugPrint('[DashboardPage] Balance: ${status['balance']}, MonthlyBalance: ${status['monthlyBalance']}');
      
      final balance = status['balance'] ?? 0.0;
      final monthlyBalance = status['monthlyBalance'] ?? 0.0;
      
      setState(() {
        _balanceData = {
          'balance': balance,
          'monthlyBalance': monthlyBalance,
          'lastBalanceReset': status['lastBalanceReset'],
        };
        _loadingBalance = false;
      });
      
      debugPrint('[DashboardPage] _loadBalance SUCCESS - Balance: ${balance}€, Monthly: ${monthlyBalance}€');
    } catch (e, stackTrace) {
      debugPrint('[DashboardPage] _loadBalance ERROR: $e');
      debugPrint('[DashboardPage] Stack trace: $stackTrace');
      setState(() {
        _loadingBalance = false;
      });
      // Silently fail - balance is not critical
    }
  }

  Future<void> _loadWeighIn() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user?.role != 'CLIENT') {
      debugPrint('[DashboardPage] Skipping weigh-in load - user is not CLIENT (role: ${user?.role})');
      return;
    }

    debugPrint('[DashboardPage] _loadWeighIn START - Loading latest weigh-in for client');

    setState(() {
      _loadingWeighIn = true;
    });

    try {
      final storage = FlutterSecureStorage();
      final dio = Dio();
      final remoteDataSource = RemoteDataSource(dio, storage);
      
      debugPrint('[DashboardPage] Calling getLatestWeighIn API...');
      final latestWeighIn = await remoteDataSource.getLatestWeighIn();
      
      debugPrint('[DashboardPage] getLatestWeighIn API Response: $latestWeighIn');
      
      setState(() {
        _weighInData = latestWeighIn;
        _loadingWeighIn = false;
      });
      
      if (latestWeighIn != null) {
        debugPrint('[DashboardPage] _loadWeighIn SUCCESS - Weight: ${latestWeighIn['weight']}kg, Date: ${latestWeighIn['date']}');
      } else {
        debugPrint('[DashboardPage] _loadWeighIn SUCCESS - No weigh-in found');
      }
    } catch (e, stackTrace) {
      debugPrint('[DashboardPage] _loadWeighIn ERROR: $e');
      debugPrint('[DashboardPage] Stack trace: $stackTrace');
      setState(() {
        _loadingWeighIn = false;
      });
      // Silently fail - weigh-in is not critical
    }
  }

  Future<void> _loadMuscleGroups() async {
    try {
      final exercises = await ExerciseLibraryService.instance.getAllExercises();
      final muscleGroups = exercises.map((e) => e.targetMuscle).toSet().toList();
      setState(() {
        _availableMuscleGroups = muscleGroups;
      });
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _showFilterSheet() async {
    AppHaptic.selection();
    final result = await FilterBottomSheet.show(
      context: context,
      initialFilters: _filterOptions,
      availableMuscleGroups: _availableMuscleGroups,
      availableExercises: [], // Can be populated if needed
    );

    if (result != null) {
      setState(() {
        _filterOptions = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutsState = ref.watch(workoutControllerProvider);
    final authState = ref.watch(authControllerProvider);
    
    // Get filtered workouts
    final filteredWorkouts = ref.read(workoutControllerProvider.notifier).filterWorkouts(
      _searchQuery,
      _filterOptions.hasActiveFilters ? _filterOptions : null,
    );
    
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: workoutsState.when(
            data: (workouts) {
              final user = authState.valueOrNull;
              final isTrainer = user?.role == 'TRAINER';
              
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(workoutControllerProvider);
                  await _loadBalance();
                  await _loadWeighIn();
                },
                color: AppColors.primary,
                child: CustomScrollView(
                  slivers: [
                    // Premium Header
                    SliverToBoxAdapter(
                      child: _buildHeader(context, user, ref),
                    ),
                    
                    // Search Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: kinetix_search.SearchBar(
                          hintText: 'Search workouts...',
                          onChanged: (query) {
                            setState(() {
                              _searchQuery = query.isEmpty ? null : query;
                            });
                          },
                          onFilterTap: _showFilterSheet,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                    
                    // Current Plan Card (Client only - not for Admin or Trainer)
                    if (!isTrainer && user?.role == 'CLIENT')
                      const SliverToBoxAdapter(
                        child: CurrentPlanCard(),
                      ),
                    
                    // Balance Card (Client only)
                    if (!isTrainer)
                      SliverToBoxAdapter(
                        child: _loadingBalance
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : _balanceData != null
                                ? BalanceCard(
                                    balance: (_balanceData!['balance'] as num?)?.toDouble() ?? 0.0,
                                    monthlyBalance: (_balanceData!['monthlyBalance'] as num?)?.toDouble() ?? 0.0,
                                    lastBalanceReset: _balanceData!['lastBalanceReset'] != null
                                        ? DateTime.parse(_balanceData!['lastBalanceReset'])
                                        : null,
                                  )
                                : const SizedBox.shrink(),
                      ),
                    
                    // Weigh-In Card (Client only)
                    if (!isTrainer)
                      SliverToBoxAdapter(
                        child: WeighInCard(
                          latestWeighIn: _weighInData,
                          isLoading: _loadingWeighIn ?? false,
                          onRefresh: () {
                            _loadWeighIn();
                          },
                        ),
                      ),
                    
                    // Quick Stats (Client only)
                    if (!isTrainer)
                      SliverToBoxAdapter(
                        child: _buildQuickStats(context),
                      ),
                    
                    // Nutrition Summary (Client only)
                    if (!isTrainer)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: NutritionSummaryCard(
                            calories: 1850,
                            protein: 120,
                            carbs: 220,
                            fats: 65,
                          ),
                        ),
                      ),
                    
                    // Today's Mission Card
                    SliverToBoxAdapter(
                      child: _buildTodaysMission(context, filteredWorkouts, ref),
                    ),
                    
                    // Role-dependent content
                    if (isTrainer)
                      SliverToBoxAdapter(
                        child: _buildTrainerContent(context),
                      )
                    else
                      SliverToBoxAdapter(
                        child: _buildClientContent(context, filteredWorkouts, ref),
                      ),
                    
                    // Spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              );
            },
            loading: () => _buildLoadingState(context),
            error: (error, stack) => _buildErrorState(context, error),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user, WidgetRef ref) {
    final greeting = _getGreeting();
    final userName = user?.name ?? 'User';
    final theme = ref.watch(themeControllerProvider);
    final themeGradient = _getThemeGradient(theme);
    final themeColor = _getThemeColor(theme);
    
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
                  gradient: themeGradient,
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
          const SizedBox(height: AppSpacing.md),
          // Streak Counter
          GradientCard(
            gradient: themeGradient,
            padding: const EdgeInsets.all(16),
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7 Day Streak',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Keep it up!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final themeGradient = _getThemeGradient(theme);
    
    return Container(
      height: 105,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: _buildStatCardExpanded(context, '12', 'Workouts\nThis Week', themeGradient)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _buildStatCardExpanded(context, '2.4k', 'Total\nVolume (kg)', AppGradients.secondary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _buildStatCardExpanded(context, '85%', 'Completion\nRate', AppGradients.success)),
        ],
      ),
    );
  }


  Widget _buildStatCardExpanded(BuildContext context, String value, String label, Gradient gradient) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;
    return SizedBox(
      height: isSmallPhone ? 88 : 96,
      child: GradientCard(
        gradient: gradient,
        padding: const EdgeInsets.all(12),
        margin: EdgeInsets.zero,
        elevation: 6,
        pressEffect: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: isSmallPhone ? 20 : 22,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                  fontSize: isSmallPhone ? 9.5 : 10,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysMission(BuildContext context, workouts, WidgetRef ref) {
    final todayWorkout = workouts.isNotEmpty ? workouts.first : null;
    final theme = ref.watch(themeControllerProvider);
    final themeGradient = _getThemeGradient(theme);
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Mission",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
            if (todayWorkout == null)
              EmptyState(
                icon: Icons.fitness_center_rounded,
                title: 'No workout scheduled',
                message: 'Take a rest day or schedule a workout',
                actionLabel: 'Schedule Workout',
                onAction: () {
                  AppHaptic.selection();
                  context.go('/calendar');
                },
              )
          else
            GradientCard(
              gradient: themeGradient,
              padding: const EdgeInsets.all(20),
              showGlow: true,
              pressEffect: true,
              onTap: () {
                AppHaptic.selection();
                context.go('/workout/${todayWorkout.id}');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todayWorkout.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(todayWorkout.scheduledDate),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (todayWorkout.isCompleted)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 32,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeonButton(
                    text: todayWorkout.isCompleted ? 'View Details' : 'Start Workout',
                    icon: todayWorkout.isCompleted ? Icons.visibility : Icons.play_arrow,
                    onPressed: () {
                      AppHaptic.selection();
                context.go('/workout/${todayWorkout.id}');
                    },
                    gradient: AppGradients.secondary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClientContent(BuildContext context, workouts, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Workouts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (workouts.isEmpty)
            EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'No workouts yet',
              message: 'Start your fitness journey by scheduling your first workout',
              actionLabel: 'Schedule Workout',
              onAction: () {
                AppHaptic.selection();
                context.go('/calendar');
              },
            )
          else
            SizedBox(
              height: workouts.length > 5 ? 400 : null,
              child: ListView.builder(
                shrinkWrap: workouts.length <= 5,
                physics: workouts.length > 5 ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                itemCount: workouts.length > 5 ? 5 : workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: GradientCard(
                      gradient: AppGradients.card,
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        AppHaptic.selection();
                        context.go('/workout/${workout.id}');
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: workout.isCompleted
                                  ? AppGradients.success
                                  : _getThemeGradient(ref.watch(themeControllerProvider)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              workout.isCompleted
                                  ? Icons.check_rounded
                                  : Icons.fitness_center_rounded,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workout.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(workout.scheduledDate),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: AppColors.error,
                            ),
                            onPressed: () => _showDeleteDialog(context, workout.id, ref),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrainerContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClientAlertsCard(),
          const SizedBox(height: AppSpacing.lg),
          AppointmentsCard(),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ShimmerCard(height: 200),
        const SizedBox(height: AppSpacing.md),
        ShimmerCard(height: 120),
        const SizedBox(height: AppSpacing.md),
        ShimmerCard(height: 120),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error loading dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  void _showDeleteDialog(BuildContext context, String workoutId, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Workout'),
        content: const Text('Are you sure you want to delete this workout? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(workoutControllerProvider.notifier).deleteWorkout(workoutId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workout deleted successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting workout: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Gradient _getThemeGradient(TrainerTheme theme) {
    switch (theme) {
      case TrainerTheme.milan:
        return TrainerThemes.milanGradient;
      case TrainerTheme.aca:
        return TrainerThemes.acaGradient;
      case TrainerTheme.neutral:
        return AppGradients.primary;
    }
  }

  Color _getThemeColor(TrainerTheme theme) {
    switch (theme) {
      case TrainerTheme.milan:
        return TrainerThemes.milanPrimary;
      case TrainerTheme.aca:
        return TrainerThemes.acaPrimary;
      case TrainerTheme.neutral:
        return AppColors.primary;
    }
  }
}


