import 'package:flutter/material.dart';
import '../plan_builder/models/plan_builder_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/gradient_card.dart';
import 'exercise_counter.dart';
import 'exercise_suggestions.dart';

class ExerciseEditor extends StatefulWidget {
  final ExerciseData exerciseData;
  final int exerciseNumber;
  final VoidCallback onDelete;
  final ValueChanged<ExerciseData> onUpdate;
  
  const ExerciseEditor({
    super.key,
    required this.exerciseData,
    required this.exerciseNumber,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<ExerciseEditor> {
  late TextEditingController _nameController;
  late TextEditingController _repsController;
  late TextEditingController _notesController;
  late int _sets;
  late int _restSeconds;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exerciseData.name);
    _repsController = TextEditingController(text: widget.exerciseData.reps);
    _notesController = TextEditingController(text: widget.exerciseData.notes ?? '');
    _sets = widget.exerciseData.sets;
    _restSeconds = widget.exerciseData.restSeconds;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateData() {
    final updatedData = ExerciseData(
      name: _nameController.text,
      sets: _sets,
      reps: _repsController.text,
      restSeconds: _restSeconds,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      videoUrl: widget.exerciseData.videoUrl,
    );
    
    // Only update if data actually changed
    if (updatedData.name != widget.exerciseData.name ||
        updatedData.sets != widget.exerciseData.sets ||
        updatedData.reps != widget.exerciseData.reps ||
        updatedData.restSeconds != widget.exerciseData.restSeconds ||
        updatedData.notes != widget.exerciseData.notes) {
      widget.onUpdate(updatedData);
      debugPrint('[PlanBuilder:Exercise] Updated ${_nameController.text} - Sets: $_sets, Reps: ${_repsController.text}, Rest: ${_restSeconds}s');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.all(12),
      margin: EdgeInsets.zero,
      gradient: LinearGradient(
        colors: [
          AppColors.surface.withValues(alpha: 0.5),
          AppColors.surface.withValues(alpha: 0.3),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.exerciseNumber}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Exercise ${widget.exerciseNumber}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textSecondary,
                onPressed: widget.onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Exercise Name with Suggestions
          ExerciseSuggestionsDropdown(
            key: ValueKey('exercise-name-${widget.exerciseData.name}-${widget.exerciseNumber}'),
            initialValue: _nameController.text,
            onChanged: (value) {
              // Only update when user selects or submits (not while typing)
              _nameController.text = value;
              _updateData();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Sets, Reps, Rest Row - Responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              // Use column for small screens (< 600px width)
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    // Sets Counter
                    SizedBox(
                      width: double.infinity,
                      child: ExerciseCounter(
                        label: 'Sets',
                        value: _sets,
                        min: 1,
                        max: 10,
                        onChanged: (value) {
                          setState(() => _sets = value);
                          _updateData();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Reps Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reps',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _repsController,
                          decoration: const InputDecoration(
                            hintText: '10-12 or 10',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: (value) {
                            if (_repsController.text != value) {
                              _updateData();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Rest Counter
                    SizedBox(
                      width: double.infinity,
                      child: ExerciseCounter(
                        label: 'Rest (sec)',
                        value: _restSeconds,
                        min: 0,
                        max: 300,
                        step: 15,
                        onChanged: (value) {
                          setState(() => _restSeconds = value);
                          _updateData();
                        },
                      ),
                    ),
                  ],
                );
              }
              
              // Use row for larger screens (>= 600px width)
              return Row(
                children: [
                  // Sets Counter
                  Expanded(
                    child: ExerciseCounter(
                      label: 'Sets',
                      value: _sets,
                      min: 1,
                      max: 10,
                      onChanged: (value) {
                        setState(() => _sets = value);
                        _updateData();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Reps Input
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reps',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _repsController,
                          decoration: const InputDecoration(
                            hintText: '10-12 or 10',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: (value) {
                            if (_repsController.text != value) {
                              _updateData();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Rest Counter
                  Expanded(
                    child: ExerciseCounter(
                      label: 'Rest (sec)',
                      value: _restSeconds,
                      min: 0,
                      max: 300,
                      step: 15,
                      onChanged: (value) {
                        setState(() => _restSeconds = value);
                        _updateData();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g., Focus on form, RPE 7',
              prefixIcon: Icon(Icons.note_rounded, size: 20),
            ),
            maxLines: 2,
            onChanged: (value) {
              if (_notesController.text != value) {
                _updateData();
              }
            },
          ),
          
          const SizedBox(height: 12),
          
          // Video URL (Coming Soon)
          TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Video URL',
              prefixIcon: const Icon(Icons.video_library_rounded, size: 20),
              suffixIcon: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              helperText: 'Video integration will be available in future update',
              helperStyle: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

