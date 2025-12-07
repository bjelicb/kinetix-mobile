import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'progress_wave_loader.dart';

class AuthOverlay extends StatefulWidget {
  final String statusText;
  final double loaderSize;
  final Color? loaderColor;
  final bool showBlur;

  const AuthOverlay({
    super.key,
    required this.statusText,
    this.loaderSize = 80,
    this.loaderColor,
    this.showBlur = true,
  });

  @override
  State<AuthOverlay> createState() => _AuthOverlayState();
}

class _AuthOverlayState extends State<AuthOverlay> {
  // GlobalKey to preserve loader state and prevent reset
  final _loaderKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: AppColors.background.withValues(alpha: 0.95),
        child: Stack(
          children: [
            // Optional blur effect
            if (widget.showBlur)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            // Centered content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress wave loader with key to prevent reset
                  RepaintBoundary(
                    child: ProgressWaveLoader(
                      key: _loaderKey,
                      size: widget.loaderSize,
                      color: widget.loaderColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Status text with fade animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      widget.statusText,
                      key: ValueKey<String>(widget.statusText),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

