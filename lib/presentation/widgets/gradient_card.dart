import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart' show AppColors, TrainerThemes;
import '../../core/theme/gradients.dart';
import '../controllers/theme_controller.dart';
import 'hexagon_clipper.dart';

class GradientCard extends ConsumerStatefulWidget {
  final Widget child;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool showGlow;
  final Color? glowColor;
  final Color? borderColor; // Added for tone-based borders
  final double? elevation;
  final bool pressEffect;
  final double pressedScale;
  final bool useHexShape;
  final bool showCyberBorder;

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
    this.borderColor,
    this.elevation,
    this.pressEffect = false,
    this.pressedScale = 0.98,
    this.useHexShape = false,
    this.showCyberBorder = false,
  });

  @override
  ConsumerState<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends ConsumerState<GradientCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  AnimationController? _borderController;
  Animation<double>? _borderAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.showCyberBorder) {
      _borderController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat();
      _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _borderController!, curve: Curves.linear),
      );
    }
  }

  @override
  void dispose() {
    _borderController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final themeColor = _getThemeColor(theme);
    final glowColor = widget.glowColor ?? themeColor;

    Widget content = Container(
      margin: widget.margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: widget.gradient ?? AppGradients.card,
        borderRadius: widget.useHexShape
            ? null
            : BorderRadius.circular(widget.borderRadius ?? 16),
        border: widget.borderColor != null
            ? Border.all(
                width: 2,
                color: widget.borderColor!,
              )
            : widget.showCyberBorder
                ? Border.all(
                    width: 1.5,
                    color: _getAnimatedBorderColor(theme),
                  )
                : null,
        boxShadow: widget.showGlow
            ? [
                BoxShadow(
                  color: glowColor.withValues(
                      alpha: _pressed ? 0.5 : 0.3),
                  blurRadius: _pressed ? 30 : 20,
                  spreadRadius: _pressed ? 3 : 2,
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
      child: widget.useHexShape
          ? ClipPath(
              clipper: HexagonClipper(cornerCut: 0.15),
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
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(16),
                    child: widget.child,
                  ),
                ),
              ),
            )
          : Material(
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

    Widget animatedContent = widget.pressEffect
        ? AnimatedScale(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            scale: _pressed ? widget.pressedScale : 1.0,
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 120),
              turns: _pressed ? 0.002 : 0.0, // Subtle 3D tilt
              child: content,
            ),
          )
        : content;

    return animatedContent;
  }

  Color _getThemeColor(TrainerTheme theme) {
    switch (theme) {
      case TrainerTheme.milan:
        return TrainerThemes.milanPrimary;
      case TrainerTheme.aca:
        return TrainerThemes.acaPrimary;
      case TrainerTheme.neutral:
        return AppColors.primary;
    }
  }

  Color _getAnimatedBorderColor(TrainerTheme theme) {
    if (!widget.showCyberBorder || _borderAnimation == null) {
      return Colors.transparent;
    }
    
    final baseColor = _getThemeColor(theme);
    final animatedAlpha = 0.3 + (_borderAnimation!.value * 0.4);
    return baseColor.withValues(alpha: animatedAlpha);
  }
}

