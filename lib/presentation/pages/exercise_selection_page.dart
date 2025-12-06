import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../domain/entities/exercise.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/exercise_details_modal.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../services/exercise_library_service.dart';

class ExerciseSelectionPage extends StatefulWidget {
  const ExerciseSelectionPage({super.key});

  @override
  State<ExerciseSelectionPage> createState() => _ExerciseSelectionPageState();
}

class _ExerciseSelectionPageState extends State<ExerciseSelectionPage> {
  final _searchController = TextEditingController();
  final _exerciseService = ExerciseLibraryService.instance;
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  final List<String> _selectedMuscleGroups = [];
  final List<String> _selectedEquipment = [];
  bool _isLoading = true;
  List<String> _availableEquipment = [];
  final Set<String> _selectedExerciseIds = {};
  Timer? _debounceTimer;
  final Map<String, List<Exercise>> _searchCache = {};

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _filterExercises();
    });
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _allExercises = await _exerciseService.getAllExercises();
      _availableEquipment = await _exerciseService.getAllEquipment();
      _filteredExercises = List.from(_allExercises);
    } catch (e) {
      debugPrint('Error loading exercises: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _filterExercises() async {
    final query = _searchController.text.toLowerCase().trim();
    
    List<Exercise> filtered = _allExercises;

    // Search filter with cache
    if (query.isNotEmpty) {
      if (_searchCache.containsKey(query)) {
        filtered = _searchCache[query]!;
      } else {
        filtered = await _exerciseService.searchExercises(query);
        _searchCache[query] = filtered;
        // Limit cache size to prevent memory issues
        if (_searchCache.length > 50) {
          final firstKey = _searchCache.keys.first;
          _searchCache.remove(firstKey);
        }
      }
    }

    // Muscle group filter
    if (_selectedMuscleGroups.isNotEmpty) {
      filtered = filtered.where((exercise) {
        return _selectedMuscleGroups.contains(exercise.targetMuscle);
      }).toList();
    }

    // Equipment filter
    if (_selectedEquipment.isNotEmpty) {
      filtered = filtered.where((exercise) {
        if (exercise.equipment == null) return false;
        return _selectedEquipment.any((eq) => exercise.equipment!.contains(eq));
      }).toList();
    }

    if (mounted) {
      setState(() {
        _filteredExercises = filtered;
      });
    }
  }

  List<String> get _availableMuscleGroups {
    return _allExercises
        .map((e) => e.targetMuscle)
        .toSet()
        .toList()
      ..sort();
  }

  void _toggleMuscleGroup(String muscleGroup) {
    setState(() {
      if (_selectedMuscleGroups.contains(muscleGroup)) {
        _selectedMuscleGroups.remove(muscleGroup);
      } else {
        _selectedMuscleGroups.add(muscleGroup);
      }
      _filterExercises();
    });
    AppHaptic.light();
  }

  void _toggleEquipment(String equipment) {
    setState(() {
      if (_selectedEquipment.contains(equipment)) {
        _selectedEquipment.remove(equipment);
      } else {
        _selectedEquipment.add(equipment);
      }
      _filterExercises();
    });
    AppHaptic.light();
  }

  Future<void> _showExerciseDetails(Exercise exercise) async {
    AppHaptic.light();
    final selected = await ExerciseDetailsModal.show(
      context: context,
      exercise: exercise,
    );
    if (selected != null && mounted) {
      context.pop(selected);
    }
  }

  void _toggleExerciseSelection(Exercise exercise) {
    setState(() {
      if (_selectedExerciseIds.contains(exercise.id)) {
        _selectedExerciseIds.remove(exercise.id);
      } else {
        _selectedExerciseIds.add(exercise.id);
      }
    });
    AppHaptic.light();
  }

  void _confirmSelection() {
    if (_selectedExerciseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one exercise'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final selectedExercises = _allExercises
        .where((e) => _selectedExerciseIds.contains(e.id))
        .toList();
    
    AppHaptic.success();
    context.pop(selectedExercises);
  }

  void _createNewExercise() {
    // For now, show a simple dialog
    // In future, this could navigate to a full exercise creation page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Create Exercise'),
        content: const Text('Exercise creation will be implemented later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            onPressed: () {
              AppHaptic.light();
              context.pop();
            },
          ),
          title: Text(
            'Select Exercise',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          actions: [
            if (_selectedExerciseIds.isNotEmpty)
              TextButton(
                onPressed: _confirmSelection,
                child: Text(
                  'Add (${_selectedExerciseIds.length})',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
              onPressed: _createNewExercise,
              tooltip: 'Create Exercise',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _searchController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              
              // Filters
              if (!_isLoading) ...[
                // Muscle Group Filters
                if (_availableMuscleGroups.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _availableMuscleGroups.length,
                      itemBuilder: (context, index) {
                        final muscleGroup = _availableMuscleGroups[index];
                        final isSelected = _selectedMuscleGroups.contains(muscleGroup);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(muscleGroup),
                            selected: isSelected,
                            onSelected: (_) => _toggleMuscleGroup(muscleGroup),
                            selectedColor: AppColors.primary.withValues(alpha: 0.3),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary.withValues(alpha: 0.3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                // Equipment Filters
                if (_availableEquipment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _availableEquipment.length,
                      itemBuilder: (context, index) {
                        final equipment = _availableEquipment[index];
                        final isSelected = _selectedEquipment.contains(equipment);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(equipment),
                            selected: isSelected,
                            onSelected: (_) => _toggleEquipment(equipment),
                            selectedColor: AppColors.secondary.withValues(alpha: 0.3),
                            checkmarkColor: AppColors.secondary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.textSecondary,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.textSecondary.withValues(alpha: 0.3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
              ],
              
              // Exercises List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _filteredExercises.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No exercises found',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _filteredExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = _filteredExercises[index];
                              final isSelected = _selectedExerciseIds.contains(exercise.id);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GradientCard(
                                  padding: const EdgeInsets.all(16),
                                  onTap: () => _showExerciseDetails(exercise),
                                  child: Row(
                                    children: [
                                      // Selection Checkbox
                                      GestureDetector(
                                        onTap: () => _toggleExerciseSelection(exercise),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                              width: 2,
                                            ),
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.transparent,
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 16,
                                                  color: AppColors.textPrimary,
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: AppGradients.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.fitness_center_rounded,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exercise.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                if (exercise.category != null) ...[
                                                  Text(
                                                    exercise.category!,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '•',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                ],
                                                Text(
                                                  exercise.targetMuscle,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons.info_outline_rounded,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                        ),
                                        onPressed: () => _showExerciseDetails(exercise),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

