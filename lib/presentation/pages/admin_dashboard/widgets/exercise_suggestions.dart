import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Real exercise suggestions organized by category
const List<String> exerciseSuggestions = [
  // Upper Body - Push
  'Bench Press',
  'Incline Bench Press',
  'Decline Bench Press',
  'Dumbbell Press',
  'Push-ups',
  'Dumbbell Flyes',
  'Cable Flyes',
  'Shoulder Press',
  'Overhead Press',
  'Lateral Raises',
  'Front Raises',
  'Tricep Dips',
  'Overhead Tricep Extension',
  'Tricep Pushdown',
  'Skull Crushers',
  
  // Upper Body - Pull
  'Pull-ups',
  'Chin-ups',
  'Bent Over Rows',
  'Barbell Rows',
  'Dumbbell Rows',
  'Lat Pulldown',
  'Seated Cable Row',
  'T-Bar Row',
  'Face Pulls',
  'Bicep Curls',
  'Hammer Curls',
  'Preacher Curls',
  'Cable Curls',
  'Concentration Curls',
  
  // Lower Body
  'Squats',
  'Barbell Squats',
  'Front Squats',
  'Goblet Squats',
  'Leg Press',
  'Romanian Deadlifts',
  'Conventional Deadlifts',
  'Sumo Deadlifts',
  'Leg Curls',
  'Leg Extensions',
  'Calf Raises',
  'Seated Calf Raises',
  'Lunges',
  'Walking Lunges',
  'Bulgarian Split Squats',
  'Step-ups',
  'Hip Thrusts',
  'Glute Bridges',
  
  // Core
  'Plank',
  'Side Plank',
  'Crunches',
  'Bicycle Crunches',
  'Russian Twists',
  'Mountain Climbers',
  'Dead Bug',
  'Bird Dog',
  'Leg Raises',
  'Hanging Leg Raises',
  'Ab Wheel Rollout',
  'Cable Crunches',
  
  // Cardio
  'Treadmill Running',
  'Rowing Machine',
  'Stationary Bike',
  'Elliptical',
  'HIIT Circuit',
  'Sprint Intervals',
  'Jump Rope',
  'Burpees',
  'Box Jumps',
  'Battle Ropes',
];

class ExerciseSuggestionsDropdown extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  
  const ExerciseSuggestionsDropdown({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<ExerciseSuggestionsDropdown> createState() => _ExerciseSuggestionsDropdownState();
}

class _ExerciseSuggestionsDropdownState extends State<ExerciseSuggestionsDropdown> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.initialValue ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return exerciseSuggestions.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        // Only call onChanged when user selects a suggestion
        widget.onChanged(selection);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Exercise Name *',
            hintText: 'Type to search or enter custom name',
            prefixIcon: Icon(Icons.fitness_center_rounded, size: 20),
          ),
          // Do NOT call onChanged while typing - this causes focus loss
          // onChanged will be called only on selection or submit
          onSubmitted: (value) {
            widget.onChanged(value);
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            color: AppColors.surface1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.fitness_center_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        option,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
