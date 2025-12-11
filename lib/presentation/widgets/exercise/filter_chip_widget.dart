import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable filter chip widget
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(String) onToggle;
  final Color selectedColor;
  final Color checkmarkColor;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onToggle,
    required this.selectedColor,
    required this.checkmarkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onToggle(label),
        selectedColor: selectedColor.withValues(alpha: 0.3),
        checkmarkColor: checkmarkColor,
        labelStyle: TextStyle(
          color: isSelected ? checkmarkColor : AppColors.textSecondary,
        ),
        side: BorderSide(
          color: isSelected
              ? checkmarkColor
              : AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

