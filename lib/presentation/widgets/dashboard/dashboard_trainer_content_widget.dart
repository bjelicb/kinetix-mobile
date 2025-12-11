import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../client_alerts_card.dart';
import '../appointments_card.dart';

/// Trainer content widget
class DashboardTrainerContent extends StatelessWidget {
  const DashboardTrainerContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClientAlertsCard(),
          const SizedBox(height: AppSpacing.lg),
          AppointmentsCard(),
        ],
      ),
    );
  }
}

