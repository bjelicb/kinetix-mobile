import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../core/theme/app_colors.dart' show TrainerThemes;
import '../../core/utils/haptic_feedback.dart';
import '../controllers/theme_controller.dart';
import 'smooth_loader.dart';

class NeonButton extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final bool showGlow;
  final IconData? icon;
  final bool isLoading;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.padding,
    this.borderRadius,
    this.showGlow = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  ConsumerState<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends ConsumerState<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    AppHaptic.selection();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onPressed != null && !widget.isLoading) {
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final glowColor = _getThemeGlowColor(theme);

    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading
          ? _handleTapDown
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading
          ? _handleTapUp
          : null,
      onTapCancel: widget.onPressed != null && !widget.isLoading
          ? _handleTapCancel
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient ?? AppGradients.primary,
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
            boxShadow: widget.showGlow && widget.onPressed != null
                ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed != null && !widget.isLoading
                  ? () {
                      AppHaptic.medium();
                      widget.onPressed!();
                    }
                  : null,
              splashColor: glowColor.withValues(alpha: 0.3),
              highlightColor: glowColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 12),
              child: Container(
                padding: widget.padding ??
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isLoading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: SmoothLoader(
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                      )
                    else if (widget.icon != null) ...[
                      Icon(widget.icon, color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getThemeGlowColor(TrainerTheme theme) {
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

