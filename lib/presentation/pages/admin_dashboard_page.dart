import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../core/theme/app_colors.dart' show AppSpacing, TrainerThemes;
import '../../core/constants/app_assets.dart';
import '../../domain/entities/user.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../presentation/widgets/search_bar.dart' as kinetix_search;
import '../../presentation/widgets/cyber_loader.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';

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
    if (!mounted) return;
    setState(() => _isLoadingPlans = true);
    try {
      final plans = await ref.read(adminControllerProvider.notifier).getAllPlans();
      if (mounted) {
        setState(() {
          _allPlans = plans;
          _isLoadingPlans = false;
        });
      }
    } catch (e) {
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
            action: SnackBarAction(
              label: 'Retry',
              textColor: AppColors.textPrimary,
              onPressed: _loadUsers,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadWorkouts() async {
    if (!mounted) return;
    setState(() => _isLoadingWorkouts = true);
    try {
      final workouts = await ref.read(adminControllerProvider.notifier).getAllWorkouts();
      if (mounted) {
        setState(() {
          _allWorkouts = workouts;
          _isLoadingWorkouts = false;
        });
      }
    } catch (e) {
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
        return user.name.toLowerCase().contains(query) ||
               user.email.toLowerCase().contains(query);
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
                  _buildAdminHeader(context, ref),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // System Statistics
                  statsState.when(
                    data: (stats) => _buildSystemStats(context, stats),
                    loading: () => _buildSystemStatsLoading(context),
                    error: (error, stack) => _buildSystemStatsError(context, error),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // User Management Card
                  _buildUserManagementCard(context),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Trainer Management Card
                  _buildTrainerManagementCard(context),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Plan Management Card
                  _buildPlanManagementCard(context),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Workout Management Card
                  _buildWorkoutManagementCard(context),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Database Overview
                  _buildDatabaseOverview(context),
                  
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

  Widget _buildAdminHeader(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final themeGradient = _getThemeGradient(theme);
    final themeColor = _getThemeColor(theme);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final userName = user?.name ?? 'Admin';
    
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
                    'Welcome, Admin',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kinetix',
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
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
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

  Widget _buildSystemStats(BuildContext context, Map<String, dynamic> stats) {
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      showCyberBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_rounded,
                color: AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'System Statistics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // First row
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Total Users',
                  value: '${stats['totalUsers'] ?? 0}',
                  icon: Icons.person_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatItem(
                  label: 'Trainers',
                  value: '${stats['totalTrainers'] ?? 0}',
                  icon: Icons.fitness_center_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Second row
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Clients',
                  value: '${stats['totalClients'] ?? 0}',
                  icon: Icons.people_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatItem(
                  label: "Today's Check-ins",
                  value: '${stats['todayCheckIns'] ?? 0}',
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
          // Additional metrics if available
          if (stats['activeTrainers'] != null || stats['totalPlans'] != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (stats['activeTrainers'] != null) ...[
                  Expanded(
                    child: _StatItem(
                      label: 'Active Trainers',
                      value: '${stats['activeTrainers'] ?? 0}',
                      icon: Icons.verified_user_rounded,
                    ),
                  ),
                  if (stats['totalPlans'] != null) const SizedBox(width: AppSpacing.sm),
                ],
                if (stats['totalPlans'] != null)
                  Expanded(
                    child: _StatItem(
                      label: 'Total Plans',
                      value: '${stats['totalPlans'] ?? 0}',
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
              ],
            ),
          ],
          if (stats['totalWorkoutsCompleted'] != null || stats['pendingCheckIns'] != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (stats['totalWorkoutsCompleted'] != null) ...[
                  Expanded(
                    child: _StatItem(
                      label: 'Workouts Completed',
                      value: '${stats['totalWorkoutsCompleted'] ?? 0}',
                      icon: Icons.done_all_rounded,
                    ),
                  ),
                  if (stats['pendingCheckIns'] != null) const SizedBox(width: AppSpacing.sm),
                ],
                if (stats['pendingCheckIns'] != null)
                  Expanded(
                    child: _StatItem(
                      label: 'Pending Check-ins',
                      value: '${stats['pendingCheckIns'] ?? 0}',
                      icon: Icons.pending_actions_rounded,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemStatsLoading(BuildContext context) {
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: AnimatedCyberLoader(size: 40),
        ),
      ),
    );
  }

  Widget _buildSystemStatsError(BuildContext context, Object error) {
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text('Error: $error', style: const TextStyle(color: AppColors.error)),
    );
  }

  Widget _buildUserManagementCard(BuildContext context) {
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
                onPressed: () => _showCreateUserModal(context),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          kinetix_search.SearchBar(
            hintText: 'Search users...',
            onChanged: (query) {
              setState(() => _searchQuery = query);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          // Role Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _roleFilter == 'ALL',
                  onSelected: (v) => setState(() => _roleFilter = 'ALL'),
                ),
                const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  label: 'Clients',
                  selected: _roleFilter == 'CLIENT',
                  onSelected: (v) => setState(() => _roleFilter = 'CLIENT'),
                ),
                const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  label: 'Trainers',
                  selected: _roleFilter == 'TRAINER',
                  onSelected: (v) => setState(() => _roleFilter = 'TRAINER'),
                ),
              const SizedBox(width: AppSpacing.xs),
              _FilterChip(
                label: 'Admins',
                selected: _roleFilter == 'ADMIN',
                onSelected: (v) => setState(() => _roleFilter = 'ADMIN'),
              ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isLoadingUsers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AnimatedCyberLoader(size: 40),
              ),
            )
          else
            _buildUsersList(context),
        ],
      ),
    );
  }

  Widget _buildUsersList(BuildContext context) {
    final users = _filteredUsers;
    
    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          _searchQuery.isNotEmpty || _roleFilter != 'ALL'
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
          return _UserListItem(
            user: user,
            onTap: () => _showUserDetails(context, user),
          );
        },
      ),
    );
  }

  Widget _buildTrainerManagementCard(BuildContext context) {
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
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Trainer Manage',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              NeonButton(
                text: 'Assign',
                icon: Icons.link_rounded,
                onPressed: _clientsWithoutTrainer.isEmpty
                    ? null
                    : () => _showAssignClientsModal(context),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_trainers.isEmpty)
            Text(
              'No trainers found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _trainers.length,
                itemBuilder: (context, index) {
                  final trainer = _trainers[index];
                  // Count clients assigned to this trainer (by name or ID matching)
                  final clientCount = _allUsers.where((u) => 
                    u.role == 'CLIENT' && 
                    (u.trainerName == trainer.name || u.trainerName == trainer.id)
                  ).length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.adminAccent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trainer.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                trainer.email,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$clientCount clients',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
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

  Widget _buildPlanManagementCard(BuildContext context) {
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
                    Icons.calendar_today_rounded,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Plan Manage',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              NeonButton(
                text: 'Create',
                icon: Icons.add_rounded,
                onPressed: () => _showCreatePlanModal(context),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isLoadingPlans)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AnimatedCyberLoader(size: 40),
              ),
            )
          else if (_allPlans.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No plans found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Plans will appear here once trainers create them',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _allPlans.length,
                itemBuilder: (context, index) {
                  final plan = _allPlans[index];
                  return InkWell(
                    onTap: () => _showPlanDetailsModal(context, plan),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.adminAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan['name'] ?? 'Unnamed Plan',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'By: ${plan['trainerName'] ?? 'Unknown'}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (plan['difficulty'] != null)
                                    Text(
                                      'Difficulty: ${plan['difficulty']}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${plan['assignedClientCount'] ?? 0} clients',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
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

  Widget _buildWorkoutManagementCard(BuildContext context) {
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
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Workout Manage',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (_workoutStats != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.adminAccent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_workoutStats!['totalWorkouts'] ?? 0} completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isLoadingWorkouts)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AnimatedCyberLoader(size: 40),
              ),
            )
          else if (_allWorkouts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No workouts found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _allWorkouts.length,
                itemBuilder: (context, index) {
                  final workout = _allWorkouts[index];
                  return InkWell(
                    onTap: () => _showWorkoutDetailsModal(context, workout),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.adminAccent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        workout['isCompleted'] == true
                                            ? Icons.check_circle_rounded
                                            : workout['isMissed'] == true
                                                ? Icons.cancel_rounded
                                                : Icons.pending_rounded,
                                        size: 16,
                                        color: workout['isCompleted'] == true
                                            ? AppColors.success
                                            : workout['isMissed'] == true
                                                ? AppColors.error
                                                : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          workout['planName'] ?? 'Unknown Plan',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Client: ${workout['clientName'] ?? 'Unknown'}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (workout['workoutDate'] != null)
                                    Text(
                                      'Date: ${_formatDate(workout['workoutDate'])}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
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
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        final parsed = DateTime.parse(date);
        return '${parsed.day}/${parsed.month}/${parsed.year}';
      } else if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year}';
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  String _formatDayOfWeek(dynamic dayOfWeek) {
    if (dayOfWeek == null) return '';
    try {
      final day = dayOfWeek is int ? dayOfWeek : int.tryParse(dayOfWeek.toString()) ?? 0;
      const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      if (day >= 1 && day <= 7) {
        return days[day];
      }
      return dayOfWeek.toString();
    } catch (e) {
      return dayOfWeek.toString();
    }
  }

  Widget _buildDatabaseOverview(BuildContext context) {
    final users = _filteredUsers;
    
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
                    Icons.storage_rounded,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Database Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.adminAccent,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${users.length} ${users.length == 1 ? 'user' : 'users'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isLoadingUsers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AnimatedCyberLoader(size: 40),
              ),
            )
          else if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No users to display',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 400,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return InkWell(
                    onTap: () => _showUserDetails(context, user),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.adminAccent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          // User Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(user.role).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            user.role,
                                            style: TextStyle(
                                              color: _getRoleColor(user.role),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: user.isActive 
                                                ? AppColors.success.withValues(alpha: 0.2)
                                                : AppColors.error.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            user.isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              color: user.isActive ? AppColors.success : AppColors.error,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (user.trainerName != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Trainer: ${user.trainerName}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Action Icon
                          Icon(
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return AppColors.error;
      case 'TRAINER':
        return AppColors.primary;
      case 'CLIENT':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showCreateUserModal(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    String selectedRole = 'CLIENT';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create New User',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  filled: true,
                  fillColor: AppColors.surface1,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  filled: true,
                  fillColor: AppColors.surface1,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: AppColors.surface1,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: AppColors.surface1,
                ),
                obscureText: true,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  filled: true,
                  fillColor: AppColors.surface1,
                ),
                items: ['CLIENT', 'TRAINER', 'ADMIN'].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedRole = value;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              NeonButton(
                text: 'Create User',
                icon: Icons.person_add_rounded,
                onPressed: () async {
                  try {
                    await ref.read(adminControllerProvider.notifier).createUser(
                      email: emailController.text.trim(),
                      password: passwordController.text,
                      firstName: firstNameController.text.trim(),
                      lastName: lastNameController.text.trim(),
                      role: selectedRole,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      await _loadUsers();
                      await _loadPlans();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User created successfully'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignClientsModal(BuildContext context) {
    String? selectedTrainerId;
    final selectedClients = <String>{};

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Assign Clients to Trainer',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  value: selectedTrainerId,
                  decoration: const InputDecoration(
                    labelText: 'Select Trainer',
                    filled: true,
                    fillColor: AppColors.surface1,
                  ),
                  items: _trainers.map((trainer) {
                    return DropdownMenuItem<String>(
                      value: trainer.id,
                      child: Text('${trainer.name} (${trainer.email})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() {
                      selectedTrainerId = value;
                      selectedClients.clear();
                      // Auto-select clients assigned to this trainer
                      for (final client in _allClients) {
                        if (client.trainerId == value) {
                          selectedClients.add(client.id);
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Clients:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (selectedClients.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${selectedClients.length} selected',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Flexible(
                  child: _allClients.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'No clients available',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _allClients.length,
                          itemBuilder: (context, index) {
                            final client = _allClients[index];
                            final isAssigned = client.trainerName != null && client.trainerName!.isNotEmpty;
                            final isSelected = selectedClients.contains(client.id);
                            
                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    selectedClients.remove(client.id);
                                  } else {
                                    selectedClients.add(client.id);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        setModalState(() {
                                          if (value == true) {
                                            selectedClients.add(client.id);
                                          } else {
                                            selectedClients.remove(client.id);
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            client.name,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            client.email,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          if (isAssigned) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.success.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle_outline,
                                                    size: 14,
                                                    color: AppColors.success,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      client.trainerName!,
                                                      style: TextStyle(
                                                        color: AppColors.success,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                NeonButton(
                  text: 'Assign',
                  icon: Icons.link_rounded,
                  onPressed: selectedTrainerId == null
                      ? null
                      : () async {
                          try {
                            // Find clients currently assigned to this trainer
                            final currentlyAssignedClients = _allClients
                                .where((client) => client.trainerId == selectedTrainerId)
                                .map((client) => client.id)
                                .toSet();
                            
                            // Unassign clients that were assigned to this trainer but are not selected
                            final clientsToUnassign = currentlyAssignedClients
                                .difference(selectedClients);
                            
                            for (final clientId in clientsToUnassign) {
                              await ref.read(adminControllerProvider.notifier).assignClientToTrainer(
                                clientId: clientId,
                                trainerId: null, // Unassign
                              );
                            }
                            
                            // Assign selected clients to this trainer
                            for (final clientId in selectedClients) {
                              await ref.read(adminControllerProvider.notifier).assignClientToTrainer(
                                clientId: clientId,
                                trainerId: selectedTrainerId!,
                              );
                            }
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                              await _loadUsers();
                              await _loadPlans();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Clients assigned successfully'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AppColors.error,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserDetails(BuildContext context, User user) {
    bool currentStatus = user.isActive;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(user.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${user.email}'),
              const SizedBox(height: 8),
              Text('Role: ${user.role}'),
              if (user.trainerName != null) ...[
                const SizedBox(height: 8),
                Text('Trainer: ${user.trainerName}'),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: currentStatus 
                              ? AppColors.success.withValues(alpha: 0.2)
                              : AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentStatus ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: currentStatus ? AppColors.success : AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (user.role != 'ADMIN')
                        _CustomToggle(
                          value: currentStatus,
                          onChanged: (value) async {
                            setDialogState(() => currentStatus = value);
                            try {
                              await ref.read(adminControllerProvider.notifier).updateUserStatus(
                                userId: user.id,
                                isActive: value,
                              );
                              await _loadUsers();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      value 
                                          ? 'User activated successfully' 
                                          : 'User deactivated successfully',
                                    ),
                                    backgroundColor: value ? AppColors.success : AppColors.error,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => currentStatus = !value);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
              if (user.role == 'ADMIN')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Admin users cannot be deactivated',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showEditUserModal(context, user);
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit'),
            ),
            if (user.role != 'ADMIN')
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Delete User'),
                      content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    try {
                      await ref.read(adminControllerProvider.notifier).deleteUser(user.id);
                      await _loadUsers();
                      await _loadPlans();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User deleted successfully'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.delete_rounded, size: 18),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserModal(BuildContext context, User user) {
    final emailController = TextEditingController(text: user.email);
    final firstNameController = TextEditingController(text: user.name.split(' ').first);
    final lastNameController = TextEditingController(
      text: user.name.split(' ').length > 1 ? user.name.split(' ').skip(1).join(' ') : '',
    );
    String selectedRole = user.role;
    bool isActive = user.isActive;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit User',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  filled: true,
                  fillColor: AppColors.surface1,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  filled: true,
                  fillColor: AppColors.surface1,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: AppColors.surface1,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  filled: true,
                  fillColor: AppColors.surface1,
                  hintText: user.role == 'ADMIN' ? 'Admin role cannot be changed' : null,
                ),
                items: ['CLIENT', 'TRAINER', 'ADMIN'].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: user.role == 'ADMIN' 
                    ? null 
                    : (value) {
                        if (value != null) selectedRole = value;
                      },
              ),
              if (user.role == 'ADMIN')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Admin role cannot be changed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              // Kill Switch Toggle
              if (user.role != 'ADMIN')
                StatefulBuilder(
                  builder: (context, setModalState) {
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive 
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.error.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isActive ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
                                    color: isActive ? AppColors.success : AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Kill Switch',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isActive ? 'User is active' : 'User is deactivated',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          _CustomToggle(
                            value: isActive,
                            onChanged: (value) async {
                              setModalState(() => isActive = value);
                              try {
                                await ref.read(adminControllerProvider.notifier).updateUserStatus(
                                  userId: user.id,
                                  isActive: value,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value 
                                            ? 'User activated successfully' 
                                            : 'User deactivated successfully',
                                      ),
                                      backgroundColor: value ? AppColors.success : AppColors.error,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isActive = !value);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              if (user.role != 'ADMIN') const SizedBox(height: AppSpacing.lg),
              NeonButton(
                text: 'Update User',
                icon: Icons.save_rounded,
                onPressed: () async {
                  try {
                    await ref.read(adminControllerProvider.notifier).updateUser(
                      userId: user.id,
                      firstName: firstNameController.text.trim(),
                      lastName: lastNameController.text.trim(),
                      email: emailController.text.trim(),
                      role: selectedRole,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      await _loadUsers();
                      await _loadPlans();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User updated successfully'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlanDetailsModal(BuildContext context, Map<String, dynamic> plan) async {
    final planId = plan['_id'] as String?;
    if (planId == null) return;

    // Load full plan details
    Map<String, dynamic>? planDetails;
    bool isLoading = true;

    try {
      planDetails = await ref.read(adminControllerProvider.notifier).getPlanById(planId);
      isLoading = false;
    } catch (e) {
      isLoading = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading plan: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!mounted || planDetails == null) return;

    final planData = planDetails!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(planData['name'] ?? 'Plan Details'),
        content: SingleChildScrollView(
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AnimatedCyberLoader(size: 40),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (planData['description'] != null) ...[
                      Text(
                        'Description:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        planData['description'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _PlanDetailItem(
                            label: 'Trainer',
                            value: planData['trainerName'] ?? 'Unknown',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PlanDetailItem(
                            label: 'Difficulty',
                            value: planData['difficulty'] ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _PlanDetailItem(
                      label: 'Assigned Clients',
                      value: '${planData['assignedClientCount'] ?? planData['assignedClientIds']?.length ?? 0}',
                    ),
                    if (planData['workouts'] != null && (planData['workouts'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Workouts:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(planData['workouts'] as List).map<Widget>((workout) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface1,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.fitness_center_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    workout['name']?.toString() ?? 'Unnamed Workout',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                if (workout['dayOfWeek'] != null)
                                  Text(
                                    _formatDayOfWeek(workout['dayOfWeek']),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showAssignPlanModal(context, plan);
            },
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Assign'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditPlanModal(context, planData);
            },
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit'),
          ),
          TextButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Duplicate Plan'),
                  content: Text('Create a copy of "${planData['name']}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Duplicate'),
                    ),
                  ],
                ),
              );
              if (!mounted) return;
              Navigator.pop(context); // Close the bottom sheet after dialog
              if (confirmed == true && mounted) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(adminControllerProvider.notifier).duplicatePlan(planId);
                  if (mounted) {
                    await _loadPlans();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Plan duplicated successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Duplicate'),
          ),
          TextButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Delete Plan'),
                  content: Text('Are you sure you want to delete "${planData['name']}"? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (!mounted) return;
              Navigator.pop(context); // Close the bottom sheet after dialog
              if (confirmed == true && mounted) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(adminControllerProvider.notifier).deletePlan(planId);
                  if (mounted) {
                    await _loadPlans();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Plan deleted successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAssignPlanModal(BuildContext context, Map<String, dynamic> plan) {
    final planId = plan['_id'] as String?;
    if (planId == null) return;

    final selectedClients = <String>{};
    DateTime? selectedStartDate;
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            // Filter clients based on search query
            final filteredClients = searchController.text.isEmpty
                ? _allClients
                : _allClients.where((client) {
                    final query = searchController.text.toLowerCase();
                    return client.name.toLowerCase().contains(query) ||
                           client.email.toLowerCase().contains(query);
                  }).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Assign Plan to Clients',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Start Date Picker
                  Text(
                    'Start Date *',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select when the plan should start for clients',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedStartDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedStartDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedStartDate == null
                              ? AppColors.error.withValues(alpha: 0.5)
                              : AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedStartDate == null
                                ? 'Select start date'
                                : '${selectedStartDate!.day}/${selectedStartDate!.month}/${selectedStartDate!.year}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: selectedStartDate == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            color: selectedStartDate == null
                                ? AppColors.textSecondary
                                : AppColors.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Clients:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (selectedClients.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${selectedClients.length} selected',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Search Bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search clients by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.surface1,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Flexible(
                    child: filteredClients.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Text(
                              searchController.text.isEmpty
                                  ? 'No clients available'
                                  : 'No clients found',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredClients.length,
                            itemBuilder: (context, index) {
                              final client = filteredClients[index];
                              final isSelected = selectedClients.contains(client.id);
                              
                              return InkWell(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      selectedClients.remove(client.id);
                                    } else {
                                      selectedClients.add(client.id);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (value) {
                                          setModalState(() {
                                            if (value == true) {
                                              selectedClients.add(client.id);
                                            } else {
                                              selectedClients.remove(client.id);
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              client.name,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              client.email,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeonButton(
                    text: 'Assign Plan',
                    icon: Icons.link_rounded,
                    onPressed: (selectedClients.isEmpty || selectedStartDate == null)
                        ? null
                        : () async {
                            try {
                              await ref.read(adminControllerProvider.notifier).assignPlanToClients(
                                planId,
                                selectedClients.toList(),
                                selectedStartDate!,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                await _loadPlans();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Plan assigned successfully'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                    backgroundColor: AppColors.error,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showEditPlanModal(BuildContext context, Map<String, dynamic> plan) {
    final planId = plan['_id'] as String?;
    if (planId == null) return;

    final nameController = TextEditingController(text: plan['name']?.toString() ?? '');
    final descriptionController = TextEditingController(text: plan['description']?.toString() ?? '');
    String? selectedDifficulty = plan['difficulty']?.toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Plan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Plan Name *',
                        filled: true,
                        fillColor: AppColors.surface1,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        filled: true,
                        fillColor: AppColors.surface1,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        filled: true,
                        fillColor: AppColors.surface1,
                      ),
                      items: ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'].map((difficulty) {
                        return DropdownMenuItem(
                          value: difficulty,
                          child: Text(difficulty),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDifficulty = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    NeonButton(
                      text: 'Update Plan',
                      icon: Icons.save_rounded,
                      onPressed: nameController.text.trim().isEmpty
                          ? null
                          : () async {
                              try {
                                final planData = <String, dynamic>{
                                  'name': nameController.text.trim(),
                                  'description': descriptionController.text.trim().isEmpty 
                                      ? '' 
                                      : descriptionController.text.trim(),
                                };
                                if (selectedDifficulty != null) {
                                  planData['difficulty'] = selectedDifficulty;
                                }
                                
                                await ref.read(adminControllerProvider.notifier).updatePlan(planId, planData);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  await _loadPlans();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Plan updated successfully'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePlanModal(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedDifficulty;
    String? selectedTrainerId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create New Plan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Trainer Selection (Required)
                    DropdownButtonFormField<String>(
                      value: selectedTrainerId,
                      decoration: const InputDecoration(
                        labelText: 'Trainer *',
                        filled: true,
                        fillColor: AppColors.surface1,
                      ),
                      items: _trainers.map((trainer) {
                        return DropdownMenuItem(
                          value: trainer.id,
                          child: Text(trainer.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTrainerId = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Plan Name *',
                        filled: true,
                        fillColor: AppColors.surface1,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        filled: true,
                        fillColor: AppColors.surface1,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        filled: true,
                        fillColor: AppColors.surface1,
                      ),
                      items: ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'].map((difficulty) {
                        return DropdownMenuItem(
                          value: difficulty,
                          child: Text(difficulty),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDifficulty = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    NeonButton(
                      text: 'Create Plan',
                      icon: Icons.add_rounded,
                      onPressed: (nameController.text.trim().isEmpty || selectedTrainerId == null)
                          ? null
                          : () async {
                              try {
                                final planData = <String, dynamic>{
                                  'name': nameController.text.trim(),
                                  'trainerId': selectedTrainerId,
                                };
                                
                                // Only add description if it's not empty
                                final description = descriptionController.text.trim();
                                if (description.isNotEmpty) {
                                  planData['description'] = description;
                                }
                                
                                // Add difficulty if selected
                                if (selectedDifficulty != null) {
                                  planData['difficulty'] = selectedDifficulty;
                                }
                                
                                // Add isTemplate (backend defaults to true if not provided)
                                planData['isTemplate'] = false;
                                
                                await ref.read(adminControllerProvider.notifier).createPlan(planData);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  await _loadPlans();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Plan created successfully'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkoutDetailsModal(BuildContext context, Map<String, dynamic> workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(workout['planName'] ?? 'Workout Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlanDetailItem(
                label: 'Client',
                value: workout['clientName'] ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              _PlanDetailItem(
                label: 'Trainer',
                value: workout['trainerName'] ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              _PlanDetailItem(
                label: 'Plan',
                value: workout['planName'] ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              if (workout['workoutDate'] != null)
                _PlanDetailItem(
                  label: 'Date',
                  value: _formatDate(workout['workoutDate']),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: workout['isCompleted'] == true
                          ? AppColors.success.withValues(alpha: 0.2)
                          : workout['isMissed'] == true
                              ? AppColors.error.withValues(alpha: 0.2)
                              : AppColors.textSecondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      workout['isCompleted'] == true
                          ? 'Completed'
                          : workout['isMissed'] == true
                              ? 'Missed'
                              : 'Pending',
                      style: TextStyle(
                        color: workout['isCompleted'] == true
                            ? AppColors.success
                            : workout['isMissed'] == true
                                ? AppColors.error
                                : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (workout['completedExercisesCount'] != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${workout['completedExercisesCount']} exercises',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (workout['isCompleted'] != true)
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(adminControllerProvider.notifier).updateWorkoutStatus(
                    workoutId: workout['_id'] as String,
                    isCompleted: true,
                  );
                  await _loadWorkouts();
                  await _loadWorkoutStats(); // Refresh stats to update completed count
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workout marked as completed'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('Mark Completed'),
            ),
          if (workout['isMissed'] != true && workout['isCompleted'] != true)
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(adminControllerProvider.notifier).updateWorkoutStatus(
                    workoutId: workout['_id'] as String,
                    isMissed: true,
                  );
                  await _loadWorkouts();
                  await _loadWorkoutStats(); // Refresh stats to update counts
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workout marked as missed'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.cancel_rounded, size: 18),
              label: const Text('Mark Missed'),
            ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Delete Workout'),
                  content: const Text('Are you sure you want to delete this workout? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                try {
                  await ref.read(adminControllerProvider.notifier).deleteWorkout(
                    workout['_id'] as String,
                  );
                  await _loadWorkouts();
                  await _loadWorkoutStats(); // Refresh stats after deletion
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workout deleted successfully'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _PlanDetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _PlanDetailItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CustomToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CustomToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_CustomToggle> createState() => _CustomToggleState();
}

class _CustomToggleState extends State<_CustomToggle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_CustomToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: 56,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: widget.value
                    ? [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.8),
                      ]
                    : [
                        AppColors.error,
                        AppColors.error.withValues(alpha: 0.8),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.value ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: widget.value ? 24 : 2,
                  top: 2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          widget.value ? Icons.check_rounded : Icons.close_rounded,
                          key: ValueKey(widget.value),
                          size: 16,
                          color: widget.value ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.3),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _UserListItem({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: user.isActive 
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: user.isActive ? AppColors.success : AppColors.error,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return AppColors.error;
      case 'TRAINER':
        return AppColors.primary;
      case 'CLIENT':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}
