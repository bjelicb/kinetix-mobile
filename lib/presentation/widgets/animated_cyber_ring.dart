import 'package:flutter/material.dart';

class AnimatedCyberRing extends StatefulWidget {
  final Color color;
  final Duration delay;
  final double initialRadius;
  final double maxRadius;

  const AnimatedCyberRing({
    super.key,
    required this.color,
    this.delay = Duration.zero,
    this.initialRadius = 50,
    this.maxRadius = 300,
  });

  @override
  State<AnimatedCyberRing> createState() => _AnimatedCyberRingState();
}

class _AnimatedCyberRingState extends State<AnimatedCyberRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _radiusAnimation = Tween<double>(
      begin: widget.initialRadius,
      end: widget.maxRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 0.4)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
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
          painter: _CyberRingPainter(
            radius: _radiusAnimation.value,
            opacity: _opacityAnimation.value,
            color: widget.color,
          ),
          size: Size(
            widget.maxRadius * 2,
            widget.maxRadius * 2,
          ),
        );
      },
    );
  }
}

class _CyberRingPainter extends CustomPainter {
  final double radius;
  final double opacity;
  final Color color;

  _CyberRingPainter({
    required this.radius,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw main ring
    canvas.drawCircle(center, radius, paint);

    // Draw inner glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(center, radius - 2, glowPaint);
  }

  @override
  bool shouldRepaint(_CyberRingPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.opacity != opacity;
  }
}
