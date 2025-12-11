import 'package:flutter/material.dart';
import '../../controllers/analytics_controller.dart';
import '../strength_progression_chart.dart';
import '../shimmer_loader.dart';

/// Widget for progress tab showing strength progression
class ProgressTabWidget extends StatelessWidget {
  final ClientAnalytics? analytics;
  final bool isLoading;

  const ProgressTabWidget({
    super.key,
    required this.analytics,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || analytics == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ShimmerCard(height: 300),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Strength Progression',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        StrengthProgressionChart(
          exerciseData: analytics!.strengthProgression,
          isLoading: isLoading,
        ),
      ],
    );
  }
}

