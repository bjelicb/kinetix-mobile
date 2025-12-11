import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../gradient_card.dart';

/// Workout name input widget
class WorkoutNameInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const WorkoutNameInputWidget({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Name',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Enter workout name',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: validator ??
                (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a workout name';
                  }
                  return null;
                },
          ),
        ],
      ),
    );
  }
}

