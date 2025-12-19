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
  final VoidCallback? onClose;

  const ImagePreviewWidget({
    super.key,
    required this.capturedImage,
    required this.onRetake,
    required this.onConfirm,
    this.onClose,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Retake button
              GlassContainer(
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
              // Close button
              if (onClose != null)
                GlassContainer(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(12),
                  onTap: onClose,
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
            ],
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
              const SizedBox(height: 12),
              // Skip button
              if (onClose != null)
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  onTap: onClose,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.skip_next_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Skip & Go to Workout',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

