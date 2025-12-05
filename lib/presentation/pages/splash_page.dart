import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../presentation/controllers/bootstrap_controller.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
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
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        'KINETIX',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              // Loading Indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

