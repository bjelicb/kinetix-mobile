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
import '../../presentation/widgets/balance_card.dart';
import '../../presentation/widgets/weigh_in_card.dart';
import '../../presentation/widgets/ai_messages_preview_card.dart';
import '../../presentation/widgets/unlock_next_week_button.dart';
// WorkoutCalendarWidget removed - use Calendar page instead
import '../../presentation/widgets/nutrition_summary_card.dart';
// Haptic feedback removed - not needed without interactive elements
import '../../data/datasources/remote_data_source.dart';
import 'dashboard/services/dashboard_data_service.dart';
import 'dashboard/services/paywall_service.dart';
import '../widgets/dashboard/dashboard_header_widget.dart';
import '../widgets/dashboard/dashboard_quick_stats_widget.dart';
import '../widgets/dashboard/todays_mission_widget.dart';
// DashboardClientContent removed - Recent Workouts not needed
import '../widgets/dashboard/dashboard_trainer_content_widget.dart';
import '../widgets/dashboard/dashboard_state_widgets.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  // Search and filter removed - not needed on dashboard
  Map<String, dynamic>? _balanceData;
  bool _loadingBalance = false;
  Map<String, dynamic>? _weighInData;
  bool _loadingWeighIn = false;

  late final RemoteDataSource _remoteDataSource;

  @override
  void initState() {
    super.initState();
    final storage = FlutterSecureStorage();
    final dio = Dio();
    _remoteDataSource = RemoteDataSource(dio, storage);

    // _loadMuscleGroups(); // Removed - not needed
    _loadBalance().then((_) => _checkPaywall());
    _loadWeighIn();
  }

  Future<void> _checkPaywall() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    final balanceData = _balanceData;

    if (mounted) {
      PaywallService.checkPaywall(context, balanceData, user);
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
                },
                color: AppColors.primary,
                child: CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(child: DashboardHeader(user: user)),

                    // Search Bar removed - not needed on dashboard

                    // Current Plan Card (Client only)
                    if (!isTrainer && user?.role == 'CLIENT') ...[
                      const SliverToBoxAdapter(child: CurrentPlanCard()),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: UnlockNextWeekButton(),
                        ),
                      ),
                    ],

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
                          isLoading: _loadingWeighIn,
                          onRefresh: _loadWeighIn,
                        ),
                      ),

                    // Quick Stats (Client only)
                    if (!isTrainer) const SliverToBoxAdapter(child: DashboardQuickStats()),

                    // AI Messages Preview (Client only)
                    if (!isTrainer && user?.role == 'CLIENT') const SliverToBoxAdapter(child: AIMessagesPreviewCard()),

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
}
