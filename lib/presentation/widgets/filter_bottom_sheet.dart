import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/widgets/glass_bottom_sheet.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../core/utils/haptic_feedback.dart';

enum DateFilter {
  today,
  thisWeek,
  thisMonth,
  all,
  custom,
}

enum StatusFilter {
  completed,
  pending,
  all,
}

class FilterOptions {
  final DateFilter? dateFilter;
  final StatusFilter? statusFilter;
  final String? exerciseId;
  final String? muscleGroup;
  final DateTimeRange? customDateRange;

  FilterOptions({
    this.dateFilter,
    this.statusFilter,
    this.exerciseId,
    this.muscleGroup,
    this.customDateRange,
  });

  FilterOptions copyWith({
    DateFilter? dateFilter,
    StatusFilter? statusFilter,
    String? exerciseId,
    String? muscleGroup,
    DateTimeRange? customDateRange,
  }) {
    return FilterOptions(
      dateFilter: dateFilter ?? this.dateFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      exerciseId: exerciseId ?? this.exerciseId,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      customDateRange: customDateRange ?? this.customDateRange,
    );
  }

  bool get hasActiveFilters {
    return dateFilter != null ||
        statusFilter != null ||
        exerciseId != null ||
        muscleGroup != null;
  }
}

class FilterBottomSheet extends StatefulWidget {
  final FilterOptions initialFilters;
  final List<String> availableMuscleGroups;
  final List<String> availableExercises; // Exercise names
  final ValueChanged<FilterOptions> onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilters,
    required this.availableMuscleGroups,
    required this.availableExercises,
    required this.onApply,
  });

  static Future<FilterOptions?> show({
    required BuildContext context,
    required FilterOptions initialFilters,
    required List<String> availableMuscleGroups,
    required List<String> availableExercises,
  }) {
    return GlassBottomSheet.show<FilterOptions>(
      context: context,
      title: 'Filter Workouts',
      height: MediaQuery.of(context).size.height * 0.7,
      child: FilterBottomSheet(
        initialFilters: initialFilters,
        availableMuscleGroups: availableMuscleGroups,
        availableExercises: availableExercises,
        onApply: (filters) {
          Navigator.of(context).pop(filters);
        },
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterOptions _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date Filter
        GradientCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    'Today',
                    _filters.dateFilter == DateFilter.today,
                    () {
                      setState(() {
                        _filters = _filters.copyWith(
                          dateFilter: DateFilter.today,
                        );
                      });
                      AppHaptic.selection();
                    },
                  ),
                  _buildFilterChip(
                    'This Week',
                    _filters.dateFilter == DateFilter.thisWeek,
                    () {
                      setState(() {
                        _filters = _filters.copyWith(
                          dateFilter: DateFilter.thisWeek,
                        );
                      });
                      AppHaptic.selection();
                    },
                  ),
                  _buildFilterChip(
                    'This Month',
                    _filters.dateFilter == DateFilter.thisMonth,
                    () {
                      setState(() {
                        _filters = _filters.copyWith(
                          dateFilter: DateFilter.thisMonth,
                        );
                      });
                      AppHaptic.selection();
                    },
                  ),
                  _buildFilterChip(
                    'All',
                    _filters.dateFilter == DateFilter.all,
                    () {
                      setState(() {
                        _filters = _filters.copyWith(
                          dateFilter: DateFilter.all,
                        );
                      });
                      AppHaptic.selection();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Status Filter
        GradientCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip(
                    'Completed',
                    _filters.statusFilter == StatusFilter.completed,
                    () {
                      setState(() {
                        _filters = _filters.copyWith(
                          statusFilter: StatusFilter.completed,
                        );
                      });
                      AppHaptic.selection();
                    },
                  ),
                  _buildFilterChip(
                    'Pending',
                    _filters.statusFilter == StatusFilter.pending,
                    () {
                      setState(() {
                        _filters = _filters.copyWith(
                          statusFilter: StatusFilter.pending,
                        );
                      });
                      AppHaptic.selection();
                    },
                  ),
                  _buildFilterChip(
                    'All',
                    _filters.statusFilter == StatusFilter.all,
                    () {
                      setState(() {
                        _filters = _filters.copyWith(
                          statusFilter: StatusFilter.all,
                        );
                      });
                      AppHaptic.selection();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Muscle Group Filter
        if (widget.availableMuscleGroups.isNotEmpty)
          GradientCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Muscle Group',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.availableMuscleGroups.map((group) {
                    return _buildFilterChip(
                      group,
                      _filters.muscleGroup == group,
                      () {
                        setState(() {
                          _filters = _filters.copyWith(
                            muscleGroup: _filters.muscleGroup == group
                                ? null
                                : group,
                          );
                        });
                        AppHaptic.selection();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 24),
        
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  AppHaptic.medium();
                  setState(() {
                    _filters = FilterOptions();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.surface2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Clear All'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  AppHaptic.heavy();
                  widget.onApply(_filters);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.3),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
