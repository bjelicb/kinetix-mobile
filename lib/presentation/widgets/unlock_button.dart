import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../controllers/workout_controller.dart';
import '../controllers/calendar_controller.dart';
import 'neon_button.dart';

/// Always-visible unlock button with pulsing animation
/// Shows dialog when unlock is not possible
class UnlockButton extends ConsumerStatefulWidget {
  final String? label;
  final bool compact; // For small spaces (locked day view)
  
  const UnlockButton({
    super.key,
    this.label,
    this.compact = false,
  });

  @override
  ConsumerState<UnlockButton> createState() => _UnlockButtonState();
}

class _UnlockButtonState extends ConsumerState<UnlockButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isProcessing = false; // Prevent double-tap

  @override
  void initState() {
    super.initState();
    
    // Pulsing animation (1.0 → 1.05 → 1.0)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final unlockState = ref.watch(unlockNextWeekProvider);
    final isUnlocking = unlockState.isLoading;
    
    // Pause animation when unlocking
    if (isUnlocking && _pulseController.isAnimating) {
      _pulseController.stop();
    } else if (!isUnlocking && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
    
    return ScaleTransition(
      scale: _pulseAnimation,
      child: widget.compact ? _buildCompactButton(isUnlocking) : _buildFullButton(isUnlocking),
    );
  }
  
  Widget _buildCompactButton(bool isUnlocking) {
    return ElevatedButton.icon(
      onPressed: (_isProcessing || isUnlocking) ? null : _handleUnlockAttempt,
      icon: isUnlocking
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.lock_open_rounded, size: 18),
      label: Text(widget.label ?? 'Unlock'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        disabledBackgroundColor: AppColors.success.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
  
  Widget _buildFullButton(bool isUnlocking) {
    return NeonButton(
      text: widget.label ?? 'Unlock Next Week',
      icon: Icons.lock_open_rounded,
      onPressed: (_isProcessing || isUnlocking) ? null : _handleUnlockAttempt,
      gradient: AppGradients.success,
      isLoading: isUnlocking,
    );
  }
  
  Future<void> _handleUnlockAttempt() async {
    if (_isProcessing) return; // Debounce
    
    debugPrint('[UnlockButton] Unlock attempt START');
    
    setState(() => _isProcessing = true);
    
    try {
      // 1. Check if unlock is possible
      debugPrint('[UnlockButton] Checking eligibility via canUnlockNextWeekProvider...');
      final canUnlock = await ref.read(canUnlockNextWeekProvider.future);
      
      debugPrint('[UnlockButton] Eligibility check result: canUnlock=$canUnlock');
      
      if (!mounted) {
        debugPrint('[UnlockButton] Widget unmounted, aborting');
        return;
      }
      
      if (!canUnlock) {
        // Show dialog explaining why unlock is not possible
        debugPrint('[UnlockButton] Cannot unlock - showing blocked dialog');
        await _showUnlockBlockedDialog();
        return;
      }
      
      // 2. Proceed with unlock
      debugPrint('[UnlockButton] Eligibility confirmed - calling unlock provider...');
      await ref.read(unlockNextWeekProvider.notifier).unlock();
      
      if (!mounted) {
        debugPrint('[UnlockButton] Widget unmounted after unlock, aborting');
        return;
      }
      
      final unlockState = ref.read(unlockNextWeekProvider);
      
      debugPrint('[UnlockButton] Unlock state: ${unlockState.runtimeType}');
      
      unlockState.whenOrNull(
        data: (_) {
          debugPrint('[UnlockButton] Unlock SUCCESS - showing success snackbar');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔓 Next week unlocked! Balance charged.'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        },
        error: (error, _) {
          debugPrint('[UnlockButton] Unlock ERROR: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $error'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('[UnlockButton] Exception during unlock attempt: $e');
      
      if (!mounted) {
        debugPrint('[UnlockButton] Widget unmounted after exception, aborting');
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to check unlock status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        debugPrint('[UnlockButton] Unlock attempt COMPLETE - resetting processing state');
        setState(() => _isProcessing = false);
      }
    }
  }
  
  Future<void> _showUnlockBlockedDialog() async {
    final calendarData = await ref.read(calendarDataProvider.future);
    
    // Determine reason for block
    String title;
    String message;
    IconData icon;
    
    if (calendarData.currentPlanId == null) {
      // No plan assigned
      title = 'No Plan Assigned';
      message = 'Your trainer hasn\'t created your first plan yet. Contact them to get started!';
      icon = Icons.assignment_outlined;
    } else {
      // Has plan but not completed
      final currentPlanWorkouts = calendarData.workouts
          .where((w) => w.planId == calendarData.currentPlanId)
          .toList();
      
      if (currentPlanWorkouts.isEmpty) {
        title = 'Plan Not Started';
        message = 'Your current plan hasn\'t started yet. Check back when workouts are available.';
        icon = Icons.schedule_outlined;
      } else {
        // Check incomplete workouts
        final incompleteWorkouts = currentPlanWorkouts
            .where((w) => !w.isRestDay && !w.isCompleted)
            .toList();
        
        final lastWorkoutDate = currentPlanWorkouts.isNotEmpty
            ? currentPlanWorkouts.map((w) => w.scheduledDate).reduce((a, b) => a.isAfter(b) ? a : b)
            : null;
        
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        
        if (lastWorkoutDate != null && todayOnly.isBefore(DateTime(lastWorkoutDate.year, lastWorkoutDate.month, lastWorkoutDate.day))) {
          title = 'Current Week Active';
          message = 'Your current week hasn\'t ended yet. Complete all workouts first!';
          icon = Icons.fitness_center;
        } else if (incompleteWorkouts.isNotEmpty) {
          title = 'Incomplete Workouts';
          message = 'You have ${incompleteWorkouts.length} incomplete workout(s). Finish them to unlock next week!';
          icon = Icons.warning_amber_rounded;
        } else {
          title = 'Cannot Unlock';
          message = 'Complete your current week to unlock the next one.';
          icon = Icons.lock_outline;
        }
      }
    }
    
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.warning.withValues(alpha: 0.3), width: 1),
        ),
        icon: Icon(icon, size: 48, color: AppColors.warning),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it', style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
  }
}

