import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart' show AppColors, AppSpacing;
import '../../domain/entities/user.dart';
import '../../presentation/widgets/gradient_background.dart';
import 'admin_dashboard/modals/assign_clients_modal.dart';
import 'admin_dashboard/modals/create_plan_modal.dart';
import 'admin_dashboard/modals/create_user_modal.dart';
import 'admin_dashboard/modals/plan_details_modal.dart';
import 'admin_dashboard/modals/user_details_modal.dart';
import 'admin_dashboard/modals/workout_details_modal.dart';
import 'admin_dashboard/widgets/admin_header.dart';
import 'admin_dashboard/widgets/database_overview_card.dart';
import 'admin_dashboard/widgets/plan_management_card.dart';
import 'admin_dashboard/widgets/system_stats_card.dart';
import 'admin_dashboard/widgets/trainer_management_card.dart';
import 'admin_dashboard/widgets/user_management_card.dart';
import 'admin_dashboard/widgets/users_list.dart';
import 'admin_dashboard/widgets/workout_management_card.dart';
import '../controllers/admin_controller.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  String _searchQuery = '';
  String _roleFilter = 'ALL';
  List<User> _allUsers = [];
  bool _isLoadingUsers = false;
  List<Map<String, dynamic>> _allPlans = [];
  bool _isLoadingPlans = false;
  List<Map<String, dynamic>> _allWorkouts = [];
  bool _isLoadingWorkouts = false;
  Map<String, dynamic>? _workoutStats;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadPlans();
    _loadWorkouts();
    _loadWorkoutStats();
  }

  Future<void> _loadPlans() async {
    if (!mounted) {
      developer.log('[AdminDashboard] _loadPlans called but widget not mounted');
      return;
    }
    developer.log('[AdminDashboard] _loadPlans called - loading plans...');
    setState(() => _isLoadingPlans = true);
    try {
      final plans = await ref.read(adminControllerProvider.notifier).getAllPlans();
      developer.log('[AdminDashboard] _loadPlans - fetched ${plans.length} plans');
      if (mounted) {
        setState(() {
          _allPlans = plans;
          _isLoadingPlans = false;
        });
        developer.log('[AdminDashboard] _loadPlans - state updated with ${_allPlans.length} plans');
      } else {
        developer.log('[AdminDashboard] _loadPlans - widget not mounted after fetch');
      }
    } catch (e) {
      developer.log('[AdminDashboard] _loadPlans - ERROR: $e');
      if (mounted) {
        setState(() => _isLoadingPlans = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading plans: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => _isLoadingUsers = true);
    try {
      final users = await ref.read(adminControllerProvider.notifier).getAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(label: 'Retry', textColor: AppColors.textPrimary, onPressed: _loadUsers),
          ),
        );
      }
    }
  }

  Future<void> _loadWorkouts() async {
developer.log('═══════════════════════════════════════════════════════════', name: 'AdminDashboard');
developer.log('[AdminDashboard] _loadWorkouts CALLED - starting refresh...', name: 'AdminDashboard');
developer.log('[AdminDashboard] Current workout count: ${_allWorkouts.length}', name: 'AdminDashboard');

    if (!mounted) {
      developer.log('[AdminDashboard] _loadWorkouts ABORTED - widget not mounted', name: 'AdminDashboard');
      return;
    }

    developer.log('[AdminDashboard] _loadWorkouts - widget is mounted, proceeding...', name: 'AdminDashboard');
    setState(() => _isLoadingWorkouts = true);

    try {
      developer.log('[AdminDashboard] _loadWorkouts - calling getAllWorkouts()...', name: 'AdminDashboard');
      final workouts = await ref.read(adminControllerProvider.notifier).getAllWorkouts();

      developer.log('[AdminDashboard] _loadWorkouts - fetched ${workouts.length} workouts from API', name: 'AdminDashboard');

      if (workouts.isNotEmpty) {
        final workoutIds = workouts.take(5).map((w) => w['_id']?.toString() ?? 'no-id').join(", ");
        developer.log('[AdminDashboard] _loadWorkouts - first 5 workout IDs: $workoutIds', name: 'AdminDashboard');
      }

      if (mounted) {
        developer.log('[AdminDashboard] _loadWorkouts - updating state with ${workouts.length} workouts', name: 'AdminDashboard');
        setState(() {
          _allWorkouts = workouts;
          _isLoadingWorkouts = false;
        });
developer.log('[AdminDashboard] _loadWorkouts - state updated successfully', name: 'AdminDashboard');
developer.log('[AdminDashboard] _loadWorkouts - NEW workout count: ${_allWorkouts.length}', name: 'AdminDashboard');
developer.log('═══════════════════════════════════════════════════════════', name: 'AdminDashboard');
      } else {
        developer.log('[AdminDashboard] _loadWorkouts - widget not mounted, skipping state update', name: 'AdminDashboard');
      }
    } catch (e) {
      developer.log('[AdminDashboard] _loadWorkouts ERROR: $e', name: 'AdminDashboard', error: e);
      if (mounted) {
        setState(() => _isLoadingWorkouts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading workouts: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadWorkoutStats() async {
    if (!mounted) return;
    try {
      final stats = await ref.read(adminControllerProvider.notifier).getWorkoutStats();
      if (mounted) {
        setState(() {
          _workoutStats = stats;
        });
      }
    } catch (e) {
      // Silently fail for stats
    }
  }

  List<User> get _filteredUsers {
    var filtered = _allUsers;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final query = _searchQuery.toLowerCase();
        return user.name.toLowerCase().contains(query) || user.email.toLowerCase().contains(query);
      }).toList();
    }

    if (_roleFilter != 'ALL') {
      filtered = filtered.where((user) => user.role == _roleFilter).toList();
    }

    return filtered;
  }

  List<User> get _trainers {
    return _allUsers.where((u) => u.role == 'TRAINER').toList();
  }

  List<User> get _clientsWithoutTrainer {
    return _allUsers.where((u) => u.role == 'CLIENT' && u.trainerName == null).toList();
  }

  List<User> get _allClients {
    return _allUsers.where((u) => u.role == 'CLIENT').toList();
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(adminControllerProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminControllerProvider);
              await _loadUsers();
              await _loadPlans();
              await _loadWorkouts();
              await _loadWorkoutStats();
            },
            color: AppColors.primary,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Header
                  const AdminHeader(),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // System Statistics
                        statsState.when(
                          data: (stats) => SystemStatsCard(stats: stats),
                          loading: () => const SystemStatsLoadingCard(),
                          error: (error, stack) => SystemStatsErrorCard(error: error),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // User Management Card
                        UserManagementCard(
                          onCreateUser: () => showCreateUserModal(
                            context: context,
                            ref: ref,
                            onUserCreated: () async {
                              await _loadUsers();
                              await _loadPlans();
                            },
                          ),
                          onSearchChanged: (query) => setState(() => _searchQuery = query),
                          roleFilter: _roleFilter,
                          onRoleFilterChanged: (role) => setState(() => _roleFilter = role),
                          isLoading: _isLoadingUsers,
                          usersList: UsersList(
                            users: _filteredUsers,
                            searchQuery: _searchQuery,
                            roleFilter: _roleFilter,
                            onUserTap: (user) => showUserDetailsModal(
                              context: context,
                              ref: ref,
                              user: user,
                              onRefresh: () async {
                                await _loadUsers();
                                await _loadPlans();
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Trainer Management Card
                        TrainerManagementCard(
                          trainers: _trainers,
                          allUsers: _allUsers,
                          clientsWithoutTrainer: _clientsWithoutTrainer,
                          onAssignClients: () => showAssignClientsModal(
                            context: context,
                            ref: ref,
                            trainers: _trainers,
                            allClients: _allClients,
                            onRefresh: () async {
                              await _loadUsers();
                              await _loadPlans();
                            },
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Plan Management Card
                        PlanManagementCard(
                          isLoading: _isLoadingPlans,
                          plans: _allPlans,
                          onCreatePlan: () async {
                            await showCreatePlanModal(
                              context: context,
                              ref: ref,
                              trainers: _trainers,
                              onCreated: () async {
                                developer.log('[AdminDashboard] onCreated callback called - refreshing plans...');
                                if (mounted) {
                                  await _loadPlans();
                                  developer.log('[AdminDashboard] Plans refreshed successfully');
                                } else {
                                  developer.log('[AdminDashboard] Widget not mounted, cannot refresh');
                                }
                              },
                            );
                            // Ensure plans are refreshed even if callback wasn't called
                            developer.log('[AdminDashboard] Modal closed, ensuring plans are loaded...');
                            if (mounted) {
                              await _loadPlans();
                            }
                          },
                          onPlanTap: (plan) => showPlanDetailsModal(
                            context: context,
                            ref: ref,
                            plan: plan,
                            allClients: _allClients,
                            onRefresh: () async {
                              developer.log('[AdminDashboard] onRefresh callback START - refreshing plans...');
                              await _loadPlans();
                              developer.log('[AdminDashboard] onRefresh - plans refreshed');
                            },
                            onRefreshWorkouts: () async {
                              developer.log('═══════════════════════════════════════════════════════════');
                              developer.log(
                                '[AdminDashboard] onRefreshWorkouts callback CALLED - starting workout refresh...',
                              );
                              developer.log(
                                '[AdminDashboard] onRefreshWorkouts - current workout count before refresh: ${_allWorkouts.length}',
                              );
                              await _loadWorkouts();
                              developer.log(
                                '[AdminDashboard] onRefreshWorkouts - workouts refreshed, now refreshing stats...',
                              );
                              await _loadWorkoutStats();
                              developer.log(
                                '[AdminDashboard] onRefreshWorkouts callback COMPLETE - workouts and stats refreshed',
                              );
                              developer.log(
                                '[AdminDashboard] onRefreshWorkouts - final workout count: ${_allWorkouts.length}',
                              );
                              developer.log('═══════════════════════════════════════════════════════════');
                            },
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Workout Management Card
                        WorkoutManagementCard(
                          isLoading: _isLoadingWorkouts,
                          workouts: _allWorkouts,
                          workoutStats: _workoutStats,
                          onWorkoutTap: (workout) => showWorkoutDetailsModal(
                            context: context,
                            ref: ref,
                            workout: workout,
                            onRefresh: () async {
                              await _loadWorkouts();
                              await _loadWorkoutStats();
                            },
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Database Overview
                        DatabaseOverviewCard(
                          users: _filteredUsers,
                          isLoading: _isLoadingUsers,
                          onUserTap: (user) => showUserDetailsModal(
                            context: context,
                            ref: ref,
                            user: user,
                            onRefresh: () async {
                              await _loadUsers();
                              await _loadPlans();
                            },
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
