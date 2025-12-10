import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ExerciseCounter extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  
  const ExerciseCounter({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decrease button
            InkWell(
              onTap: value > min ? () => onChanged(value - step) : null,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: value > min 
                      ? AppColors.surface1 
                      : AppColors.surface1.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: value > min
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.remove_rounded,
                  color: value > min
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Value display - Flexible to prevent overflow
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.primaryEnd.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Increase button
            InkWell(
              onTap: value < max ? () => onChanged(value + step) : null,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: value < max
                      ? AppColors.surface1
                      : AppColors.surface1.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: value < max
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: value < max
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

