import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../neon_button.dart';

/// Empty state widget for calendar when no workouts are scheduled
class CalendarEmptyState extends StatelessWidget {
  final VoidCallback onScheduleWorkout;

  const CalendarEmptyState({
    super.key,
    required this.onScheduleWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxHeight < 200
            ? 16.0
            : constraints.maxHeight < 300
                ? 24.0
                : 32.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        gradient: AppGradients.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: constraints.maxHeight < 200 ? 48 : 64,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: padding),
                    Text(
                      'No workouts scheduled',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to schedule a workout for this day',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: padding),
                    NeonButton(
                      text: 'Schedule Workout',
                      onPressed: onScheduleWorkout,
                      gradient: AppGradients.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

