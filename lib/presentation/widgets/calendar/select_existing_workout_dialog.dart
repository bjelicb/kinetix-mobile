import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/workout.dart';
import '../../pages/calendar/utils/calendar_utils.dart';

/// Dialog for selecting an existing workout to schedule
class SelectExistingWorkoutDialog {
  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime selectedDay,
    required List<Workout> workouts,
    required Function(Workout) onWorkoutSelected,
  }) {
    if (workouts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No workouts available. Create a new one first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Select Workout'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return ListTile(
                title: Text(workout.name),
                subtitle: Text(CalendarUtils.formatDateForWorkout(workout.scheduledDate)),
                onTap: () {
                  Navigator.pop(context);
                  onWorkoutSelected(workout);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

