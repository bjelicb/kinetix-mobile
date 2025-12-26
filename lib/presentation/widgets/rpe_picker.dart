import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../core/utils/haptic_feedback.dart';

class RpePicker extends StatefulWidget {
  final Function(double) onRpeSelected;
  final double? initialValue;

  const RpePicker({
    super.key,
    required this.onRpeSelected,
    this.initialValue,
  });

  @override
  State<RpePicker> createState() => _RpePickerState();
}

class _RpePickerState extends State<RpePicker> with SingleTickerProviderStateMixin {
  double? _selectedRpe;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // NOVO: Migration logika - konvertovati postojeće RPE vrednosti u najbližu opciju
    if (widget.initialValue != null) {
      _selectedRpe = _migrateRpe(widget.initialValue);
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

  // NOVO: RPE mapping sa 3 opcije
  static const Map<String, double> _rpeOptions = {
    'Lako': 4.5,   // 4-5 range
    'Ok': 6.5,     // 6-7 range
    'Teško': 8.5,  // 8-9 range
  };

  // NOVO: Migration logika - konvertovati postojeće RPE vrednosti u najbližu opciju
  static double _migrateRpe(double? oldRpe) {
    if (oldRpe == null) return 6.5; // Default to "Ok"
    
    // Pronađi najbližu opciju
    double closestRpe = 6.5; // Default
    double minDistance = double.infinity;
    
    for (final option in _rpeOptions.values) {
      final distance = (oldRpe - option).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestRpe = option;
      }
    }
    
    return closestRpe;
  }

  Color _getRpeColor(double rpe) {
    if (rpe <= 5) return AppColors.success;
    if (rpe <= 7) return AppColors.warning;
    return AppColors.error;
  }

  String _getRpeLabel(double rpe) {
    if (rpe <= 5) return 'Lako';
    if (rpe <= 7) return 'Ok';
    return 'Teško';
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
                    'Rate of Perceived Exertion',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            
            // Selected RPE Display
            if (_selectedRpe != null)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getRpeColor(_selectedRpe!),
                        _getRpeColor(_selectedRpe!).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _getRpeColor(_selectedRpe!).withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedRpe!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _getRpeLabel(_selectedRpe!),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // NOVO: RPE sa 3 opcije umesto 1-10 grid
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: _rpeOptions.entries.map((entry) {
                  final isSelected = _selectedRpe != null && 
                      (_selectedRpe! - entry.value).abs() < 0.1;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                        onTap: () {
                          AppHaptic.selection();
                          setState(() {
                            _selectedRpe = entry.value;
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
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      _getRpeColor(entry.value),
                                      _getRpeColor(entry.value).withValues(alpha: 0.7),
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
                                      color: _getRpeColor(entry.value).withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.key,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.value.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Confirm Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedRpe != null
                      ? () {
                          try {
                            AppHaptic.medium();
                            widget.onRpeSelected(_selectedRpe!);
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            debugPrint('[RpePicker] ❌ ERROR in confirm flow: $e');
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

