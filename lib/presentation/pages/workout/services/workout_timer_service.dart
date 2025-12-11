import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/utils/haptic_feedback.dart';

/// Service for managing workout timer
class WorkoutTimerService {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isPaused = false;
  VoidCallback? _onTick;

  int get elapsedSeconds => _elapsedSeconds;
  bool get isPaused => _isPaused;

  /// Start the timer
  void startTimer(VoidCallback onTick) {
    _onTick = onTick;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _elapsedSeconds++;
        _onTick?.call();
      }
    });
  }

  /// Stop the timer
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Toggle pause state
  void togglePause() {
    _isPaused = !_isPaused;
    AppHaptic.medium();
  }

  /// Format seconds into HH:MM:SS or MM:SS format
  static String formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Dispose resources
  void dispose() {
    _timer?.cancel();
  }
}

