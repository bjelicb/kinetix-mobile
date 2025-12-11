import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service for camera management
class CameraService {
  /// Initialize camera controller
  /// Returns initialized controller or null on failure
  static Future<CameraController?> initializeCamera(
    CameraDescription camera,
  ) async {
    try {
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      return controller;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      return null;
    }
  }

  /// Switch camera
  /// Returns new initialized controller or null on failure
  static Future<CameraController?> switchCamera(
    CameraDescription newCamera,
    CameraController? oldController,
  ) async {
    await oldController?.dispose();

    return await initializeCamera(newCamera);
  }

  /// Toggle flash mode
  /// Returns new flash state (true = on, false = off)
  static Future<bool> toggleFlash(CameraController? controller, bool currentFlashState) async {
    if (controller == null) return currentFlashState;

    try {
      if (currentFlashState) {
        await controller.setFlashMode(FlashMode.off);
      } else {
        await controller.setFlashMode(FlashMode.torch);
      }
      return !currentFlashState;
    } catch (e) {
      debugPrint('Error toggling flash: $e');
      return currentFlashState;
    }
  }
}

