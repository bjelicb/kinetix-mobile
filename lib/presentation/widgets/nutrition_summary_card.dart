import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import 'gradient_card.dart';

class NutritionSummaryCard extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  
  const NutritionSummaryCard({
    super.key,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Mock daily targets (in production, these would come from user settings)
    const double targetCalories = 2500;
    const double targetProtein = 150; // grams
    const double targetCarbs = 300; // grams
    const double targetFats = 80; // grams

    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                'Nutrition Summary',
                style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Icon(
                Icons.restaurant_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Calories
          _buildMacroRow(
            context,
            'Calories',
            calories,
            targetCalories,
            'kcal',
            AppGradients.primary,
          ),
          const SizedBox(height: 16),
          
          // Protein
          _buildMacroRow(
            context,
            'Protein',
            protein,
            targetProtein,
            'g',
            AppGradients.secondary,
          ),
          const SizedBox(height: 16),
          
          // Carbs
          _buildMacroRow(
            context,
            'Carbs',
            carbs,
            targetCarbs,
            'g',
            AppGradients.purplePink,
          ),
          const SizedBox(height: 16),
          
          // Fats
          _buildMacroRow(
            context,
            'Fats',
            fats,
            targetFats,
            'g',
            AppGradients.orangePink,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(
    BuildContext context,
    String label,
    double current,
    double target,
    String unit,
    Gradient gradient,
  ) {
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isComplete = percentage >= 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            ),
            Flexible(
              child: Text(
              '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} $unit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isComplete
                      ? [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

