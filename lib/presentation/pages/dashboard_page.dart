import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/workout.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
// Search and filter removed - not needed on dashboard
import '../../presentation/widgets/plans/current_plan_card.dart';
import '../../presentation/controllers/plan_controller.dart';
import '../../presentation/widgets/balance_card.dart';
import '../../presentation/widgets/weigh_in_card.dart';
import '../../presentation/widgets/ai_messages_preview_card.dart';
// WorkoutCalendarWidget removed - use Calendar page instead
import '../../presentation/widgets/nutrition_summary_card.dart';
// Haptic feedback removed - not needed without interactive elements
import '../../data/datasources/remote_data_source.dart';
import 'dashboard/services/dashboard_data_service.dart';
import 'dashboard/services/paywall_service.dart';
import '../widgets/dashboard/dashboard_header_widget.dart';
import '../widgets/dashboard/todays_mission_widget.dart';
// DashboardClientContent removed - Recent Workouts not needed
import '../widgets/dashboard/dashboard_trainer_content_widget.dart';
import '../widgets/dashboard/dashboard_state_widgets.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with WidgetsBindingObserver {
  // Search and filter removed - not needed on dashboard
  Map<String, dynamic>? _balanceData;
  bool _loadingBalance = false;
  Map<String, dynamic>? _weighInData;
  bool _loadingWeighIn = false;

  late final RemoteDataSource _remoteDataSource;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final storage = FlutterSecureStorage();
    final dio = Dio();
    _remoteDataSource = RemoteDataSource(dio, storage);

    // _loadMuscleGroups(); // Removed - not needed
    _loadBalance().then((_) => _checkPaywall());
    _loadWeighIn();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app returns to foreground, refresh balance and check paywall
    if (state == AppLifecycleState.resumed) {
      debugPrint('[DashboardPage] App resumed - refreshing balance and checking paywall');
      refreshBalance();
    }
  }

  /// Refresh balance - can be called from outside (e.g., after payment)
  void refreshBalance() {
    debugPrint('[DashboardPage] refreshBalance() called - reloading balance');
    _loadBalance().then((_) => _checkPaywall());
  }

  Future<void> _checkPaywall() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    final balanceData = _balanceData;

    if (mounted) {
      PaywallService.checkPaywall(
        context,
        balanceData,
        user,
        onPaymentComplete: refreshBalance, // Refresh balance after payment
      );
    }
  }

  Future<void> _loadBalance() async {
    final user = ref.read(authControllerProvider).valueOrNull;

    setState(() {
      _loadingBalance = true;
    });

    final balanceData = await DashboardDataService.loadBalance(_remoteDataSource, user);

    if (mounted) {
      setState(() {
        _balanceData = balanceData;
        _loadingBalance = false;
      });
    }
  }

  Future<void> _loadWeighIn() async {
    final user = ref.read(authControllerProvider).valueOrNull;

    setState(() {
      _loadingWeighIn = true;
    });

    final weighInData = await DashboardDataService.loadWeighIn(_remoteDataSource, user);

    if (mounted) {
      setState(() {
        _weighInData = weighInData;
        _loadingWeighIn = false;
      });
    }
  }

  // Search and filter methods removed - not needed on dashboard

  // _handleDeleteWorkout removed - not needed without Recent Workouts section

  @override
  Widget build(BuildContext context) {
    final workoutsState = ref.watch(workoutControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: workoutsState.when(
            data: (workouts) {
              final user = authState.valueOrNull;
              final isTrainer = user?.role == 'TRAINER';

              // Get today's workout
              final today = DateTime.now();
              final todayDate = DateTime(today.year, today.month, today.day);
              Workout? todayWorkout;
              try {
                todayWorkout = workouts.firstWhere((w) {
                  final workoutDate = DateTime(w.scheduledDate.year, w.scheduledDate.month, w.scheduledDate.day);
                  return workoutDate.isAtSameMomentAs(todayDate);
                });
              } catch (e) {
                todayWorkout = null;
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(workoutControllerProvider);
                  await _loadBalance();
                  await _loadWeighIn();
                  await _checkPaywall(); // Re-check paywall after refresh
                },
                color: AppColors.primary,
                child: CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(child: DashboardHeader(user: user)),

                    // Search Bar removed - not needed on dashboard

                    // Info Card (status plana)
                    // Show "No Plan Assigned" only if there's no plan at all (neither current nor from history)
                    if (!isTrainer && user?.role == 'CLIENT')
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Consumer(
                            builder: (context, ref, _) {
                              final currentPlanAsync = ref.watch(currentPlanProvider);

                              // Check if there's any plan (current or from history)
                              final hasPlan = currentPlanAsync.hasValue && currentPlanAsync.value != null;
                              final plan = currentPlanAsync.valueOrNull;
                              
                              // Show "No Plan Assigned" only if there's no plan at all
                              if (!hasPlan || plan == null) {
                                return _buildInfoCard(
                                  context,
                                  icon: Icons.info_outline,
                                  title: 'No Plan Assigned',
                                  message: 'Waiting for your trainer to create your first plan',
                                  color: AppColors.warning,
                                );
                              } else if (plan.planStatus == 'future') {
                                // Future plan (not unlocked yet)
                                return _buildInfoCard(
                                  context,
                                  icon: Icons.lock_outline_rounded,
                                  title: 'Future Plan - Unlock',
                                  message: 'You have a plan ready. Unlock it to start training.',
                                  color: AppColors.primary,
                                );
                              } else if (plan.planStatus == 'previous') {
                                // Previous plan (completed)
                                return _buildInfoCard(
                                  context,
                                  icon: Icons.info_outline,
                                  title: 'Previous Plan',
                                  message: 'You have a previous plan. Unlock a new plan to continue training.',
                                  color: AppColors.warning,
                                );
                              } else {
                                // Current plan exists and is active
                                return _buildInfoCard(
                                  context,
                                  icon: Icons.fitness_center,
                                  title: 'Keep Going!',
                                  message: 'Complete current week to unlock next week',
                                  color: AppColors.info,
                                );
                              }
                            },
                          ),
                        ),
                      ),

                    // Current Plan Card (Client only)
                    if (!isTrainer && user?.role == 'CLIENT') ...[const SliverToBoxAdapter(child: CurrentPlanCard())],

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
                                onPaymentComplete: refreshBalance, // Refresh balance after payment
                              )
                            : const SizedBox.shrink(),
                      ),

                    // Weigh-In Card (Client only)
                    if (!isTrainer)
                      SliverToBoxAdapter(
                        child: WeighInCard(
                          latestWeighIn: _weighInData,
                          isLoading: _loadingWeighIn,
                          onRefresh: _loadWeighIn,
                        ),
                      ),

                    // AI Messages Preview (Client only)
                    if (!isTrainer && user?.role == 'CLIENT') ...[
                      Builder(
                        builder: (context) {
                          debugPrint(
                            '[Dashboard] Rendering AIMessagesPreviewCard - isTrainer: $isTrainer, user role: ${user?.role}',
                          );
                          return const SliverToBoxAdapter(child: AIMessagesPreviewCard());
                        },
                      ),
                    ],

                    // Workout Calendar removed - use Calendar page instead

                    // Nutrition Summary (Client only)
                    if (!isTrainer)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: NutritionSummaryCard(calories: 1850, protein: 120, carbs: 220, fats: 65),
                        ),
                      ),

                    // Today's Mission Card
                    SliverToBoxAdapter(child: TodaysMissionWidget(todayWorkout: todayWorkout)),

                    // Role-dependent content
                    if (isTrainer) const SliverToBoxAdapter(child: DashboardTrainerContent()),
                    // Recent Workouts removed - use Calendar page instead

                    // Spacing
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            },
            loading: () => const DashboardLoadingState(),
            error: (error, stack) => DashboardErrorState(error: error),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
