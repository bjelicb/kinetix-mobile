import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../presentation/controllers/checkin_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/empty_state.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../presentation/widgets/cached_image_widget.dart';
import '../../core/utils/haptic_feedback.dart';

class CheckInHistoryPage extends ConsumerStatefulWidget {
  const CheckInHistoryPage({super.key});

  @override
  ConsumerState<CheckInHistoryPage> createState() => _CheckInHistoryPageState();
}

class _CheckInHistoryPageState extends ConsumerState<CheckInHistoryPage> {
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    // In a real app, this would fetch more data from the controller
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final checkInsState = ref.watch(checkInControllerProvider);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
            'Check-In History',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        body: SafeArea(
          child: checkInsState.when(
            data: (checkIns) {
              if (checkIns.isEmpty) {
                return EmptyState(
                  icon: Icons.camera_alt_outlined,
                  title: 'No check-ins yet',
                  message: 'Start your journey by taking your first check-in photo',
                  actionLabel: 'Take Check-In',
                  onAction: () => context.go('/check-in'),
                );
              }

              // Pagination: show only first _pageSize items per page
              final displayedItems = checkIns.take((_currentPage + 1) * _pageSize).toList();
              final hasMore = checkIns.length > displayedItems.length;

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: displayedItems.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == displayedItems.length) {
                    return _isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }
                  final checkIn = displayedItems[index];
                  return _buildCheckInCard(context, checkIn, ref);
                },
              );
            },
            loading: () => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ShimmerCard(height: 100),
                const SizedBox(height: 16),
                ShimmerCard(height: 100),
                const SizedBox(height: 16),
                ShimmerCard(height: 100),
              ],
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading check-ins',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInCard(BuildContext context, checkIn, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    return GradientCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      gradient: AppGradients.card,
      child: Row(
        children: [
          // Photo Thumbnail
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildThumbnail(checkIn.photoLocalPath),
            ),
          ),
          const SizedBox(width: 16),
          
          // Date/Time Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(checkIn.timestamp),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(checkIn.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      checkIn.isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      size: 16,
                      color: checkIn.isSynced ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      checkIn.isSynced ? 'Synced' : 'Pending',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: checkIn.isSynced ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Delete Button
          IconButton(
            icon: const Icon(
              Icons.delete_rounded,
              color: AppColors.error,
            ),
            onPressed: () => _showDeleteDialog(context, checkIn.id, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String photoPath) {
    return CachedImageWidget(
      imagePath: photoPath,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, String checkInId, WidgetRef ref) async {
    AppHaptic.light();
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Delete Check-In',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
          ),
          content: Text(
            'Are you sure you want to delete this check-in? This action cannot be undone.',
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
                'Delete',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      AppHaptic.medium();
      try {
        await ref.read(checkInControllerProvider.notifier).deleteCheckIn(checkInId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Check-in deleted successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete check-in: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

