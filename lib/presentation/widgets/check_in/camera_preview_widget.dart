import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradients.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/shimmer_loader.dart';
import 'guide_lines_painter.dart';

/// Camera preview widget for check-in
class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final List<CameraDescription>? cameras;
  final bool isFrontCamera;
  final bool flashOn;
  final bool isInitialized;
  final VoidCallback onCapture;
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleFlash;
  final VoidCallback onClose;

  const CameraPreviewWidget({
    super.key,
    this.controller,
    this.cameras,
    required this.isFrontCamera,
    required this.flashOn,
    required this.isInitialized,
    required this.onCapture,
    required this.onSwitchCamera,
    required this.onToggleFlash,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!isInitialized || controller == null) {
      return const Center(
        child: ShimmerLoader(width: 200, height: 200, borderRadius: 16),
      );
    }

    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: CameraPreview(controller!),
        ),

        // Overlay with guide lines
        Positioned.fill(
          child: CustomPaint(
            painter: GuideLinesPainter(),
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
              // Close Button
              GlassContainer(
                borderRadius: 12,
                padding: const EdgeInsets.all(12),
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),

              // Flash Toggle
              GlassContainer(
                borderRadius: 12,
                padding: const EdgeInsets.all(12),
                onTap: onToggleFlash,
                child: Icon(
                  flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: flashOn ? AppColors.accentYellow : AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),

        // Bottom Controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Instructions
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                margin: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Position your face in the frame',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // Capture Button and Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Switch Camera
                  if (cameras != null && cameras!.length > 1)
                    GlassContainer(
                      borderRadius: 30,
                      padding: const EdgeInsets.all(16),
                      onTap: onSwitchCamera,
                      child: const Icon(
                        Icons.flip_camera_ios_rounded,
                        color: AppColors.textPrimary,
                        size: 28,
                      ),
                    )
                  else
                    const SizedBox(width: 60),

                  // Capture Button
                  GestureDetector(
                    onTap: onCapture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.primary,
                        border: Border.all(
                          color: AppColors.textPrimary,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.circle,
                        color: AppColors.textPrimary,
                        size: 60,
                      ),
                    ),
                  ),

                  // Placeholder for symmetry
                  const SizedBox(width: 60),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

