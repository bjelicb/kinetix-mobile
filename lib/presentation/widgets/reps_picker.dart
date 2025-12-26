import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../core/utils/haptic_feedback.dart';

class RepsPicker extends StatefulWidget {
  final List<int> options;
  final int initialValue;
  final Function(int) onRepsSelected;

  const RepsPicker({
    super.key,
    required this.options,
    required this.initialValue,
    required this.onRepsSelected,
  });

  @override
  State<RepsPicker> createState() => _RepsPickerState();
}

class _RepsPickerState extends State<RepsPicker> {
  late int _selectedReps;

  @override
  void initState() {
    super.initState();
    _selectedReps = widget.initialValue;
  }

  void _onConfirm() {
    if (_selectedReps > 0) {
      try {
        AppHaptic.medium();
        widget.onRepsSelected(_selectedReps);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('[RepsPicker] ❌ ERROR in confirm flow: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Select Reps',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Reps options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.options.map((reps) {
                  final isSelected = _selectedReps == reps;
                  return GestureDetector(
                    onTap: () {
                      AppHaptic.selection();
                      setState(() {
                        _selectedReps = reps;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.primary : null,
                        color: isSelected ? null : AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        '$reps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // Confirm Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: Builder(
                  builder: (context) {
                    final isEnabled = _selectedReps > 0;
                    return ElevatedButton(
                      onPressed: isEnabled ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


