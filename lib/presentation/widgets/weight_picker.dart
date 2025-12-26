import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../core/utils/haptic_feedback.dart';

class WeightPicker extends StatefulWidget {
  final Function(double) onWeightSelected;
  final double? initialValue;

  const WeightPicker({
    super.key,
    required this.onWeightSelected,
    this.initialValue,
  });

  @override
  State<WeightPicker> createState() => _WeightPickerState();
}

class _WeightPickerState extends State<WeightPicker> with SingleTickerProviderStateMixin {
  double? _selectedWeight;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Fixed weight options: 5, 10, 15, 20, 25, 30, 35, 40, 45, 50 kg
  static const List<double> _weightOptions = [
    5.0,
    10.0,
    15.0,
    20.0,
    25.0,
    30.0,
    35.0,
    40.0,
    45.0,
    50.0,
  ];

  @override
  void initState() {
    super.initState();
    // Migration logika - konvertovati postojeće weight vrednosti u najbližu opciju
    // Ako je initialValue null ili 0, koristi default vrednost (5.0)
    if (widget.initialValue != null && widget.initialValue! > 0) {
      _selectedWeight = _migrateWeight(widget.initialValue);
    } else {
      // Default to first option (5.0 kg) if no initial value
      _selectedWeight = 5.0;
    }
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Migration logika - konvertovati postojeće weight vrednosti u najbližu opciju
  static double _migrateWeight(double? oldWeight) {
    if (oldWeight == null || oldWeight <= 0) {
      return 5.0; // Default to first option
    }

    if (oldWeight > 50.0) {
      return 50.0; // Max option
    }

    // Pronađi najbližu opciju
    double closestWeight = 5.0; // Default
    double minDistance = double.infinity;

    for (final option in _weightOptions) {
      final distance = (oldWeight - option).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestWeight = option;
      }
    }

    return closestWeight;
  }

  Color _getWeightColor(double weight) {
    // Lighter weights = success, heavier = warning/error gradient
    if (weight <= 15) return AppColors.success;
    if (weight <= 30) return AppColors.warning;
    return AppColors.error;
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
                    'Select Weight',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            // Selected Weight Display
            if (_selectedWeight != null)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getWeightColor(_selectedWeight!),
                        _getWeightColor(_selectedWeight!).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getWeightColor(_selectedWeight!).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_selectedWeight!.toStringAsFixed(0)} kg',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

            // Weight options using Wrap layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _weightOptions.map((weight) {
                  final isSelected = _selectedWeight != null &&
                      (_selectedWeight! - weight).abs() < 0.1;
                  return GestureDetector(
                    onTap: () {
                      AppHaptic.selection();
                      setState(() {
                        _selectedWeight = weight;
                      });
                      _animationController.forward(from: 0.0).then((_) {
                        if (mounted && _animationController.isAnimating) {
                          _animationController.reverse();
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  _getWeightColor(weight),
                                  _getWeightColor(weight).withValues(alpha: 0.7),
                                ],
                              )
                            : AppGradients.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.primary.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _getWeightColor(weight).withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '${weight.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
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
                    final isEnabled = _selectedWeight != null;
                    return ElevatedButton(
                      onPressed: isEnabled
                          ? () {
                              try {
                                AppHaptic.medium();
                                widget.onWeightSelected(_selectedWeight!);
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                debugPrint('[WeightPicker] ❌ ERROR in confirm flow: $e');
                              }
                            }
                          : null,
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

