import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../core/constants/app_assets.dart';
import '../controllers/theme_controller.dart';

class TrainerAvatar extends StatelessWidget {
  final String image;
  final TrainerTheme theme;
  final double size;

  const TrainerAvatar({
    super.key,
    required this.image,
    required this.theme,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Decorative border lines behind the avatar
        Container(
          width: size + 4,
          height: size + 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getAccentColor().withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _getAccentColor().withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        // Avatar image without border or radius
        Image.asset(
          image,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Gradient _getGradient() {
    switch (theme) {
      case TrainerTheme.milan:
        return TrainerThemes.milanGradient;
      case TrainerTheme.aca:
        return TrainerThemes.acaGradient;
      case TrainerTheme.neutral:
        return AppGradients.primary;
    }
  }

  Color _getAccentColor() {
    switch (theme) {
      case TrainerTheme.milan:
        return TrainerThemes.milanPrimary;
      case TrainerTheme.aca:
        return TrainerThemes.acaPrimary;
      case TrainerTheme.neutral:
        return AppColors.primary;
    }
  }
}
