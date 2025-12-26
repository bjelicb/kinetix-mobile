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
  final VoidCallback? onGiveUp; // NOVO - optional za Give up dugme

  const FinishWorkoutButton({
    super.key,
    required this.workout,
    required this.confettiController,
    required this.onFinish,
    this.onGiveUp, // NOVO
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
          child: onGiveUp != null
              ? Row( // NOVO: Ako postoji onGiveUp, prikazati oba dugmeta
                  children: [
                    Expanded(
                      child: NeonButton(
                        text: 'Give Up',
                        icon: Icons.close_rounded,
                        onPressed: onGiveUp,
                        gradient: AppGradients.error,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: NeonButton(
                        text: 'Finish Workout',
                        icon: Icons.check_circle_rounded,
                        onPressed: onFinish,
                        gradient: AppGradients.success,
                      ),
                    ),
                  ],
                )
              : NeonButton( // Postojeći kod ako nema onGiveUp
                  text: 'Finish Workout',
                  icon: Icons.check_circle_rounded,
                  onPressed: onFinish,
                  gradient: AppGradients.success,
                ),
        ),
        // Confetti overlay (samo za Finish, ne za Give Up)
        if (onGiveUp == null)
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

