import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_card.dart';
import '../../widgets/neon_button.dart';
import '../../../domain/entities/user.dart';
import '../../controllers/admin_controller.dart';
import 'widgets/workout_day_editor.dart';
import 'widgets/plan_preview_dialog.dart';
import 'plan_builder/models/plan_builder_models.dart';

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
  bool _isPlanEditable = true; // Can this plan be edited?

  @override
  void initState() {
    super.initState();
    
    if (widget.existingPlan != null) {
      // Load existing plan data
      _loadExistingPlan();
    } else {
      // New plan - pre-fill from modal if provided
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
      
      // Set trainer ID for new plan
      if (widget.trainerId != null) {
        if (widget.trainerId is Map) {
          final trainerMap = widget.trainerId as Map;
          _selectedTrainerId = trainerMap['userId']?.toString() ?? trainerMap['_id']?.toString();
        } else {
          _selectedTrainerId = widget.trainerId.toString();
        }
        
        // Verify trainer exists in trainers list
        if (_selectedTrainerId != null && widget.trainers.isNotEmpty) {
          final trainerExists = widget.trainers.any((t) => t.id == _selectedTrainerId);
          if (!trainerExists) {
            debugPrint('[PlanBuilder] WARNING: Trainer ID $_selectedTrainerId not found in trainers list');
            _selectedTrainerId = null;
          }
        }
      }
    }

    
    debugPrint('[PlanBuilder:Init] ${widget.existingPlan != null ? "EDIT" : "CREATE"} mode - Trainer: $_selectedTrainerId');
  }

  void _loadExistingPlan() {
    final plan = widget.existingPlan!;
    _nameController.text = plan['name'] ?? '';
    _descriptionController.text = plan['description'] ?? '';
    _selectedDifficulty = plan['difficulty'] ?? 'BEGINNER';
    
    // Debug logging for trainer ID
    debugPrint('[PlanBuilder] Raw plan trainerId: ${plan['trainerId']} (type: ${plan['trainerId'].runtimeType})');
    
    // Load weekly cost - prioritize from widget if provided, otherwise from plan
    if (widget.initialWeeklyCost != null && widget.initialWeeklyCost! > 0) {
      _weeklyCostController.text = widget.initialWeeklyCost!.toStringAsFixed(2);
    } else {
      final weeklyCost = plan['weeklyCost'];
      if (weeklyCost != null) {
        if (weeklyCost is num) {
          _weeklyCostController.text = weeklyCost.toDouble().toStringAsFixed(2);
        } else if (weeklyCost is String) {
          final costValue = double.tryParse(weeklyCost);
          if (costValue != null) {
            _weeklyCostController.text = costValue.toStringAsFixed(2);
          }
        }
      }
    }
    
    // Extract trainer ID - simplified logic
    String? extractedTrainerId;
    
    // Try widget.trainerId first (from modal)
    if (widget.trainerId != null && widget.trainerId.toString().trim().isNotEmpty) {
      if (widget.trainerId is Map) {
        final trainerMap = widget.trainerId as Map;
        extractedTrainerId = (trainerMap['userId'] ?? trainerMap['_id'] ?? trainerMap['id'])?.toString();
      } else {
        extractedTrainerId = widget.trainerId.toString().trim();
      }
    }
    
    // Fallback to plan's trainerId
    if ((extractedTrainerId == null || extractedTrainerId.isEmpty) && plan['trainerId'] != null) {
      final trainerIdValue = plan['trainerId'];
      if (trainerIdValue is Map) {
        extractedTrainerId = (trainerIdValue['userId'] ?? trainerIdValue['_id'] ?? trainerIdValue['id'])?.toString();
      } else {
        extractedTrainerId = trainerIdValue.toString().trim();
      }
    }
    
    // Debug logging for extracted trainer ID
    debugPrint('[PlanBuilder] Extracted trainerId: $extractedTrainerId');
    
    // Only set _selectedTrainerId if the trainer exists in the trainers list
    if (extractedTrainerId != null && widget.trainers.isNotEmpty) {
      final trainerExists = widget.trainers.any((t) => t.id == extractedTrainerId);
      if (trainerExists) {
        _selectedTrainerId = extractedTrainerId;
        debugPrint('[PlanBuilder] ✓ Trainer matched and set: $_selectedTrainerId');
      } else {
        debugPrint('[PlanBuilder] ✗ WARNING: Trainer ID $extractedTrainerId not found in trainers list');
        debugPrint('[PlanBuilder] Available trainer IDs: ${widget.trainers.map((t) => t.id).join(", ")}');
        _selectedTrainerId = null;
      }
    } else {
      _selectedTrainerId = extractedTrainerId;
      debugPrint('[PlanBuilder] Set trainerId without validation: $_selectedTrainerId');
    }
    
    // Check if plan can be edited (only template plans or plans without assigned clients)
    final isTemplate = plan['isTemplate'] == true;
    final assignedClientIds = plan['assignedClientIds'] as List<dynamic>? ?? [];
    _isPlanEditable = isTemplate || assignedClientIds.isEmpty;
    
    if (!_isPlanEditable) {
      debugPrint('[PlanBuilder] WARNING: Plan is assigned to ${assignedClientIds.length} clients - editing may fail');
    }
    
    debugPrint('[PlanBuilder] Loaded plan - Trainer ID: $_selectedTrainerId, Trainers list length: ${widget.trainers.length}');
    
    // Load workout days
    final workouts = plan['workouts'] as List<dynamic>? ?? [];
    _workoutDays = workouts.map((w) {
      final exercises = (w['exercises'] as List<dynamic>? ?? []).map((e) {
        return ExerciseData(
          name: e['name'] ?? '',
          sets: e['sets'] ?? 3,
          reps: e['reps']?.toString() ?? '10',
          restSeconds: e['restSeconds'] ?? 60,
          notes: e['notes'],
          videoUrl: e['videoUrl'],
        );
      }).toList();
      
      return WorkoutDayData(
        dayOfWeek: w['dayOfWeek'] ?? 1,
        name: w['name'] ?? '',
        isRestDay: w['isRestDay'] ?? false,
        exercises: exercises,
        notes: w['notes'],
      );
    }).toList();
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

  List<String> _validate() {
    final errors = <String>[];
    
    if (_nameController.text.trim().isEmpty) {
      errors.add('Plan name is required');
    }
    
    if (_selectedTrainerId == null) {
      errors.add('Trainer is required');
    }
    
    if (_workoutDays.isEmpty) {
      errors.add('At least one workout day is required');
    }
    
    for (int i = 0; i < _workoutDays.length; i++) {
      final day = _workoutDays[i];
      if (!day.isRestDay) {
        if (day.name.trim().isEmpty) {
          errors.add('Day ${i + 1}: Workout name is required');
        }
        
        if (day.exercises.isEmpty) {
          errors.add('Day ${i + 1}: At least one exercise is required');
        }
        
        for (int j = 0; j < day.exercises.length; j++) {
          final exercise = day.exercises[j];
          if (exercise.name.trim().isEmpty) {
            errors.add('Day ${i + 1}, Exercise ${j + 1}: Exercise name is required');
          }
        }
      }
    }
    
    return errors;
  }

  void _showPreview() {
    showDialog(
      context: context,
      builder: (_) => PlanPreviewDialog(
        planName: _nameController.text,
        difficulty: _selectedDifficulty,
        description: _descriptionController.text,
        workoutDays: _workoutDays,
      ),
    );
  }

  Future<void> _savePlan() async {
    final errors = _validate();
    
    if (errors.isNotEmpty) {
      debugPrint('[PlanBuilder:Validation] Errors: $errors');
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Validation Errors'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $e'),
            )).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      debugPrint('[PlanBuilder:Save] Saving plan with ${_workoutDays.length} workout days');
      
      // Build workouts array
      final workouts = _workoutDays.map((day) {
        return {
          'dayOfWeek': day.dayOfWeek,
          'isRestDay': day.isRestDay,
          'name': day.name,
          'exercises': day.exercises.map((ex) {
            return {
              'name': ex.name,
              'sets': ex.sets,
              'reps': ex.reps,
              'restSeconds': ex.restSeconds,
              'notes': ex.notes,
            };
          }).toList(),
        };
      }).toList();
      
      final planData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'difficulty': _selectedDifficulty,
        'workouts': workouts,
        'isTemplate': false,
      };
      
      // Add trainer ID - prioritize selected trainer, fallback to widget trainerId
      if (_selectedTrainerId != null) {
        planData['trainerId'] = _selectedTrainerId;
      } else if (widget.trainerId != null) {
        if (widget.trainerId is Map) {
          final trainerMap = widget.trainerId as Map;
          planData['trainerId'] = trainerMap['userId']?.toString() ?? trainerMap['_id']?.toString();
        } else {
          planData['trainerId'] = widget.trainerId.toString();
        }
      }
      
      // Add weekly cost if provided
      if (_weeklyCostController.text.trim().isNotEmpty) {
        final costValue = double.tryParse(_weeklyCostController.text.trim());
        if (costValue != null && costValue > 0) {
          planData['weeklyCost'] = costValue;
        }
      } else if (widget.existingPlan != null) {
        // Copy from existing plan if not set in form
        final existingCost = widget.existingPlan!['weeklyCost'];
        if (existingCost != null) {
          if (existingCost is num) {
            planData['weeklyCost'] = existingCost.toDouble();
          }
        }
      }
      
      // Save plan via API
      if (widget.existingPlan != null) {
        // Check if plan can be edited
        if (!_isPlanEditable) {
          // Plan is assigned to clients - show warning with options
          if (!mounted) return;
          
          final dialogResult = await showDialog<String>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: Row(
                children: [
                  Icon(Icons.warning_rounded, color: AppColors.warning, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Plan is Assigned to Clients')),
                ],
              ),
              content: Text(
                'This plan is assigned to ${(widget.existingPlan!['assignedClientIds'] as List?)?.length ?? 0} client(s).\n\n'
                '⚠️ Editing this plan will affect all assigned clients.\n\n'
                'Choose an option:',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, 'cancel'),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, 'new'),
                  child: const Text('Create New Plan'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, 'update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  child: const Text('Update Anyway'),
                ),
              ],
            ),
          );
          
          if (dialogResult == 'cancel') {
            return; // User cancelled
          } else if (dialogResult == 'new') {
            // Create new plan instead of updating - copy all data with modified name
            try {
              // Create copy of planData with modified name
              final newPlanData = Map<String, dynamic>.from(planData);
              
              // Add suffix to plan name to differentiate it
              final originalName = _nameController.text.trim();
              String newName = originalName;
              
              // Check if name already has a suffix, if not add one
              if (!originalName.toLowerCase().contains('(copy)') && 
                  !originalName.toLowerCase().contains('(new)') &&
                  !originalName.toLowerCase().contains('[copy]')) {
                newName = '$originalName (Copy)';
              } else {
                // If it already has a suffix, add timestamp or counter
                final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(10);
                newName = '$originalName $timestamp';
              }
              
              newPlanData['name'] = newName;
              
              // Ensure trainer and cost are copied
              if (_selectedTrainerId != null) {
                newPlanData['trainerId'] = _selectedTrainerId;
              } else if (widget.trainerId != null) {
                newPlanData['trainerId'] = widget.trainerId;
              }
              
              // Ensure weekly cost is copied
              if (_weeklyCostController.text.trim().isNotEmpty) {
                final costValue = double.tryParse(_weeklyCostController.text.trim());
                if (costValue != null && costValue > 0) {
                  newPlanData['weeklyCost'] = costValue;
                }
              } else if (widget.existingPlan != null) {
                // Copy from existing plan if not set in form
                final existingCost = widget.existingPlan!['weeklyCost'];
                if (existingCost != null) {
                  if (existingCost is num) {
                    newPlanData['weeklyCost'] = existingCost.toDouble();
                  }
                }
              }
              
              debugPrint('[PlanBuilder:Save] Creating new plan with name: $newName, trainer: ${newPlanData['trainerId']}, cost: ${newPlanData['weeklyCost']}');
              
              await ref.read(adminControllerProvider.notifier).createPlan(newPlanData);
              debugPrint('[PlanBuilder:Save] New plan created successfully (instead of updating)');
              if (!mounted) return;
              
              // Navigate back - parent will handle success message
              Navigator.pop(context, true);
              return;
            } catch (e) {
              if (!mounted) return;
              
              // Check for auth errors
              final errorStr = e.toString().toLowerCase();
              final isAuthError = errorStr.contains('401') || errorStr.contains('unauthorized');
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isAuthError 
                    ? 'Session expired. Please log in again.' 
                    : 'Error creating plan: ${e.toString().replaceAll('Exception: ', '')}'),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: isAuthError ? 4 : 3),
                ),
              );
              
              if (isAuthError) {
                Navigator.pop(context, false);
              }
              return;
            }
          } else if (dialogResult == 'update') {
            // User wants to update anyway - proceed to update (will likely fail but try)
            // Fall through to update attempt
          }
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
          
          // If update fails, check if it's due to assignment/template issue
          // Backend returns 400 when plan is not template and has assigned clients
          final errorStr = e.toString().toLowerCase();
          
          // Check if it's an assignment/template error (400 but not 401)
          final isAssignmentError = (errorStr.contains('400') && !errorStr.contains('401')) ||
                                    errorStr.contains('assigned') ||
                                    errorStr.contains('template') ||
                                    errorStr.contains('cannot update') ||
                                    errorStr.contains('not a template');
          
          if (isAssignmentError && !_isPlanEditable) {
            // Plan is assigned and update failed - show dialog with options
            final dialogResult = await showDialog<String>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Update Failed')),
                  ],
                ),
                content: const Text(
                  'This plan cannot be updated because it is assigned to clients and is not a template.\n\n'
                  'Only template plans can be updated when they have assigned clients.\n\n'
                  'Choose an option:',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, 'cancel'),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, 'new'),
                    child: const Text('Create New Plan'),
                  ),
                ],
              ),
            );
            
            if (dialogResult == 'new') {
              try {
                // Create copy of planData with modified name
                final newPlanData = Map<String, dynamic>.from(planData);
                
                // Add suffix to plan name to differentiate it
                final originalName = _nameController.text.trim();
                String newName = originalName;
                
                // Check if name already has a suffix, if not add one
                if (!originalName.toLowerCase().contains('(copy)') && 
                    !originalName.toLowerCase().contains('(new)') &&
                    !originalName.toLowerCase().contains('[copy]')) {
                  newName = '$originalName (Copy)';
                } else {
                  // If it already has a suffix, add timestamp or counter
                  final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(10);
                  newName = '$originalName $timestamp';
                }
                
                newPlanData['name'] = newName;
                
                // Ensure trainer and cost are copied
                if (_selectedTrainerId != null) {
                  newPlanData['trainerId'] = _selectedTrainerId;
                } else if (widget.trainerId != null) {
                  newPlanData['trainerId'] = widget.trainerId;
                }
                
                // Ensure weekly cost is copied
                if (_weeklyCostController.text.trim().isNotEmpty) {
                  final costValue = double.tryParse(_weeklyCostController.text.trim());
                  if (costValue != null && costValue > 0) {
                    newPlanData['weeklyCost'] = costValue;
                  }
                } else if (widget.existingPlan != null) {
                  // Copy from existing plan if not set in form
                  final existingCost = widget.existingPlan!['weeklyCost'];
                  if (existingCost != null) {
                    if (existingCost is num) {
                      newPlanData['weeklyCost'] = existingCost.toDouble();
                    }
                  }
                }
                
                debugPrint('[PlanBuilder:Save] Creating new plan (after update failure) with name: $newName, trainer: ${newPlanData['trainerId']}, cost: ${newPlanData['weeklyCost']}');
                
                await ref.read(adminControllerProvider.notifier).createPlan(newPlanData);
                debugPrint('[PlanBuilder:Save] New plan created successfully (after update failure)');
                if (!mounted) return;
                
                // Navigate back - parent will handle success message
                Navigator.pop(context, true);
                return;
              } catch (createError) {
                if (!mounted) return;
                
                // Check for auth errors
                final createErrorStr = createError.toString().toLowerCase();
                final isAuthError = createErrorStr.contains('401') || createErrorStr.contains('unauthorized');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAuthError 
                      ? 'Session expired. Please log in again.' 
                      : 'Error creating plan: ${createError.toString().replaceAll('Exception: ', '')}'),
                    backgroundColor: AppColors.error,
                    duration: Duration(seconds: isAuthError ? 4 : 3),
                  ),
                );
                
                if (isAuthError) {
                  Navigator.pop(context, false);
                }
                return;
              }
            } else {
              return; // User cancelled
            }
          }
          
          // For other errors, rethrow to be handled by outer catch block
          rethrow;
        }
      } else {
        await ref.read(adminControllerProvider.notifier).createPlan(planData);
        debugPrint('[PlanBuilder:Save] Plan created successfully');
      }
      
      if (!mounted) return;
      
      // Show success message before navigating
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingPlan != null ? 'Plan updated successfully' : 'Plan created successfully'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Small delay to show snackbar, then navigate
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh list
      }
      
    } catch (e) {
      debugPrint('[PlanBuilder:Save] ERROR: $e');
      
      if (!mounted) return;
      
      // Check if it's an authentication error (401)
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
          ),
        );
        // Navigate back on auth error
        Navigator.pop(context, false);
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving plan: ${e.toString().replaceAll('Exception: ', '').split('\n').first}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
              _buildBasicInfoSection(),
              
              const SizedBox(height: 24),
              
              // Workout Days Section
              _buildWorkoutDaysSection(),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return GradientCard(
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
          
          // Plan Name
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Plan Name *',
              hintText: 'e.g., Beginner Full Body Program',
              prefixIcon: Icon(Icons.fitness_center_rounded),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Brief description of the plan',
              prefixIcon: Icon(Icons.description_rounded),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 16),
          
          // Difficulty
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _selectedDifficulty,
            decoration: const InputDecoration(
              labelText: 'Difficulty *',
              prefixIcon: Icon(Icons.trending_up_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
              DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
              DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
            ],
            onChanged: (value) {
              setState(() => _selectedDifficulty = value ?? 'BEGINNER');
            },
          ),
          
          const SizedBox(height: 16),
          
          // Trainer
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _selectedTrainerId != null && widget.trainers.any((t) => t.id == _selectedTrainerId)
                ? _selectedTrainerId
                : null,
            decoration: const InputDecoration(
              labelText: 'Trainer *',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            items: widget.trainers.map((trainer) {
              return DropdownMenuItem(
                value: trainer.id,
                child: Text(trainer.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedTrainerId = value);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Weekly Cost
          TextField(
            controller: _weeklyCostController,
            decoration: const InputDecoration(
              labelText: 'Weekly Cost',
              hintText: 'e.g., 9.99',
              prefixIcon: Icon(Icons.attach_money_rounded),
              helperText: 'Optional - Cost per week for this plan',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutDaysSection() {
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Workout Days (${_workoutDays.length}/7)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              NeonButton(
                text: 'Add Day',
                icon: Icons.add_rounded,
                onPressed: _workoutDays.length < 7 ? _addWorkoutDay : null,
                isSmall: true,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_workoutDays.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No workout days added yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click "Add Day" to start building your plan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._workoutDays.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: WorkoutDayEditor(
                  key: ValueKey('day-${day.dayOfWeek}'),
                  dayData: day,
                  onDelete: () => _removeWorkoutDay(index),
                  onUpdate: (updatedDay) => _updateWorkoutDay(index, updatedDay),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: NeonButton(
            text: 'Cancel',
            icon: Icons.close_rounded,
            onPressed: () => Navigator.pop(context),
            gradient: LinearGradient(
              colors: [
                AppColors.textSecondary.withValues(alpha: 0.3),
                AppColors.textSecondary.withValues(alpha: 0.2),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: NeonButton(
            text: widget.existingPlan != null ? 'Update Plan' : 'Create Plan',
            icon: Icons.save_rounded,
            onPressed: _isSaving ? null : _savePlan,
            gradient: AppGradients.success,
          ),
        ),
      ],
    );
  }
}

