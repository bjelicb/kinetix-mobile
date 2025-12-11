import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../../domain/entities/workout.dart';
import '../neon_button.dart';

class FinishWorkoutButton extends StatelessWidget {
  final Workout workout;
  final ConfettiController confettiController;
  final VoidCallback onFinish;

  const FinishWorkoutButton({
    super.key,
    required this.workout,
    required this.confettiController,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.background,
              ],
            ),
          ),
          child: NeonButton(
            text: 'Finish Workout',
            icon: Icons.check_circle_rounded,
            onPressed: onFinish,
            gradient: AppGradients.success,
          ),
        ),
        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: confettiController,
            blastDirection: 3.14 / 2, // Down
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            shouldLoop: false,
          ),
        ),
      ],
    );
  }
}

