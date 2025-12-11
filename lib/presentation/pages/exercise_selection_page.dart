import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/exercise.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/exercise_details_modal.dart';
import '../../presentation/widgets/exercise/exercise_search_bar_widget.dart';
import '../../presentation/widgets/exercise/exercise_filter_section_widget.dart';
import '../../presentation/widgets/exercise/exercise_list_widget.dart';
import '../../presentation/widgets/exercise/create_exercise_dialog.dart';
import '../../core/utils/haptic_feedback.dart';
import 'exercise_selection/services/exercise_search_service.dart';

class ExerciseSelectionPage extends StatefulWidget {
  const ExerciseSelectionPage({super.key});

  @override
  State<ExerciseSelectionPage> createState() => _ExerciseSelectionPageState();
}

class _ExerciseSelectionPageState extends State<ExerciseSelectionPage> {
  final _searchController = TextEditingController();
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
      final result = await ExerciseSearchService.loadExercises();
      _allExercises = result.exercises;
      _availableEquipment = result.availableEquipment;
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
    final query = _searchController.text;

    final filtered = await ExerciseSearchService.filterExercises(
      allExercises: _allExercises,
      searchQuery: query,
      selectedMuscleGroups: _selectedMuscleGroups,
      selectedEquipment: _selectedEquipment,
      searchCache: _searchCache,
    );

    if (mounted) {
      setState(() {
        _filteredExercises = filtered;
      });
    }
  }

  List<String> get _availableMuscleGroups {
    return ExerciseSearchService.getAvailableMuscleGroups(_allExercises);
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
    CreateExerciseDialog.show(context);
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
              ExerciseSearchBarWidget(
                controller: _searchController,
                onClear: () {
                  _searchController.clear();
                },
              ),
              
              // Filters
              if (!_isLoading) ...[
                // Muscle Group Filters
                ExerciseFilterSectionWidget(
                  items: _availableMuscleGroups,
                  selectedItems: _selectedMuscleGroups,
                  onToggle: _toggleMuscleGroup,
                  selectedColor: AppColors.primary,
                  checkmarkColor: AppColors.primary,
                ),
                
                // Equipment Filters
                if (_availableEquipment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ExerciseFilterSectionWidget(
                    items: _availableEquipment,
                    selectedItems: _selectedEquipment,
                    onToggle: _toggleEquipment,
                    selectedColor: AppColors.secondary,
                    checkmarkColor: AppColors.secondary,
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
                    : ExerciseListWidget(
                        exercises: _filteredExercises,
                        selectedExerciseIds: _selectedExerciseIds,
                        onExerciseTap: _showExerciseDetails,
                        onToggleSelection: _toggleExerciseSelection,
                        onShowDetails: _showExerciseDetails,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

