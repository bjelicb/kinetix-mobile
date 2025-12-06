import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import 'gradient_card.dart';
import 'neon_button.dart';

class SuccessAnimation extends StatefulWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool isError;

  const SuccessAnimation({
    super.key,
    this.message,
    this.onRetry,
    this.isError = false,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkmarkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _checkmarkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GradientCard(
          gradient: widget.isError ? AppGradients.orangePink : AppGradients.success,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Checkmark or Error Icon
              widget.isError
                  ? const Icon(
                      Icons.error_outline_rounded,
                      size: 80,
                      color: AppColors.textPrimary,
                    )
                  : _buildCheckmark(),
              const SizedBox(height: 24),
              if (widget.message != null) ...[
                Text(
                  widget.message!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
              if (widget.isError && widget.onRetry != null) ...[
                NeonButton(
                  text: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: widget.onRetry,
                  gradient: AppGradients.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckmark() {
    return CustomPaint(
      size: const Size(80, 80),
      painter: CheckmarkPainter(_checkmarkAnimation.value),
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw circle
    canvas.drawCircle(center, radius, paint);

    // Draw checkmark
    if (progress > 0) {
      final path = Path();
      final startX = center.dx - radius * 0.3;
      final startY = center.dy;
      final midX = center.dx - radius * 0.1;
      final midY = center.dy + radius * 0.3;
      final endX = center.dx + radius * 0.4;
      final endY = center.dy - radius * 0.2;

      path.moveTo(startX, startY);
      path.lineTo(midX, midY);
      path.lineTo(endX, endY);

      final pathMetrics = path.computeMetrics().first;
      final pathLength = pathMetrics.length;
      final animatedPath = pathMetrics.extractPath(0, pathLength * progress);

      canvas.drawPath(animatedPath, paint);
    }
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

