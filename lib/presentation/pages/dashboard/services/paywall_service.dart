import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/entities/user.dart';
import '../../../widgets/paywall_dialog.dart';

/// Service for checking and showing paywall
class PaywallService {
  /// Check if paywall should be shown and display it if needed
  /// Only shows for CLIENT role with negative monthly balance
  static void checkPaywall(
    BuildContext context,
    Map<String, dynamic>? balanceData,
    User? user,
  ) {
    if (user?.role != 'CLIENT') return;

    // Check if monthly balance is negative
    if (balanceData != null) {
      final monthlyBalance = (balanceData['monthlyBalance'] as num?)?.toDouble() ?? 0.0;
      if (monthlyBalance < 0) {
        // Show paywall dialog (non-dismissible)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => PaywallDialog(
                balance: monthlyBalance.abs(),
                onNavigateToPayment: () {
                  Navigator.pop(context);
                  context.push('/payment');
                },
              ),
            );
          }
        });
      }
    }
  }
}

