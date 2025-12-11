import 'dart:io' as io;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/neon_button.dart';

/// Photo preview widget for check-in
class ImagePreviewWidget extends StatelessWidget {
  final XFile capturedImage;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;

  const ImagePreviewWidget({
    super.key,
    required this.capturedImage,
    required this.onRetake,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Photo Preview
        Positioned.fill(
          child: kIsWeb
              ? Image.network(capturedImage.path, fit: BoxFit.cover)
              : Image.file(
                  io.File(capturedImage.path),
                  fit: BoxFit.cover,
                ),
        ),

        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.background.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),

        // Top Controls
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: GlassContainer(
            padding: const EdgeInsets.all(12),
            onTap: onRetake,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Retake',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Controls
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            children: [
              NeonButton(
                text: 'Confirm Check-In',
                icon: Icons.check_circle_rounded,
                onPressed: onConfirm,
                gradient: AppGradients.success,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

