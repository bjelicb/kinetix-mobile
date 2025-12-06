import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';

class GradientCard extends StatefulWidget {
  final Widget child;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool showGlow;
  final Color? glowColor;
  final double? elevation;
  final bool pressEffect;
  final double pressedScale;

  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.showGlow = false,
    this.glowColor,
    this.elevation,
    this.pressEffect = false,
    this.pressedScale = 0.98,
  });

  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: widget.margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: widget.gradient ?? AppGradients.card,
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
        boxShadow: widget.showGlow
            ? [
                BoxShadow(
                  color: (widget.glowColor ?? AppColors.primary).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : widget.elevation != null
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: widget.elevation! * 2,
                      offset: Offset(0, widget.elevation!),
                    ),
                  ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) {
            if (!widget.pressEffect) return;
            setState(() {
              _pressed = v;
            });
          },
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: widget.child,
          ),
        ),
      ),
    );

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      scale: widget.pressEffect && _pressed ? widget.pressedScale : 1.0,
      child: content,
    );
  }
}

