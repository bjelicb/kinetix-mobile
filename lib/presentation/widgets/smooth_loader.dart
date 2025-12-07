import 'package:flutter/material.dart';
import '../../core/theme/gradients.dart';
import 'progress_wave_loader.dart';

/// SmoothLoader - now uses ProgressWaveLoader internally
/// Maintains the same API for backward compatibility
class SmoothLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final Gradient? gradient;

  const SmoothLoader({
    super.key,
    this.size = 60,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ProgressWaveLoader(
      size: size,
      color: color,
      gradient: gradient ?? AppGradients.primary,
    );
  }
}

