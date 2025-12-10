import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/user.dart';

/// Basic information section for Plan Builder
/// Contains: Name, Description, Difficulty, Trainer, Weekly Cost
class BasicInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController weeklyCostController;
  final String? selectedDifficulty;
  final String? selectedTrainerId;
  final List<User> trainers;
  final Function(String?) onDifficultyChanged;
  final Function(String?) onTrainerChanged;

  const BasicInfoSection({
    super.key,
    required this.nameController,
    required this.descriptionController,
    required this.weeklyCostController,
    required this.selectedDifficulty,
    required this.selectedTrainerId,
    required this.trainers,
    required this.onDifficultyChanged,
    required this.onTrainerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plan Name
        TextField(
          controller: nameController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Plan Name',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Description
        TextField(
          controller: descriptionController,
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Description',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Difficulty Dropdown
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: selectedDifficulty,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Difficulty',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          items: ['BEGINNER', 'INTERMEDIATE', 'ADVANCED']
              .map((level) => DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  ))
              .toList(),
          onChanged: onDifficultyChanged,
        ),
        const SizedBox(height: 16),

        // Trainer Dropdown
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: selectedTrainerId,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Assign Trainer (Optional)',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('No Trainer'),
            ),
            ...trainers.map((trainer) => DropdownMenuItem<String>(
                  value: trainer.id,
                  child: Text(trainer.name),
                )),
          ],
          onChanged: onTrainerChanged,
        ),
        const SizedBox(height: 16),

        // Weekly Cost
        TextField(
          controller: weeklyCostController,
          style: const TextStyle(color: AppColors.textPrimary),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Weekly Cost (€)',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            prefixText: '€ ',
            prefixStyle: const TextStyle(color: AppColors.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

