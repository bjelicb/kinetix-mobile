import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/shared_preferences_service.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/glass_container.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../data/repositories/workout_repository_impl.dart';
import '../../domain/entities/workout.dart';
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
  bool _cameraFailed = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[CheckInPage] ═══════════════════════════════════════');
    debugPrint('[CheckInPage] initState() - Page initialized');
    debugPrint('[CheckInPage] Platform: ${kIsWeb ? "Web" : "Mobile"}');
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initializeCamera();
    debugPrint('[CheckInPage] ═══════════════════════════════════════');
  }

  Future<void> _initializeCamera() async {
    debugPrint('[CheckInPage:Camera] ═══════════════════════════════════════');
    debugPrint('[CheckInPage:Camera] _initializeCamera() START');
    
    // On web, skip camera initialization after a short delay
    if (kIsWeb) {
      debugPrint('[CheckInPage:Camera] Web platform - camera not supported');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _cameraFailed = true;
        });
      }
      debugPrint('[CheckInPage:Camera] Camera marked as failed for web');
      debugPrint('[CheckInPage:Camera] ═══════════════════════════════════════');
      return;
    }

    try {
      debugPrint('[CheckInPage:Camera] Requesting available cameras (5s timeout)...');
      // Set timeout for camera initialization (5 seconds)
      _cameras = await availableCameras().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[CheckInPage:Camera] ⚠️ Timeout getting available cameras');
          return <CameraDescription>[];
        },
      );
      
      debugPrint('[CheckInPage:Camera] Found ${_cameras?.length ?? 0} cameras');
      if (_cameras != null && _cameras!.isNotEmpty) {
        for (var i = 0; i < _cameras!.length; i++) {
          debugPrint('[CheckInPage:Camera]   Camera $i: ${_cameras![i].lensDirection} - ${_cameras![i].name}');
        }
        
        final camera = _cameras![_isFrontCamera ? 1 : 0];
        debugPrint('[CheckInPage:Camera] Initializing ${_isFrontCamera ? "front" : "back"} camera...');
        _cameraController = await CameraService.initializeCamera(camera).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('[CheckInPage:Camera] ⚠️ Timeout initializing camera');
            return null;
          },
        );
        
        if (mounted) {
          final isInitialized = _cameraController != null && _cameraController!.value.isInitialized;
          debugPrint('[CheckInPage:Camera] Camera initialized: $isInitialized');
          setState(() {
            _isInitialized = isInitialized;
            _cameraFailed = !isInitialized;
          });
          if (isInitialized) {
            debugPrint('[CheckInPage:Camera] ✅ Camera ready');
          } else {
            debugPrint('[CheckInPage:Camera] ❌ Camera initialization failed');
          }
        }
      } else {
        debugPrint('[CheckInPage:Camera] ❌ No cameras available');
        if (mounted) {
          setState(() {
            _cameraFailed = true;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[CheckInPage:Camera] ❌ Error initializing camera: $e');
      debugPrint('[CheckInPage:Camera] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _cameraFailed = true;
        });
      }
    }
    debugPrint('[CheckInPage:Camera] ═══════════════════════════════════════');
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
    debugPrint('[CheckInPage:Photo] ═══════════════════════════════════════');
    debugPrint('[CheckInPage:Photo] _capturePhoto() START');
    
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint('[CheckInPage:Photo] ❌ Camera not initialized - cannot capture');
      debugPrint('[CheckInPage:Photo] ═══════════════════════════════════════');
      return;
    }

    try {
      debugPrint('[CheckInPage:Photo] Taking picture...');
      AppHaptic.medium();
      final image = await _cameraController!.takePicture();
      debugPrint('[CheckInPage:Photo] ✅ Photo captured successfully');
      debugPrint('[CheckInPage:Photo] Image path: ${image.path}');
      setState(() {
        _capturedImage = image;
      });
      debugPrint('[CheckInPage:Photo] State updated - showing preview');
      debugPrint('[CheckInPage:Photo] ═══════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('[CheckInPage:Photo] ❌ Error capturing photo: $e');
      debugPrint('[CheckInPage:Photo] Stack trace: $stackTrace');
      debugPrint('[CheckInPage:Photo] ═══════════════════════════════════════');
      // Error handled silently in UI
    }
  }

  /// Navigate to workout runner after check-in
  Future<void> _navigateToWorkoutRunner() async {
    try {
      debugPrint('[CheckInPage] _navigateToWorkoutRunner() START');
      
      // Use WorkoutRepository to get workouts (works on both web and mobile)
      final localDataSource = LocalDataSource();
      const storage = FlutterSecureStorage();
      final dio = Dio();
      final remoteDataSource = RemoteDataSource(dio, storage);
      final workoutRepository = WorkoutRepositoryImpl(localDataSource, remoteDataSource);
      
      final allWorkouts = await workoutRepository.getWorkouts();
      debugPrint('[CheckInPage] Loaded ${allWorkouts.length} total workouts');
      
      // Filter for today's workouts and exclude rest days
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      debugPrint('[CheckInPage] Today date: $todayDate (${now.year}-${now.month}-${now.day})');
      
      // Debug: log all workouts with their dates
      for (var workout in allWorkouts) {
        final workoutDate = DateTime(
          workout.scheduledDate.year,
          workout.scheduledDate.month,
          workout.scheduledDate.day,
        );
        final isDateMatch = workoutDate == todayDate;
        debugPrint('[CheckInPage] Workout: ${workout.name} | Date: $workoutDate | isRestDay: ${workout.isRestDay} | Date match: $isDateMatch');
      }
      
      // First try to find today's workout (not rest day)
      final todayWorkouts = allWorkouts.where((w) {
        final workoutDate = DateTime(
          w.scheduledDate.year,
          w.scheduledDate.month,
          w.scheduledDate.day,
        );
        final isToday = workoutDate == todayDate && !w.isRestDay;
        if (isToday) {
          debugPrint('[CheckInPage] ✓ Found today workout: ${w.name}, ID: ${w.id}, ServerID: ${w.serverId}, Date: $workoutDate');
        }
        return isToday;
      }).toList();
      
      debugPrint('[CheckInPage] Found ${todayWorkouts.length} workouts for today');
      
      Workout? targetWorkout;
      
      if (todayWorkouts.isNotEmpty) {
        // Use today's workout
        targetWorkout = todayWorkouts.first;
        debugPrint('[CheckInPage] Using today workout: ${targetWorkout.name}');
      } else {
        // Fallback: find next upcoming workout (not rest day)
        final upcomingWorkouts = allWorkouts.where((w) {
          final workoutDate = DateTime(
            w.scheduledDate.year,
            w.scheduledDate.month,
            w.scheduledDate.day,
          );
          final isUpcoming = workoutDate.isAfter(todayDate) || workoutDate == todayDate;
          return isUpcoming && !w.isRestDay;
        }).toList();
        
        if (upcomingWorkouts.isNotEmpty) {
          // Sort by date and take the first (closest to today)
          upcomingWorkouts.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
          targetWorkout = upcomingWorkouts.first;
          debugPrint('[CheckInPage] Using upcoming workout: ${targetWorkout.name}, Date: ${targetWorkout.scheduledDate}');
        } else {
          // Last fallback: first non-rest-day workout (even if in the past)
          final nonRestDayWorkouts = allWorkouts.where((w) => !w.isRestDay).toList();
          if (nonRestDayWorkouts.isNotEmpty) {
            // Sort by date descending to get the most recent one
            nonRestDayWorkouts.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
            targetWorkout = nonRestDayWorkouts.first;
            debugPrint('[CheckInPage] Using most recent workout: ${targetWorkout.name}, Date: ${targetWorkout.scheduledDate}');
          }
        }
      }
      
      if (targetWorkout != null) {
        final workoutId = targetWorkout.id;
        debugPrint('[CheckInPage] =====================================');
        debugPrint('[CheckInPage] NAVIGATION: Going to workout runner');
        debugPrint('[CheckInPage] Workout ID: $workoutId');
        debugPrint('[CheckInPage] Workout Name: ${targetWorkout.name}');
        debugPrint('[CheckInPage] Route: /workout/$workoutId');
        debugPrint('[CheckInPage] =====================================');
        if (mounted) {
          context.go('/workout/$workoutId');
        }
      } else {
        // No workout found, go to home
        debugPrint('[CheckInPage] No workouts available, navigating to home');
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[CheckInPage] Error navigating to workout runner: $e');
      debugPrint('[CheckInPage] Stack trace: $stackTrace');
      // Fallback to home on error
      if (mounted) {
        context.go('/home');
      }
    }
  }

  Future<void> _saveCheckIn() async {
    debugPrint('[CheckInPage:Submit] ═══════════════════════════════════════');
    debugPrint('[CheckInPage:Submit] _saveCheckIn() START');
    
    if (_capturedImage == null) {
      debugPrint('[CheckInPage:Submit] ❌ No captured image - cannot submit');
      debugPrint('[CheckInPage:Submit] ═══════════════════════════════════════');
      return;
    }

    try {
      debugPrint('[CheckInPage:Submit] User clicked SUBMIT CHECK-IN button');
      debugPrint('[CheckInPage:Submit] Image ready: ${_capturedImage!.path}');
      AppHaptic.heavy();

      debugPrint('[CheckInPage:Submit] Calling CheckInService.saveCheckIn()...');
      final result = await CheckInService.saveCheckIn(_capturedImage!);
      debugPrint('[CheckInPage:Submit] CheckInService returned - Success: ${result.success}');

      if (!result.success) {
        debugPrint('[CheckInPage:Submit] ❌ Check-in save FAILED');
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

      debugPrint('[CheckInPage:Submit] ✅ Check-in save SUCCESS');
      
      // Show warning if date mismatch
      if (result.warningMessage != null) {
        debugPrint('[CheckInPage:Submit] ⚠️ Warning message: ${result.warningMessage}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.warningMessage!),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      debugPrint('[CheckInPage:Submit] Playing confetti animation');
      _confettiController?.play();

      // Show success and navigate to workout runner
      debugPrint('[CheckInPage:Submit] Waiting 2 seconds before navigation...');
      await Future.delayed(const Duration(seconds: 2));

      debugPrint('[CheckInPage:Submit] Navigating to workout runner...');
      await _navigateToWorkoutRunner();
      debugPrint('[CheckInPage:Submit] ═══════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('[CheckInPage:Submit] ❌ Exception in _saveCheckIn: $e');
      debugPrint('[CheckInPage:Submit] Stack trace: $stackTrace');
      debugPrint('[CheckInPage:Submit] ═══════════════════════════════════════');
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
    debugPrint('[CheckInPage:Photo] User clicked RETAKE PHOTO button');
    debugPrint('[CheckInPage:Photo] Clearing captured image, returning to camera');
    setState(() {
      _capturedImage = null;
    });
  }

  /// Skip check-in (simulate check-in without photo) and navigate to workout runner
  Future<void> _skipCheckIn() async {
    try {
      debugPrint('[CheckInPage] =====================================');
      debugPrint('[CheckInPage] User clicked SKIP CHECK-IN button');
      debugPrint('[CheckInPage] =====================================');
      AppHaptic.medium();
      
      // Simulate check-in by setting skip flag
      debugPrint('[CheckInPage] Calling skipCheckInForToday()...');
      await SharedPreferencesService.skipCheckInForToday();
      debugPrint('[CheckInPage] Skip flag set successfully');
      
      // Verify skip flag was set
      final isSkipped = await SharedPreferencesService.isCheckInSkipped();
      debugPrint('[CheckInPage] Verification - isCheckInSkipped: $isSkipped');
      
      // Navigate to workout runner
      debugPrint('[CheckInPage] Navigating to workout runner...');
      await _navigateToWorkoutRunner();
    } catch (e) {
      debugPrint('[CheckInPage] ERROR in _skipCheckIn: $e');
      // Fallback to home on error
      if (mounted) {
        context.go('/home');
      }
    }
  }

  Widget _buildCameraFailedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: AppColors.textPrimary,
            ),
            const SizedBox(height: 24),
            Text(
              'Camera not available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You can skip check-in and go directly to your workout',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              onTap: _skipCheckIn,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.skip_next_rounded,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Skip & Go to Workout',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
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
                _cameraFailed
                    ? _buildCameraFailedView()
                    : CameraPreviewWidget(
                        controller: _cameraController,
                        cameras: _cameras,
                        isFrontCamera: _isFrontCamera,
                        flashOn: _flashOn,
                        isInitialized: _isInitialized,
                        onCapture: _capturePhoto,
                        onSwitchCamera: _switchCamera,
                        onToggleFlash: _toggleFlash,
                        onClose: _skipCheckIn,
                      )
              else
                ImagePreviewWidget(
                  capturedImage: _capturedImage!,
                  onRetake: _retakePhoto,
                  onConfirm: _saveCheckIn,
                  onClose: _skipCheckIn,
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
