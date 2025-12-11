import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../core/utils/haptic_feedback.dart';
import 'check_in/services/camera_service.dart';
import 'check_in/services/check_in_service.dart';
import '../widgets/check_in/camera_preview_widget.dart';
import '../widgets/check_in/image_preview_widget.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isFrontCamera = false;
  bool _flashOn = false;
  XFile? _capturedImage;
  ConfettiController? _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final camera = _cameras![_isFrontCamera ? 1 : 0];
        _cameraController = await CameraService.initializeCamera(camera);
        setState(() {
          _isInitialized = _cameraController != null;
        });
      }
    } catch (e) {
      // Error handled in service
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });

    final newCamera = _cameras![_isFrontCamera ? 1 : 0];
    _cameraController = await CameraService.switchCamera(newCamera, _cameraController);
    setState(() {});
  }

  Future<void> _toggleFlash() async {
    final newFlashState = await CameraService.toggleFlash(_cameraController, _flashOn);
    setState(() {
      _flashOn = newFlashState;
    });
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      AppHaptic.medium();
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      // Error handled silently
    }
  }

  Future<void> _saveCheckIn() async {
    if (_capturedImage == null) return;

    try {
      AppHaptic.heavy();

      final result = await CheckInService.saveCheckIn(_capturedImage!);

      if (!result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error saving check-in'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Show warning if date mismatch
      if (result.warningMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.warningMessage!),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      _confettiController?.play();

      // Show success and navigate
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving check-in: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _confettiController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Camera Preview or Photo Preview
              if (_capturedImage == null)
                CameraPreviewWidget(
                  controller: _cameraController,
                  cameras: _cameras,
                  isFrontCamera: _isFrontCamera,
                  flashOn: _flashOn,
                  isInitialized: _isInitialized,
                  onCapture: _capturePhoto,
                  onSwitchCamera: _switchCamera,
                  onToggleFlash: _toggleFlash,
                  onClose: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/home');
                    }
                  },
                )
              else
                ImagePreviewWidget(
                  capturedImage: _capturedImage!,
                  onRetake: _retakePhoto,
                  onConfirm: _saveCheckIn,
                ),

              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController!,
                  blastDirection: 3.14 / 2,
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
