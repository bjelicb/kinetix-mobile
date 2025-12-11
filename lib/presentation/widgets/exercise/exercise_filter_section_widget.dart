import 'package:flutter/material.dart';
import 'filter_chip_widget.dart';

/// Widget for displaying horizontal scrollable filter chips section
class ExerciseFilterSectionWidget extends StatelessWidget {
  final List<String> items;
  final List<String> selectedItems;
  final Function(String) onToggle;
  final Color selectedColor;
  final Color checkmarkColor;

  const ExerciseFilterSectionWidget({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onToggle,
    required this.selectedColor,
    required this.checkmarkColor,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedItems.contains(item);
          return FilterChipWidget(
            label: item,
            isSelected: isSelected,
            onToggle: onToggle,
            selectedColor: selectedColor,
            checkmarkColor: checkmarkColor,
          );
        },
      ),
    );
  }
}

