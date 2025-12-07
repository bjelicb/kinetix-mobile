import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/bootstrap_controller.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/widgets/progress_wave_loader.dart';
import '../../core/utils/shared_preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _hasNavigated = false;

  Future<void> _navigateAfterDelay() async {
    if (_hasNavigated || !mounted) return;
    
    Future.delayed(const Duration(seconds: 2), () async {
      if (_hasNavigated || !mounted) return;
      
      final router = GoRouter.maybeOf(context);
      if (router != null && mounted) {
        _hasNavigated = true;
        
        // Check onboarding status
        final isOnboardingCompleted = await SharedPreferencesService.isOnboardingCompleted();
        
        if (!isOnboardingCompleted) {
          router.go('/onboarding');
          return;
        }
        
        // If onboarding completed, navigate based on auth
        final authState = ref.read(authControllerProvider);
        final targetRoute = authState.valueOrNull != null ? '/home' : '/login';
        router.go(targetRoute);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch bootstrap completion
    final bootstrap = ref.watch(bootstrapControllerProvider);
    
    // Listen to bootstrap completion - must be in build method
    ref.listen<AsyncValue<bool>>(bootstrapControllerProvider, (previous, next) {
      if (_hasNavigated || !mounted) return;
      
      next.whenData((_) {
        _navigateAfterDelay();
      });
    });
    
    // Also check if bootstrap is already complete
    bootstrap.whenData((_) {
      if (!_hasNavigated && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateAfterDelay();
        });
      }
    });
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF000000), // Deep void black
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progress wave loader
              const ProgressWaveLoader(
                size: 100,
              ),
              const SizedBox(height: 32),
              // Loading text
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

