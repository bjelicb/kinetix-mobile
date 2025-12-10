import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/gradient_card.dart';
import '../widgets/neon_button.dart';
import 'package:go_router/go_router.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double monthlyBalance;
  final DateTime? lastBalanceReset;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.monthlyBalance,
    this.lastBalanceReset,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('[BalanceCard] Building - balance: $balance€, monthlyBalance: $monthlyBalance€');
    debugPrint('[BalanceCard] Showing balance card (always visible for testing)');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GradientCard(
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
                      'Running Tab',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '€${balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: balance > 0 ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (monthlyBalance > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'This month: €${monthlyBalance.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else if (balance == 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'No balance due',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
                if (balance > 0)
                  NeonButton(
                    text: 'Pay Now',
                    icon: Icons.payment_rounded,
                    onPressed: () {
                      context.push('/payment');
                    },
                  ),
              ],
            ),
            if (balance > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Clear your balance to unlock next month',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

