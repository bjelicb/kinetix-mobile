import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import 'gradient_card.dart';
import 'neon_button.dart';

class PaywallDialog extends StatelessWidget {
  final double balance;
  final VoidCallback? onNavigateToPayment;

  const PaywallDialog({
    super.key,
    required this.balance,
    this.onNavigateToPayment,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('[Paywall:Block] Balance outstanding - Showing paywall dialog');
    
    return PopScope(
      canPop: false, // Non-dismissible
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: GradientCard(
          gradient: LinearGradient(
            colors: [
              AppColors.error.withValues(alpha: 0.2),
              AppColors.error.withValues(alpha: 0.1),
            ],
          ),
          borderColor: AppColors.error,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppGradients.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  size: 32,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Payment Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Balance Amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${balance.toStringAsFixed(2)}€',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Message
              Text(
                'Your balance for last month is ${balance.toStringAsFixed(2)}€. Pay to continue training.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Button
              NeonButton(
                text: 'View Payment Details',
                icon: Icons.payment_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  onNavigateToPayment?.call();
                },
                gradient: AppGradients.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

