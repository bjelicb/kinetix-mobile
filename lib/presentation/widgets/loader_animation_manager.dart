import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

/// Global animation manager that maintains continuous animation state
/// across widget rebuilds and navigation
class LoaderAnimationManager {
  static final LoaderAnimationManager _instance = LoaderAnimationManager._internal();
  factory LoaderAnimationManager() => _instance;
  LoaderAnimationManager._internal();

  double _animationValue = 0.0;
  Ticker? _ticker;
  final List<ValueChanged<double>> _listeners = [];

  double get animationValue => _animationValue;

  void start() {
    if (_ticker != null && _ticker!.isActive) return;

    const duration = 1300; // 1.3 seconds per cycle (faster)

    _ticker = Ticker((elapsed) {
      final elapsedMs = elapsed.inMilliseconds;
      _animationValue = (elapsedMs % duration) / duration;
      
      // Notify all listeners
      for (final listener in _listeners) {
        listener(_animationValue);
      }
    });
    
    _ticker!.start();
  }

  void stop() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
  }

  void addListener(ValueChanged<double> listener) {
    _listeners.add(listener);
    // Immediately notify with current value
    listener(_animationValue);
  }

  void removeListener(ValueChanged<double> listener) {
    _listeners.remove(listener);
  }

  void dispose() {
    stop();
    _listeners.clear();
  }
}

