import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart';
import '../../presentation/controllers/workout_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../services/workout_template_service.dart';
import '../../data/models/workout_template.dart';
import 'package:uuid/uuid.dart';
import '../widgets/workout_edit/workout_name_input_widget.dart';
import '../widgets/workout_edit/scheduled_date_picker_widget.dart';
import '../widgets/workout_edit/exercise_list_widget.dart';
import '../widgets/workout_edit/template_selection_dialog.dart';
import '../widgets/workout_edit/apply_template_dialog.dart';
import 'workout_edit/services/workout_edit_service.dart';
import 'workout_edit/services/workout_template_service.dart' as template_service;
import 'workout_edit/utils/date_picker_utils.dart';

class WorkoutEditPage extends ConsumerStatefulWidget {
  final String? workoutId; // null for create, workout id for edit
  final DateTime? selectedDate; // Optional initial date for new workouts

  const WorkoutEditPage({super.key, this.workoutId, this.selectedDate});

  @override
  ConsumerState<WorkoutEditPage> createState() => _WorkoutEditPageState();
}

class _WorkoutEditPageState extends ConsumerState<WorkoutEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<Exercise> _exercises = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    if (widget.workoutId != null) {
      _loadWorkout();
    }
  }

  Future<void> _loadWorkout() async {
    setState(() => _isLoading = true);
    try {
      final workouts = await ref.read(workoutControllerProvider.future);
      final workout = WorkoutEditService.loadWorkout(widget.workoutId!, workouts);

      if (workout != null) {
        _nameController.text = workout.name;
        _selectedDate = workout.scheduledDate;
        _exercises = List.from(workout.exercises);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading workout: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addExercise() async {
    AppHaptic.selection();
    final result = await context.push('/exercise-selection');
    if (result != null && result is Exercise) {
      setState(() {
        _exercises.add(result);
      });
      AppHaptic.medium();
    }
  }

  Future<void> _selectTemplate() async {
    AppHaptic.selection();

    // Only show template selection for new workouts
    if (widget.workoutId != null) {
      return;
    }

    final templates = await WorkoutTemplateService.instance.getAllTemplates();

    if (!mounted) return;

    final selectedTemplate = await TemplateSelectionDialog.show(context: context, templates: templates);

    if (selectedTemplate != null) {
      await _applyTemplate(selectedTemplate);
    }
  }

  Future<void> _applyTemplate(WorkoutTemplate template) async {
    final confirmed = await ApplyTemplateDialog.show(context: context, templateName: template.name);

    if (confirmed != true) return;

    try {
      final exercises = await template_service.WorkoutTemplateEditService.applyTemplate(template);

      setState(() {
        _exercises = exercises;
        if (_nameController.text.isEmpty) {
          _nameController.text = template.name;
        }
      });

      AppHaptic.heavy();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template "${template.name}" applied successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error applying template: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
    AppHaptic.light();
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final validationError = WorkoutEditService.validateWorkout(_nameController.text, _exercises);

    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError), backgroundColor: AppColors.warning));
      return;
    }

    setState(() => _isSaving = true);
    AppHaptic.medium();

    try {
      final workout = Workout(
        id: widget.workoutId ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        scheduledDate: _selectedDate,
        isCompleted: false,
        isMissed: false,
        isRestDay: false,
        exercises: _exercises,
        isDirty: true,
        updatedAt: DateTime.now(),
      );

      await WorkoutEditService.saveWorkout(workout, widget.workoutId != null, ref);

      if (mounted) {
        AppHaptic.heavy();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.workoutId != null ? 'Workout updated successfully' : 'Workout created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving workout: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
          ),
        ),
      );
    }

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
            widget.workoutId != null ? 'Edit Workout' : 'Create Workout',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                WorkoutNameInputWidget(controller: _nameController),
                const SizedBox(height: 16),
                ScheduledDatePickerWidget(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) async {
                    final picked = await DatePickerUtils.showDatePickerDialog(context, date);
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                      AppHaptic.light();
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Start from Template (only for new workouts)
                if (widget.workoutId == null)
                  Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _selectTemplate,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Start from Template'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ExerciseListWidget(
                  exercises: _exercises,
                  onAddExercise: _addExercise,
                  onRemoveExercise: _removeExercise,
                ),
                const SizedBox(height: 32),
                NeonButton(
                  text: widget.workoutId != null ? 'Update Workout' : 'Create Workout',
                  icon: widget.workoutId != null ? Icons.save_rounded : Icons.add_rounded,
                  onPressed: _isSaving ? null : _saveWorkout,
                  isLoading: _isSaving,
                  gradient: AppGradients.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
