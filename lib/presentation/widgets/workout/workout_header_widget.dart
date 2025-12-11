import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../domain/entities/workout.dart';
import '../gradient_card.dart';

class WorkoutHeader extends StatelessWidget {
  final Workout workout;
  final String formattedTime;
  final bool isPaused;
  final VoidCallback onPauseToggle;

  const WorkoutHeader({
    super.key,
    required this.workout,
    required this.formattedTime,
    required this.isPaused,
    required this.onPauseToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  workout.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: onPauseToggle,
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Timer
          GradientCard(
            gradient: AppGradients.primary,
            padding: const EdgeInsets.all(16),
            margin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer_rounded,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

