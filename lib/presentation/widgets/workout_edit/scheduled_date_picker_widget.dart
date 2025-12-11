import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../gradient_card.dart';

/// Scheduled date picker widget
class ScheduledDatePickerWidget extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const ScheduledDatePickerWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduled Date',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              // Trigger date selection callback - parent handles showing picker
              onDateSelected(selectedDate);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

