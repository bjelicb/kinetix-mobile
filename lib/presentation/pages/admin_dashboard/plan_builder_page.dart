import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_card.dart';
import '../../../domain/entities/user.dart';
import '../../controllers/admin_controller.dart';
import 'plan_builder/models/plan_builder_models.dart';
import 'plan_builder/plan_builder_service.dart';
import 'plan_builder/widgets/basic_info_section.dart';
import 'plan_builder/widgets/workout_days_section.dart';
import 'plan_builder/widgets/plan_action_buttons_widget.dart';
import 'services/plan_preview_service.dart';
import 'widgets/plan_validation_error_dialog.dart';
import 'widgets/plan_assigned_clients_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../data/datasources/remote_data_source.dart';

class PlanBuilderPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingPlan;
  final String? trainerId;
  final List<User> trainers;
  final String? initialName;
  final String? initialDescription;
  final String? initialDifficulty;
  final double? initialWeeklyCost;
  
  const PlanBuilderPage({
    super.key,
    this.existingPlan,
    this.trainerId,
    required this.trainers,
    this.initialName,
    this.initialDescription,
    this.initialDifficulty,
    this.initialWeeklyCost,
  });

  @override
  ConsumerState<PlanBuilderPage> createState() => _PlanBuilderPageState();
}

