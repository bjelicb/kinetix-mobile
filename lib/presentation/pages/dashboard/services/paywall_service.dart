import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/user.dart';
import '../../../widgets/paywall_dialog.dart';

/// Service for checking and showing paywall
class PaywallService {
  /// Check if paywall should be shown and display it if needed
  /// Only shows for CLIENT role with negative monthly balance
  /// [onPaymentComplete] - Optional callback to refresh balance after payment
  static void checkPaywall(
    BuildContext context,
    Map<String, dynamic>? balanceData,
    User? user, {
    VoidCallback? onPaymentComplete,
  }) {
    debugPrint('[PaywallService] checkPaywall START - user role: ${user?.role}');
    
    if (user?.role != 'CLIENT') {
      debugPrint('[PaywallService] Skipping paywall check - user is not CLIENT (role: ${user?.role})');
      return;
    }

    // Check if monthly balance is negative
    if (balanceData != null) {
      final monthlyBalance = (balanceData['monthlyBalance'] as num?)?.toDouble() ?? 0.0;
      final balance = (balanceData['balance'] as num?)?.toDouble() ?? 0.0;
      
      debugPrint('[PaywallService] Balance data - balance: $balance€, monthlyBalance: $monthlyBalance€');
      debugPrint('[PaywallService] Paywall condition check - monthlyBalance < 0: ${monthlyBalance < 0}');
      
      if (monthlyBalance < 0) {
        debugPrint('[PaywallService] Paywall condition MET - Showing PaywallDialog with balance: ${monthlyBalance.abs()}€');
        // Show paywall dialog (non-dismissible)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => PaywallDialog(
                balance: monthlyBalance.abs(),
                onNavigateToPayment: () {
                  // Close dialog first using root navigator
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                  // Navigate to payment and ALWAYS refresh balance and re-check paywall when returning
                  context.push('/payment').then((result) {
                    debugPrint('[PaywallService] Payment page returned with result: $result');
                    // ALWAYS refresh balance and re-check paywall when returning from payment page
                    // This ensures paywall is shown again if balance is still negative
                    if (onPaymentComplete != null) {
                      debugPrint('[PaywallService] Returning from payment page - refreshing balance and re-checking paywall');
                      onPaymentComplete();
                    }
                  });
                },
              ),
            );
            debugPrint('[PaywallService] PaywallDialog shown successfully');
          } else {
            debugPrint('[PaywallService] WARNING - Context not mounted, PaywallDialog not shown');
          }
        });
      } else {
        debugPrint('[PaywallService] Paywall condition NOT MET - monthlyBalance is not negative ($monthlyBalance€), paywall will not be shown');
      }
    } else {
      debugPrint('[PaywallService] Balance data is null - paywall check skipped');
    }
  }
}

