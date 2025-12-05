import 'package:flutter/material.dart';
import '../../core/theme/gradients.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.background,
      ),
      child: child,
    );
  }
}

