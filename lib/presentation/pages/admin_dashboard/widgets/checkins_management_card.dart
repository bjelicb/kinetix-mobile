import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../widgets/gradient_card.dart';
import '../../../widgets/neon_button.dart';
import '../modals/checkin_details_modal.dart';
import '../../../../core/utils/date_utils.dart';

class CheckinsManagementCard extends ConsumerStatefulWidget {
  const CheckinsManagementCard({super.key});

  @override
  ConsumerState<CheckinsManagementCard> createState() => _CheckinsManagementCardState();
}

class _CheckinsManagementCardState extends ConsumerState<CheckinsManagementCard> {
  List<Map<String, dynamic>> _checkIns = [];
  bool _isLoading = false;
  String _filterClient = 'ALL';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _loadCheckIns();
  }

  Future<void> _loadCheckIns() async {
    setState(() => _isLoading = true);
    
    debugPrint('[AdminDashboard:CheckIns] Loading check-ins with filters: client=$_filterClient, start=$_filterStartDate, end=$_filterEndDate');
    
    try {
      // TODO: Load check-ins from API
      // final checkIns = await ref.read(adminControllerProvider.notifier).getCheckIns(
      //   clientId: _filterClient != 'ALL' ? _filterClient : null,
      //   startDate: _filterStartDate,
      //   endDate: _filterEndDate,
      // );
      
      // Mock data for now
      _checkIns = [];
      
      debugPrint('[AdminDashboard:CheckIns] Loaded ${_checkIns.length} check-ins');
    } catch (e) {
      debugPrint('[AdminDashboard:CheckIns] Error loading check-ins: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCheckIn(String checkInId) async {
    debugPrint('[AdminDashboard:CheckIns] Delete check-in $checkInId - Success');
    
    try {
      // TODO: Delete check-in via API
      // await ref.read(adminControllerProvider.notifier).deleteCheckIn(checkInId);
      
      setState(() {
        _checkIns.removeWhere((c) => c['_id'] == checkInId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting check-in: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportCheckIns() async {
    debugPrint('[AdminDashboard:CheckIns] Export initiated - ${_checkIns.length} records');
    
    // TODO: Implement export functionality
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export feature coming soon'),
          backgroundColor: AppColors.info,
        ),
      );
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
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Check-ins Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              NeonButton(
                text: 'Export',
                icon: Icons.download_rounded,
                onPressed: _exportCheckIns,
                isSmall: true,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Filters
          _buildFilters(),
          
          const SizedBox(height: 20),
          
          // Check-ins List
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_checkIns.isEmpty)
            _buildEmptyState()
          else
            _buildCheckInsList(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Client Filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: DropdownButton<String>(
            value: _filterClient,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('All Clients')),
              // TODO: Add client options
            ],
            onChanged: (value) {
              setState(() => _filterClient = value ?? 'ALL');
              _loadCheckIns();
            },
          ),
        ),
        
        // Date Range Filter
        TextButton.icon(
          onPressed: () async {
            // TODO: Show date range picker
          },
          icon: const Icon(Icons.date_range_rounded, size: 18),
          label: Text(
            _filterStartDate != null && _filterEndDate != null
                ? '${AppDateUtils.formatDisplayDate(_filterStartDate!)} - ${AppDateUtils.formatDisplayDate(_filterEndDate!)}'
                : 'Date Range',
          ),
        ),
        
        // Clear Filters
        if (_filterClient != 'ALL' || _filterStartDate != null)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _filterClient = 'ALL';
                _filterStartDate = null;
                _filterEndDate = null;
              });
              _loadCheckIns();
            },
            icon: const Icon(Icons.clear_rounded, size: 18),
            label: const Text('Clear'),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No check-ins found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check-ins will appear here once clients start checking in',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _checkIns.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final checkIn = _checkIns[index];
        return _buildCheckInItem(checkIn);
      },
    );
  }

  Widget _buildCheckInItem(Map<String, dynamic> checkIn) {
    final date = DateTime.parse(checkIn['checkinDate'] ?? DateTime.now().toIso8601String());
    final clientName = checkIn['clientName'] ?? 'Unknown Client';
    final photoUrl = checkIn['photoUrl'];
    
    return GradientCard(
      padding: const EdgeInsets.all(12),
      margin: EdgeInsets.zero,
      gradient: LinearGradient(
        colors: [
          AppColors.surface1.withValues(alpha: 0.5),
          AppColors.surface1.withValues(alpha: 0.3),
        ],
      ),
      child: Row(
        children: [
          // Photo Thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              image: photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoUrl == null
                ? const Icon(Icons.image_outlined, color: AppColors.textSecondary)
                : null,
          ),
          
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppDateUtils.formatDisplayDate(date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          Row(
            children: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CheckinDetailsModal(checkIn: checkIn),
                  );
                },
                icon: const Icon(Icons.visibility_rounded),
                color: AppColors.primary,
              ),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Check-in'),
                      content: const Text('Are you sure you want to delete this check-in?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteCheckIn(checkIn['_id']);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

