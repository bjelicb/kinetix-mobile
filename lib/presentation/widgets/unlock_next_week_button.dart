import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/datasources/remote_data_source.dart';
import '../controllers/common_providers.dart';
import 'gradient_card.dart';
import 'neon_button.dart';

class UnlockNextWeekButton extends ConsumerStatefulWidget {
  const UnlockNextWeekButton({super.key});

  @override
  ConsumerState<UnlockNextWeekButton> createState() => _UnlockNextWeekButtonState();
}

class _UnlockNextWeekButtonState extends ConsumerState<UnlockNextWeekButton> {
  bool _isEligible = false;
  bool _hasPendingRequest = false;
  bool _isLoading = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    setState(() => _isLoading = true);
    
    try {
      // Get user ID
      final localDataSource = LocalDataSource();
      final users = await localDataSource.getUsers();
      
      if (users.isEmpty) {
        debugPrint('[UnlockNextWeek:Eligibility] No users found');
        setState(() {
          _isEligible = false;
          _hasPendingRequest = false;
        });
        return;
      }
      
      final clientId = users.first.serverId;
      
      // Check eligibility via API
      final remoteDataSource = RemoteDataSource(
        ref.read(dioProvider),
        ref.read(secureStorageProvider),
      );
      
      final canUnlock = await remoteDataSource.canUnlockNextWeek(clientId);
      
      debugPrint('[UnlockNextWeek:Eligibility] Can unlock: $canUnlock');
      
      setState(() {
        _isEligible = canUnlock;
        _hasPendingRequest = false; // TODO: Get pending request status from backend
      });
      
    } catch (e) {
      debugPrint('[UnlockNextWeek:Eligibility] Error checking eligibility: $e');
      setState(() {
        _isEligible = false;
        _hasPendingRequest = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestNextWeek() async {
    setState(() => _isRequesting = true);
    
    try {
      // Get user ID
      final localDataSource = LocalDataSource();
      final users = await localDataSource.getUsers();
      
      if (users.isEmpty) {
        throw Exception('User not found');
      }
      
      final clientId = users.first.serverId;
      
      // Send request to trainer via API
      final remoteDataSource = RemoteDataSource(
        ref.read(dioProvider),
        ref.read(secureStorageProvider),
      );
      
      debugPrint('[UnlockNextWeek:Request] Sending unlock request to trainer');
      await remoteDataSource.requestNextWeek(clientId);
      debugPrint('[UnlockNextWeek:Request] ✓ Request sent successfully');
      
      setState(() {
        _hasPendingRequest = true;
        _isEligible = false; // Hide button after request
      });
      
      debugPrint('[UnlockNextWeek:UI] Showing pending state');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent to your trainer'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('[UnlockNextWeek:Request] ✗ Error sending request: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }
    
    if (!_isEligible) {
      return const SizedBox.shrink();
    }
    
    if (_hasPendingRequest) {
      return GradientCard(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.2),
            AppColors.warning.withValues(alpha: 0.1),
          ],
        ),
        borderColor: AppColors.warning,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Pending',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Waiting for trainer approval',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return NeonButton(
      text: 'Request Next Week',
      icon: Icons.lock_open_rounded,
      onPressed: _isRequesting ? null : _requestNextWeek,
      gradient: AppGradients.success,
    );
  }
}

