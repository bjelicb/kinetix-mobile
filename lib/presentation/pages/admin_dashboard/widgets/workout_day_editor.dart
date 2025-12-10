import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../widgets/gradient_card.dart';
import '../plan_builder/models/plan_builder_models.dart';
import 'exercise_editor.dart';

class WorkoutDayEditor extends StatefulWidget {
  final WorkoutDayData dayData;
  final VoidCallback onDelete;
  final ValueChanged<WorkoutDayData> onUpdate;
  
  const WorkoutDayEditor({
    super.key,
    required this.dayData,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<WorkoutDayEditor> createState() => _WorkoutDayEditorState();
}

class _WorkoutDayEditorState extends State<WorkoutDayEditor> {
  late TextEditingController _nameController;
  late bool _isRestDay;
  late List<ExerciseData> _exercises;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dayData.name);
    _isRestDay = widget.dayData.isRestDay;
    _exercises = List.from(widget.dayData.exercises);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateData() {
    widget.onUpdate(WorkoutDayData(
      dayOfWeek: widget.dayData.dayOfWeek,
      name: _isRestDay ? 'Rest Day' : _nameController.text,
      isRestDay: _isRestDay,
      exercises: _exercises,
      notes: widget.dayData.notes,
    ));
  }

  void _addExercise() {
    setState(() {
      _exercises.add(ExerciseData());
    });
    _updateData();
    
    debugPrint('[PlanBuilder:Exercise] Added exercise to day ${widget.dayData.dayOfWeek}');
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
    _updateData();
    
    debugPrint('[PlanBuilder:Exercise] Removed exercise ${index + 1} from day ${widget.dayData.dayOfWeek}');
  }

  void _updateExercise(int index, ExerciseData updatedExercise) {
    setState(() {
      _exercises[index] = updatedExercise;
    });
    _updateData();
  }

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      gradient: LinearGradient(
        colors: [
          AppColors.surface1.withValues(alpha: 0.5),
          AppColors.surface1.withValues(alpha: 0.3),
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.dayData.dayOfWeek}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Day ${widget.dayData.dayOfWeek}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.error,
                onPressed: widget.onDelete,
                tooltip: 'Delete Day',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Rest Day Checkbox
          CheckboxListTile(
            value: _isRestDay,
            onChanged: (value) {
              setState(() {
                _isRestDay = value ?? false;
                if (_isRestDay) {
                  _nameController.text = 'Rest Day';
                  _exercises.clear();
                }
              });
              _updateData();
              
              debugPrint('[PlanBuilder:WorkoutDay] Day ${widget.dayData.dayOfWeek} - Rest: $_isRestDay');
            },
            title: const Text('Rest Day'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          
          if (!_isRestDay) ...[
            const SizedBox(height: 12),
            
            // Workout Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workout Name *',
                hintText: 'e.g., Push Day, Pull Day, Leg Day',
                prefixIcon: Icon(Icons.fitness_center_rounded),
              ),
              onChanged: (_) => _updateData(),
            ),
            
            const SizedBox(height: 20),
            
            // Exercises
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercises (${_exercises.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Exercise'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Exercises List
            if (_exercises.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No exercises added yet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ..._exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ExerciseEditor(
                    key: ValueKey('exercise-${widget.dayData.dayOfWeek}-$index'),
                    exerciseData: exercise,
                    exerciseNumber: index + 1,
                    onDelete: () => _removeExercise(index),
                    onUpdate: (updated) => _updateExercise(index, updated),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}

