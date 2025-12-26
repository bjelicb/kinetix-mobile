import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../data/datasources/remote_data_source.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _processing = false;
  Map<String, dynamic>? _balanceData;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    debugPrint('[PaymentPage] _loadBalance START');
    try {
      final storage = FlutterSecureStorage();
      final dio = Dio();
      final remoteDataSource = RemoteDataSource(dio, storage);
      
      debugPrint('[PaymentPage] Calling getBalance()...');
      final balance = await remoteDataSource.getBalance();
      debugPrint('[PaymentPage] getBalance() response: $balance');
      debugPrint('[PaymentPage] balance value: ${balance['balance']}');
      debugPrint('[PaymentPage] monthlyBalance value: ${balance['monthlyBalance']}');
      debugPrint('[PaymentPage] penaltyHistory: ${balance['penaltyHistory']}');
      
      setState(() {
        _balanceData = balance;
      });
      
      debugPrint('[PaymentPage] _loadBalance SUCCESS - Balance: ${balance['balance']}€, Monthly: ${balance['monthlyBalance']}€');
    } catch (e, stackTrace) {
      debugPrint('[PaymentPage] _loadBalance ERROR: $e');
      debugPrint('[PaymentPage] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading balance: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _processPayment() async {
    debugPrint('[PaymentPage] _processPayment START');
    
    final currentBalance = (_balanceData?['balance'] as num?)?.toDouble() ?? 0.0;
    final currentMonthlyBalance = (_balanceData?['monthlyBalance'] as num?)?.toDouble() ?? 0.0;
    debugPrint('[PaymentPage] Current balance before payment: balance=$currentBalance€, monthlyBalance=$currentMonthlyBalance€');
    
    setState(() {
      _processing = true;
    });

    try {
      final storage = FlutterSecureStorage();
      final dio = Dio();
      final remoteDataSource = RemoteDataSource(dio, storage);
      
      debugPrint('[PaymentPage] Calling clearBalance() API...');
      // TODO: In Phase 2, integrate with Stripe
      // For now, just clear the balance (manual payment)
      await remoteDataSource.clearBalance();
      debugPrint('[PaymentPage] clearBalance() API call SUCCESS');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Balance cleared successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        debugPrint('[PaymentPage] Reloading balance after payment...');
        // Reload balance
        await _loadBalance();
        debugPrint('[PaymentPage] Balance reloaded after payment');
        
        // Navigate back with result to trigger refresh on dashboard
        if (mounted) {
          debugPrint('[PaymentPage] Navigating back to previous page with success result');
          context.pop(true); // Return true to indicate successful payment
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[PaymentPage] _processPayment ERROR: $e');
      debugPrint('[PaymentPage] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
        debugPrint('[PaymentPage] _processPayment END - processing flag set to false');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = (_balanceData?['balance'] as num?)?.toDouble() ?? 0.0;
    final monthlyBalance = (_balanceData?['monthlyBalance'] as num?)?.toDouble() ?? 0.0;
    final penaltyHistory = _balanceData?['penaltyHistory'] as List? ?? [];

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Payment'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Balance Summary
                GradientCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '€${balance.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (monthlyBalance > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'This month: €${monthlyBalance.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Method (Placeholder for Stripe)
                GradientCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.textSecondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Digital payments coming in Phase 2. For now, please pay your trainer directly.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment History
                if (penaltyHistory.isNotEmpty) ...[
                  Text(
                    'Payment History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...penaltyHistory.take(10).map((entry) {
                    final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
                    final reason = entry['reason'] as String? ?? 'Unknown';
                    final date = entry['date'] != null
                        ? DateTime.parse(entry['date'])
                        : DateTime.now();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GradientCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reason,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}/${date.month}/${date.year}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '+€${amount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // Pay Button
                NeonButton(
                  text: balance > 0 ? 'Mark as Paid' : 'No Balance Due',
                  icon: Icons.payment_rounded,
                  onPressed: balance > 0 && !_processing ? _processPayment : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

