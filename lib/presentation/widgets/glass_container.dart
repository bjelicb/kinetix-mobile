import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final double? blur;
  final Color? borderColor;
  final double? borderWidth;
  final VoidCallback? onTap;

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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: borderWidth ?? 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur ?? 10,
            sigmaY: blur ?? 10,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.glassGradient,
              borderRadius: BorderRadius.circular(borderRadius ?? 16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius ?? 16),
                child: padding != null
                    ? Padding(
                        padding: padding!,
                        child: child,
                      )
                    : child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

