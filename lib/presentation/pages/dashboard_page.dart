import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/search_bar.dart' as kinetix_search;
import '../../presentation/widgets/filter_bottom_sheet.dart';
import '../../presentation/widgets/plans/current_plan_card.dart';
import '../../presentation/widgets/balance_card.dart';
import '../../presentation/widgets/weigh_in_card.dart';
import '../../presentation/widgets/ai_messages_preview_card.dart';
import '../../presentation/widgets/unlock_next_week_button.dart';
import '../../presentation/widgets/calendar/workout_calendar_widget.dart';
import '../../presentation/widgets/nutrition_summary_card.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../data/datasources/remote_data_source.dart';
import 'dashboard/services/dashboard_data_service.dart';
import 'dashboard/services/paywall_service.dart';
import '../widgets/dashboard/dashboard_header_widget.dart';
import '../widgets/dashboard/dashboard_quick_stats_widget.dart';
import '../widgets/dashboard/todays_mission_widget.dart';
import '../widgets/dashboard/dashboard_client_content_widget.dart';
import '../widgets/dashboard/dashboard_trainer_content_widget.dart';
import '../widgets/dashboard/dashboard_state_widgets.dart';

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
  
  late final RemoteDataSource _remoteDataSource;

  @override
  void initState() {
    super.initState();
    final storage = FlutterSecureStorage();
    final dio = Dio();
    _remoteDataSource = RemoteDataSource(dio, storage);
    
    _loadMuscleGroups();
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

  Future<void> _loadMuscleGroups() async {
    final muscleGroups = await DashboardDataService.loadMuscleGroups();
    if (mounted) {
      setState(() {
        _availableMuscleGroups = muscleGroups;
      });
    }
  }

  Future<void> _showFilterSheet() async {
    AppHaptic.selection();
    final result = await FilterBottomSheet.show(
      context: context,
      initialFilters: _filterOptions,
      availableMuscleGroups: _availableMuscleGroups,
      availableExercises: [],
    );

    if (result != null && mounted) {
      setState(() {
        _filterOptions = result;
      });
    }
  }

  void _handleDeleteWorkout(String workoutId) {
    // Workout deletion is handled in the dialog callback
    // This method can be used for additional cleanup if needed
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
              final todayWorkout = filteredWorkouts.isNotEmpty ? filteredWorkouts.first : null;

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
                    SliverToBoxAdapter(
                      child: DashboardHeader(user: user),
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

                    // Current Plan Card (Client only)
                    if (!isTrainer && user?.role == 'CLIENT') ...[
                      const SliverToBoxAdapter(
                        child: CurrentPlanCard(),
                      ),
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
                    if (!isTrainer)
                      const SliverToBoxAdapter(
                        child: DashboardQuickStats(),
                      ),

                    // AI Messages Preview (Client only)
                    if (!isTrainer && user?.role == 'CLIENT')
                      const SliverToBoxAdapter(
                        child: AIMessagesPreviewCard(),
                      ),

                    // Workout Calendar (Client only)
                    if (!isTrainer && user?.role == 'CLIENT')
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: WorkoutCalendarWidget(),
                        ),
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
                      child: TodaysMissionWidget(todayWorkout: todayWorkout),
                    ),

                    // Role-dependent content
                    if (isTrainer)
                      const SliverToBoxAdapter(
                        child: DashboardTrainerContent(),
                      )
                    else
                      SliverToBoxAdapter(
                        child: DashboardClientContent(
                          workouts: filteredWorkouts,
                          onDeleteWorkout: _handleDeleteWorkout,
                        ),
                      ),

                    // Spacing
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
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
