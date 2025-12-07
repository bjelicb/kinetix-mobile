import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../controllers/theme_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CyberLoader extends ConsumerWidget {
  final double size;
  final Color? color;

  const CyberLoader({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final gradient = _getThemeGradient(theme);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CyberLoaderPainter(
          gradient: gradient,
          color: color,
        ),
      ),
    );
  }

  Gradient _getThemeGradient(TrainerTheme theme) {
    switch (theme) {
      case TrainerTheme.milan:
        return TrainerThemes.milanGradient;
      case TrainerTheme.aca:
        return TrainerThemes.acaGradient;
      case TrainerTheme.neutral:
        return AppGradients.primary;
    }
  }
}

class _CyberLoaderPainter extends CustomPainter {
  final Gradient gradient;
  final Color? color;
  final double _animationValue = 0.0;

  _CyberLoaderPainter({
    required this.gradient,
    this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Create paint with gradient
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Draw animated rings
    for (int i = 0; i < 3; i++) {
      final ringRadius = radius * (0.4 + i * 0.2);
      final opacity = (1.0 - i * 0.3).clamp(0.3, 1.0);
      
      if (color != null) {
        paint.color = color!.withValues(alpha: opacity);
      } else {
        // Use gradient shader
        final shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: ringRadius),
        );
        paint.shader = shader;
        paint.color = Colors.white.withValues(alpha: opacity);
      }
      
      // Draw partial ring with rotation
      final startAngle = (math.pi * 2 * _animationValue) + (i * math.pi / 3);
      final sweepAngle = math.pi * 1.5;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CyberLoaderPainter oldDelegate) {
    return oldDelegate.gradient != gradient || oldDelegate.color != color;
  }
}

class AnimatedCyberLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const AnimatedCyberLoader({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  State<AnimatedCyberLoader> createState() => _AnimatedCyberLoaderState();
}

class _AnimatedCyberLoaderState extends State<AnimatedCyberLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AnimatedCyberLoaderPainter(
            animationValue: _controller.value,
            gradient: AppGradients.primary,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _AnimatedCyberLoaderPainter extends CustomPainter {
  final double animationValue;
  final Gradient gradient;
  final Color? color;

  _AnimatedCyberLoaderPainter({
    required this.animationValue,
    required this.gradient,
    this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Draw 3 animated rings
    for (int i = 0; i < 3; i++) {
      final ringRadius = radius * (0.3 + i * 0.25);
      final opacity = (1.0 - i * 0.35).clamp(0.2, 1.0);
      
      // Rotate each ring at different speeds
      final rotation = (animationValue * 2 * math.pi) + (i * math.pi / 2);
      final startAngle = rotation;
      final sweepAngle = math.pi * 1.2;
      
      if (color != null) {
        paint.shader = null;
        paint.color = color!.withValues(alpha: opacity);
      } else {
        paint.shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: ringRadius),
        );
        paint.color = Colors.white.withValues(alpha: opacity);
      }
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_AnimatedCyberLoaderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.gradient != gradient ||
        oldDelegate.color != color;
  }
}
