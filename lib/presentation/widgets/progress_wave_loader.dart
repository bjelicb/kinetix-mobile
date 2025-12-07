import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import 'loader_animation_manager.dart';

class ProgressWaveLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final Gradient? gradient;
  @Deprecated('This parameter is no longer used, kept for backward compatibility')
  final bool isHorizontal;

  const ProgressWaveLoader({
    super.key,
    this.size = 60,
    this.color,
    this.gradient,
    this.isHorizontal = true, // Kept for backward compatibility, not used
  });

  @override
  State<ProgressWaveLoader> createState() => _ProgressWaveLoaderState();
}

class _ProgressWaveLoaderState extends State<ProgressWaveLoader> {
  final _animationManager = LoaderAnimationManager();
  double _animationValue = 0.0;

  void _updateAnimation(double value) {
    if (mounted) {
      setState(() {
        _animationValue = value;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Start global animation if not already running
    _animationManager.start();
    // Listen to animation updates
    _animationManager.addListener(_updateAnimation);
  }

  @override
  void dispose() {
    _animationManager.removeListener(_updateAnimation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _ProgressWaveLoaderPainter(
          animationValue: _animationValue,
          size: widget.size,
          color: widget.color,
          gradient: widget.gradient ?? AppGradients.primary,
        ),
      ),
    );
  }
}

class _ProgressWaveLoaderPainter extends CustomPainter {
  final double animationValue;
  final double size;
  final Color? color;
  final Gradient gradient;

  _ProgressWaveLoaderPainter({
    required this.animationValue,
    required this.size,
    this.color,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    _paintBouncingBall(canvas, canvasSize);
  }

  void _paintBouncingBall(Canvas canvas, Size canvasSize) {
    final ballRadius = size * 0.15; // 15% of total size
    final centerY = canvasSize.height / 2;
    final padding = ballRadius * 1.5;
    final startX = padding;
    final endX = canvasSize.width - padding;
    final trackLength = endX - startX;

    // Calculate ball position using sin for smooth bouncing
    // sin goes from -1 to 1, so we map it to 0 to 1, then to startX to endX
    final normalizedPosition = 0.5 + 0.5 * math.sin(animationValue * 2 * math.pi);
    final ballX = startX + trackLength * normalizedPosition;
    final ballY = centerY;

    // Subtle track line (optional background)
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = (color ?? AppColors.primary).withValues(alpha: 0.15);
    canvas.drawLine(
      Offset(startX, centerY),
      Offset(endX, centerY),
      trackPaint,
    );

    // Trail particles (4 particles with fade-out effect)
    final trailOpacities = [0.6, 0.4, 0.25, 0.1];
    final trailSpacing = trackLength * 0.15; // Spacing between trail particles
    
    for (int i = 0; i < trailOpacities.length; i++) {
      final trailDelay = (i + 1) * 0.12; // Delay for each trail particle
      final trailAnimationValue = (animationValue - trailDelay).clamp(0.0, 1.0);
      final trailNormalizedPosition = 0.5 + 0.5 * math.sin(trailAnimationValue * 2 * math.pi);
      final trailX = startX + trackLength * trailNormalizedPosition;
      
      final trailPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = (color ?? AppColors.primary).withValues(alpha: trailOpacities[i]);
      
      canvas.drawCircle(
        Offset(trailX, ballY),
        ballRadius * 0.6, // Trail particles are smaller
        trailPaint,
      );
    }

    // Main ball
    final ballPaint = Paint()..style = PaintingStyle.fill;
    
    if (color != null) {
      ballPaint.color = color!;
    } else {
      // Gradient for the ball
      final gradientRect = Rect.fromCircle(
        center: Offset(ballX, ballY),
        radius: ballRadius,
      );
      final shader = gradient.createShader(gradientRect);
      ballPaint.shader = shader;
    }
    
    canvas.drawCircle(
      Offset(ballX, ballY),
      ballRadius,
      ballPaint,
    );

    // Subtle glow around the ball
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    
    if (color != null) {
      glowPaint.color = color!.withValues(alpha: 0.4);
    } else {
      glowPaint.color = Colors.white.withValues(alpha: 0.3);
    }
    
    canvas.drawCircle(
      Offset(ballX, ballY),
      ballRadius,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressWaveLoaderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.gradient != gradient;
  }
}