class _PlanBuilderPageState extends ConsumerState<PlanBuilderPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weeklyCostController = TextEditingController();
  String _selectedDifficulty = 'BEGINNER';
  String? _selectedTrainerId;
  List<WorkoutDayData> _workoutDays = [];
  bool _isSaving = false;
  bool _isPlanEditable = true;
  
  late final PlanBuilderService _planBuilderService;

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    final storage = FlutterSecureStorage();
    _planBuilderService = PlanBuilderService(RemoteDataSource(dio, storage));
    
    if (widget.existingPlan != null) {
      _loadExistingPlan();
    } else {
      _initializeNewPlan();
    }
    
    debugPrint('[PlanBuilder:Init] ${widget.existingPlan != null ? "EDIT" : "CREATE"} mode - Trainer: $_selectedTrainerId');
  }

  void _initializeNewPlan() {
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    if (widget.initialDifficulty != null) {
      _selectedDifficulty = widget.initialDifficulty!;
    }
    if (widget.initialWeeklyCost != null && widget.initialWeeklyCost! > 0) {
      _weeklyCostController.text = widget.initialWeeklyCost!.toStringAsFixed(2);
    }
    
    _setTrainerIdFromWidget();
  }

  void _setTrainerIdFromWidget() {
    if (widget.trainerId == null) return;
    
    String? extractedId;
    if (widget.trainerId is Map) {
      final trainerMap = widget.trainerId as Map;
      extractedId = trainerMap['userId']?.toString() ?? trainerMap['_id']?.toString();
    } else {
      extractedId = widget.trainerId.toString();
    }
    
    if (extractedId != null && widget.trainers.isNotEmpty) {
      final trainerExists = widget.trainers.any((t) => t.id == extractedId);
      if (trainerExists) {
        _selectedTrainerId = extractedId;
      } else {
        debugPrint('[PlanBuilder] WARNING: Trainer ID $extractedId not found in trainers list');
      }
    }
  }

  void _loadExistingPlan() {
    final loadedData = _planBuilderService.loadExistingPlan(
      plan: widget.existingPlan!,
      widgetTrainerId: widget.trainerId,
      initialWeeklyCost: widget.initialWeeklyCost,
      trainers: widget.trainers,
    );
    
    _nameController.text = loadedData.name;
    _descriptionController.text = loadedData.description;
    _selectedDifficulty = loadedData.difficulty;
    _selectedTrainerId = loadedData.selectedTrainerId;
    _workoutDays = loadedData.workoutDays;
    _isPlanEditable = loadedData.isPlanEditable;
    
    if (loadedData.weeklyCost != null) {
      _weeklyCostController.text = loadedData.weeklyCost!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _weeklyCostController.dispose();
    super.dispose();
  }

  void _addWorkoutDay() {
    if (_workoutDays.length >= 7) return;
    
    setState(() {
      _workoutDays.add(WorkoutDayData(
        dayOfWeek: _workoutDays.length + 1,
      ));
    });
    
    debugPrint('[PlanBuilder:WorkoutDay] Added day ${_workoutDays.length}');
  }

  void _removeWorkoutDay(int index) {
    setState(() {
      _workoutDays.removeAt(index);
      // Renumber days
      for (int i = 0; i < _workoutDays.length; i++) {
        _workoutDays[i] = WorkoutDayData(
          dayOfWeek: i + 1,
          name: _workoutDays[i].name,
          isRestDay: _workoutDays[i].isRestDay,
          exercises: _workoutDays[i].exercises,
          notes: _workoutDays[i].notes,
        );
      }
    });
    
    debugPrint('[PlanBuilder:WorkoutDay] Removed day ${index + 1}');
  }

  void _updateWorkoutDay(int index, WorkoutDayData updatedDay) {
    setState(() {
      _workoutDays[index] = updatedDay;
    });
  }

  void _showPreview() {
    PlanPreviewService.showPlanPreview(
      context: context,
      planName: _nameController.text,
      difficulty: _selectedDifficulty,
      description: _descriptionController.text,
      workoutDays: _workoutDays,
    );
  }

  Future<void> _savePlan() async {
    // Validate
    final errors = _planBuilderService.validatePlan(
      name: _nameController.text,
      trainerId: _selectedTrainerId,
      workoutDays: _workoutDays,
    );
    
    if (errors.isNotEmpty) {
      await PlanValidationErrorDialog.show(context, errors);
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      // Prepare plan data
      final planData = _planBuilderService.preparePlanDataForSave(
        name: _nameController.text,
        description: _descriptionController.text,
        difficulty: _selectedDifficulty,
        workoutDays: _workoutDays,
        selectedTrainerId: _selectedTrainerId,
        widgetTrainerId: widget.trainerId,
        weeklyCostText: _weeklyCostController.text,
        existingPlan: widget.existingPlan,
      );
      
      // Handle save logic
      if (widget.existingPlan != null) {
        await _handleUpdatePlan(planData);
      } else {
        await _handleCreatePlan(planData);
      }
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingPlan != null ? 'Plan updated successfully' : 'Plan created successfully'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      _handleSaveError(e);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleUpdatePlan(Map<String, dynamic> planData) async {
    // Check if plan can be edited
    if (!_isPlanEditable) {
      final assignedClientsCount = _planBuilderService.getAssignedClientsCount(widget.existingPlan);
      final dialogResult = await PlanAssignedClientsDialog.show(
        context,
        assignedClientsCount,
      );
      
      if (dialogResult == 'cancel') {
        return;
      } else if (dialogResult == 'new') {
        await _createDuplicatePlan(planData);
        return;
      }
      // Continue with update if 'update'
    }
    
    // Try to update plan
    try {
      await ref.read(adminControllerProvider.notifier).updatePlan(
        widget.existingPlan!['_id'],
        planData,
      );
      debugPrint('[PlanBuilder:Save] Plan updated successfully');
    } catch (e) {
      if (!mounted) return;
      
      // Check if it's an assignment/template error
      if (_planBuilderService.isAssignmentError(e) && !_isPlanEditable) {
        final dialogResult = await PlanAssignedClientsDialog.show(
          context,
          _planBuilderService.getAssignedClientsCount(widget.existingPlan),
          isUpdateFailure: true,
        );
        
        if (dialogResult == 'new') {
          await _createDuplicatePlan(planData);
          return;
        } else {
          return; // User cancelled
        }
      }
      
      // For other errors, rethrow
      rethrow;
    }
  }

  Future<void> _handleCreatePlan(Map<String, dynamic> planData) async {
    await ref.read(adminControllerProvider.notifier).createPlan(planData);
    debugPrint('[PlanBuilder:Save] Plan created successfully');
  }

  Future<void> _createDuplicatePlan(Map<String, dynamic> originalPlanData) async {
    try {
      final newPlanData = _planBuilderService.createDuplicatePlanData(
        originalPlanData: originalPlanData,
        originalName: _nameController.text,
        selectedTrainerId: _selectedTrainerId,
        widgetTrainerId: widget.trainerId,
        weeklyCostText: _weeklyCostController.text,
        existingPlan: widget.existingPlan,
      );
      
      debugPrint('[PlanBuilder:Save] Creating duplicate plan: ${newPlanData['name']}');
      await ref.read(adminControllerProvider.notifier).createPlan(newPlanData);
      debugPrint('[PlanBuilder:Save] Duplicate plan created successfully');
      
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _handleSaveError(e);
    }
  }

  void _handleSaveError(dynamic error) {
    final isAuthError = _planBuilderService.isAuthenticationError(error);
    
    if (isAuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pop(context, false);
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving plan: ${_planBuilderService.extractErrorMessage(error)}'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.existingPlan != null ? 'Edit Plan' : 'Create New Plan'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.preview_rounded),
              onPressed: _showPreview,
              tooltip: 'Preview Plan',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Info Section
              GradientCard(
                gradient: AppGradients.card,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    BasicInfoSection(
                      nameController: _nameController,
                      descriptionController: _descriptionController,
                      weeklyCostController: _weeklyCostController,
                      selectedDifficulty: _selectedDifficulty,
                      selectedTrainerId: _selectedTrainerId != null && widget.trainers.any((t) => t.id == _selectedTrainerId)
                          ? _selectedTrainerId
                          : null,
                      trainers: widget.trainers,
                      onDifficultyChanged: (value) {
                        setState(() => _selectedDifficulty = value ?? 'BEGINNER');
                      },
                      onTrainerChanged: (value) {
                        setState(() => _selectedTrainerId = value);
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Workout Days Section
              GradientCard(
                gradient: AppGradients.card,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout Days (${_workoutDays.length}/7)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    WorkoutDaysSection(
                      workoutDays: _workoutDays,
                      onRemoveDay: _removeWorkoutDay,
                      onAddDay: _addWorkoutDay,
                      onDayUpdated: _updateWorkoutDay,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              PlanActionButtons(
                isExistingPlan: widget.existingPlan != null,
                isSaving: _isSaving,
                onCancel: () => Navigator.pop(context),
                onSave: _savePlan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
