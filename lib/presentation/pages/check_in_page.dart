import 'dart:io' as io show Directory, File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:image/image.dart' as img;
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../presentation/widgets/glass_container.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../presentation/widgets/shimmer_loader.dart';
import '../../core/utils/image_cache_manager.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../data/models/checkin_collection.dart' if (dart.library.html) '../../data/models/checkin_collection_stub.dart';
import '../../services/cloudinary_upload_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
        _cameraController = CameraController(
          _cameras![_isFrontCamera ? 1 : 0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    
    await _cameraController?.dispose();
    _cameraController = CameraController(
      _cameras![_isFrontCamera ? 1 : 0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    
    try {
      if (_flashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _flashOn = !_flashOn;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
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
      debugPrint('Error capturing photo: $e');
    }
  }

  Future<void> _saveCheckIn() async {
    if (_capturedImage == null) return;

    try {
      AppHaptic.heavy();
      
      // Read and compress image
      Uint8List imageBytes;
      String? savedPath;
      
      if (!kIsWeb) {
        // Read image from file
        imageBytes = await io.File(_capturedImage!.path).readAsBytes();
        final originalImage = img.decodeImage(imageBytes);
        
        if (originalImage != null) {
          // Resize to max 1920x1920 while maintaining aspect ratio
          final resizedImage = img.copyResize(
            originalImage,
            width: originalImage.width > 1920 ? 1920 : null,
            height: originalImage.height > 1920 ? 1920 : null,
            maintainAspect: true,
          );
          
          // Compress to JPEG with 85% quality
          imageBytes = Uint8List.fromList(
            img.encodeJpg(resizedImage, quality: 85),
          );
          
          // Save compressed image locally
          final appDir = await getApplicationDocumentsDirectory();
          final checkinsDir = io.Directory(path.join(appDir.path, 'checkins'));
          if (!await checkinsDir.exists()) {
            await checkinsDir.create(recursive: true);
          }
          
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'checkin_$timestamp.jpg';
          savedPath = path.join(checkinsDir.path, fileName);
          final savedFile = io.File(savedPath);
          await savedFile.writeAsBytes(imageBytes);
          
          // Cache the image
          await ImageCacheManager.instance.cacheImage(savedPath, imageBytes);
        }
      } else {
        // Web: read from XFile
        imageBytes = await _capturedImage!.readAsBytes();
      }

      // Upload to Cloudinary and create check-in
      String? photoUrl;
      try {
        final storage = FlutterSecureStorage();
        final dio = Dio();
        final remoteDataSource = RemoteDataSource(dio, storage);
        final cloudinaryService = CloudinaryUploadService(remoteDataSource);
        
        // Upload to Cloudinary
        photoUrl = await cloudinaryService.uploadCheckInPhoto(imageBytes);
        
        // Create check-in via API
        final checkInData = {
          'checkinDate': DateTime.now().toIso8601String(),
          'photoUrl': photoUrl,
          'gpsCoordinates': null, // TODO: Add GPS coordinates if available
        };
        
        await remoteDataSource.createCheckIn(checkInData);
      } catch (uploadError) {
        // If upload fails, still save locally for later sync
        debugPrint('Cloudinary upload failed, saving locally for sync: $uploadError');
      }

      // Save to Isar database (skip on web)
      if (!kIsWeb && savedPath != null) {
        final checkIn = CheckInCollection()
          ..photoLocalPath = savedPath
          ..photoUrl = photoUrl
          ..timestamp = DateTime.now()
          ..isSynced = photoUrl != null; // Mark as synced if upload succeeded
        
        final localDataSource = LocalDataSource();
        await localDataSource.saveCheckIn(checkIn);
      }
      
      _confettiController?.play();
      
      // Show success and navigate
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      debugPrint('Error saving check-in: $e');
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
                _buildCameraView()
              else
                _buildPhotoPreview(),
              
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

  Widget _buildCameraView() {
    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: ShimmerLoader(width: 200, height: 200, borderRadius: 16),
      );
    }

    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),
        
        // Overlay with guide lines
        Positioned.fill(
          child: CustomPaint(
            painter: _GuideLinesPainter(),
          ),
        ),
        
        // Top Controls
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close Button
              GlassContainer(
                borderRadius: 12,
                padding: const EdgeInsets.all(12),
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
              
              // Flash Toggle
              GlassContainer(
                borderRadius: 12,
                padding: const EdgeInsets.all(12),
                onTap: _toggleFlash,
                child: Icon(
                  _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: _flashOn ? AppColors.accentYellow : AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        
        // Bottom Controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Instructions
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                margin: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Position your face in the frame',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              
              // Capture Button and Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Switch Camera
                  if (_cameras != null && _cameras!.length > 1)
                    GlassContainer(
                      borderRadius: 30,
                      padding: const EdgeInsets.all(16),
                      onTap: _switchCamera,
                      child: const Icon(
                        Icons.flip_camera_ios_rounded,
                        color: AppColors.textPrimary,
                        size: 28,
                      ),
                    )
                  else
                    const SizedBox(width: 60),
                  
                  // Capture Button
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.primary,
                        border: Border.all(
                          color: AppColors.textPrimary,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.circle,
                        color: AppColors.textPrimary,
                        size: 60,
                      ),
                    ),
                  ),
                  
                  // Placeholder for symmetry
                  const SizedBox(width: 60),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPreview() {
    return Stack(
      children: [
        // Photo Preview
        Positioned.fill(
          child: kIsWeb
              ? Image.network(_capturedImage!.path, fit: BoxFit.cover)
              : Image.file(
                  io.File(_capturedImage!.path),
                  fit: BoxFit.cover,
                ),
        ),
        
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.background.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),
        
        // Top Controls
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: GlassContainer(
            padding: const EdgeInsets.all(12),
            onTap: _retakePhoto,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Retake',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom Controls
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            children: [
              NeonButton(
                text: 'Confirm Check-In',
                icon: Icons.check_circle_rounded,
                onPressed: _saveCheckIn,
                gradient: AppGradients.success,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Face guide frame (centered, 60% of screen width)
    final frameSize = size.width * 0.6;
    final frameLeft = (size.width - frameSize) / 2;
    final frameTop = size.height * 0.2;
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(frameLeft, frameTop, frameSize, frameSize * 1.3),
      const Radius.circular(20),
    );

    canvas.drawRRect(frameRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
