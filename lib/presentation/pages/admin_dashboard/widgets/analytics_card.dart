import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../data/datasources/remote_data_source.dart';
import '../../../widgets/gradient_card.dart';
import '../../../controllers/common_providers.dart';

class AnalyticsCard extends ConsumerStatefulWidget {
  const AnalyticsCard({super.key});

  @override
  ConsumerState<AnalyticsCard> createState() => _AnalyticsCardState();
}

class _AnalyticsCardState extends ConsumerState<AnalyticsCard> {
  bool _isLoading = false;
  String _selectedPeriod = '30d'; // 7d, 30d, 90d, 1y
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    // Period selection for future API filtering (currently unused)
    
    debugPrint('[AdminDashboard:Analytics] Fetching analytics for period: $_selectedPeriod');
    
    try {
      // Fetch analytics from API
      final remoteDataSource = RemoteDataSource(
        ref.read(dioProvider),
        ref.read(secureStorageProvider),
      );
      
      final statsData = await remoteDataSource.getAdminStats();
      final workoutStats = await remoteDataSource.getWorkoutStats();
      
      // Combine stats data
      _analyticsData = {
        'userCount': statsData['totalUsers'] ?? 0,
        'growthRate': statsData['userGrowth'] ?? 0.0,
        'completionRate': workoutStats['completionRate'] ?? 0.0,
        'activeUsers': statsData['activeUsers'] ?? 0,
        'totalWorkouts': workoutStats['totalWorkouts'] ?? 0,
        'completedWorkouts': workoutStats['completedWorkouts'] ?? 0,
        'totalCheckIns': statsData['totalCheckIns'] ?? 0,
        'totalPlans': statsData['totalPlans'] ?? 0,
      };
      
      debugPrint('[AdminDashboard:Analytics] ✓ User stats: ${_analyticsData['userCount']} users, ${_analyticsData['growthRate']}% growth');
      debugPrint('[AdminDashboard:Analytics] ✓ Workout completion: ${_analyticsData['completionRate']}%');
      debugPrint('[AdminDashboard:Analytics] ✓ Active users: ${_analyticsData['activeUsers']}');
      
    } catch (e) {
      debugPrint('[AdminDashboard:Analytics] ✗ Error loading analytics: $e');
      
      // Set empty data on error
      _analyticsData = {
        'userCount': 0,
        'growthRate': 0.0,
        'completionRate': 0.0,
        'activeUsers': 0,
        'totalWorkouts': 0,
        'totalCheckIns': 0,
      };
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Analytics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Period Selector
              _buildPeriodSelector(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                // Stats Grid
                _buildStatsGrid(),
                
                const SizedBox(height: 24),
                
                // Charts Placeholder
                _buildChartsPlaceholder(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodButton('7d', '7 Days'),
          _buildPeriodButton('30d', '30 Days'),
          _buildPeriodButton('90d', '90 Days'),
          _buildPeriodButton('1y', '1 Year'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final isSelected = _selectedPeriod == value;
    
    return InkWell(
      onTap: () {
        setState(() => _selectedPeriod = value);
        _loadAnalytics();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primary : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.people_rounded,
          label: 'Total Users',
          value: _analyticsData['userCount']?.toString() ?? '0',
          trend: _analyticsData['growthRate'] ?? 0.0,
        ),
        _buildStatCard(
          icon: Icons.fitness_center_rounded,
          label: 'Workouts',
          value: _analyticsData['totalWorkouts']?.toString() ?? '0',
        ),
        _buildStatCard(
          icon: Icons.camera_alt_rounded,
          label: 'Check-ins',
          value: _analyticsData['totalCheckIns']?.toString() ?? '0',
        ),
        _buildStatCard(
          icon: Icons.check_circle_rounded,
          label: 'Completion Rate',
          value: '${_analyticsData['completionRate']?.toStringAsFixed(1) ?? '0.0'}%',
          color: AppColors.success,
        ),
        _buildStatCard(
          icon: Icons.person_rounded,
          label: 'Active Users',
          value: _analyticsData['activeUsers']?.toString() ?? '0',
          color: AppColors.info,
        ),
        _buildStatCard(
          icon: Icons.trending_up_rounded,
          label: 'Growth',
          value: '+${_analyticsData['growthRate']?.toStringAsFixed(1) ?? '0.0'}%',
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    double? trend,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (color ?? AppColors.primary).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color ?? AppColors.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  trend >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 12,
                  color: trend >= 0 ? AppColors.success : AppColors.error,
                ),
                Text(
                  '${trend.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: trend >= 0 ? AppColors.success : AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Charts Coming Soon',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'User growth, workout completion, and performance charts will be available in the next update',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

