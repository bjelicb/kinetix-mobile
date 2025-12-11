import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Custom painter for face guide lines in camera preview
class GuideLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Face guide frame (centered, 60% of screen width)
    final frameSize = size.width * 0.6;
    final frameLeft = (size.width - frameSize) / 2;
    final frameTop = size.height * 0.2;
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(frameLeft, frameTop, frameSize, frameSize * 1.3),
      const Radius.circular(20),
    );

    canvas.drawRRect(frameRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

