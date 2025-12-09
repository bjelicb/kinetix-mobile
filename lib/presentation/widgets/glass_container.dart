import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart' show AppColors, TrainerThemes;
import '../../core/theme/gradients.dart';
import '../controllers/theme_controller.dart';
import 'hexagon_clipper.dart';

class GlassContainer extends ConsumerStatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final double? blur;
  final Color? borderColor;
  final double? borderWidth;
  final VoidCallback? onTap;
  final bool useHexShape;
  final bool animateOnTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur,
    this.borderColor,
    this.borderWidth,
    this.onTap,
    this.useHexShape = false,
    this.animateOnTap = false,
  });

  @override
  ConsumerState<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends ConsumerState<GlassContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.animateOnTap) {
      _scaleController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
      );
      _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    if (widget.animateOnTap) {
      _scaleController.dispose();
    }
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.animateOnTap) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.animateOnTap) {
      _scaleController.reverse();
    }
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.animateOnTap) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeControllerProvider);
    final themeColor = _getThemeColor(theme);
    final borderColor = widget.borderColor ?? 
        (widget.useHexShape 
            ? themeColor.withValues(alpha: 0.5)
            : AppColors.glassBorder);

    Widget container = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: widget.useHexShape 
            ? null 
            : BorderRadius.circular(widget.borderRadius ?? 16),
        border: Border.all(
          color: borderColor,
          width: widget.borderWidth ?? 1,
        ),
      ),
      child: widget.useHexShape
          ? ClipPath(
              clipper: HexagonClipper(cornerCut: 0.15),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.blur ?? 10,
                  sigmaY: widget.blur ?? 10,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.glassGradient,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      onTapDown: widget.animateOnTap ? _handleTapDown : null,
                      onTapUp: widget.animateOnTap ? _handleTapUp : null,
                      onTapCancel: widget.animateOnTap ? _handleTapCancel : null,
                      child: widget.padding != null
                          ? Padding(
                              padding: widget.padding!,
                              child: widget.child,
                            )
                          : widget.child,
                    ),
                  ),
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
                  sigmaX: widget.blur ?? 10,
                  sigmaY: widget.blur ?? 10,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.glassGradient,
                    borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                      onTap: widget.onTap,
                      onTapDown: widget.animateOnTap ? _handleTapDown : null,
                      onTapUp: widget.animateOnTap ? _handleTapUp : null,
                      onTapCancel: widget.animateOnTap ? _handleTapCancel : null,
                      borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
                      child: widget.padding != null
                    ? Padding(
                              padding: widget.padding!,
                              child: widget.child,
                      )
                          : widget.child,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.animateOnTap) {
      return GestureDetector(
        onTapDown: widget.onTap != null ? _handleTapDown : null,
        onTapUp: widget.onTap != null ? _handleTapUp : null,
        onTapCancel: widget.onTap != null ? _handleTapCancel : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: container,
        ),
      );
    }

    return container;
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
}

