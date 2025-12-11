import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/gradient_background.dart';
import '../../../presentation/widgets/neon_button.dart';

class CheckInRequiredWidget extends StatelessWidget {
  const CheckInRequiredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Check-In Required'),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_rounded,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Check-In Required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You must check in with GPS and photo before starting a workout.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                NeonButton(
                  text: 'Go to Check-In',
                  icon: Icons.camera_alt_rounded,
                  onPressed: () {
                    context.go('/check-in');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

