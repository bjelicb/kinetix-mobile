import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/onboarding_page.dart';
import '../../presentation/pages/check_in_page.dart';
import '../../presentation/pages/dashboard_page.dart';
import '../../presentation/pages/calendar_page.dart';
import '../../presentation/pages/profile_page.dart';
import '../../presentation/pages/workout_runner_page.dart';
import '../../presentation/pages/workout_edit_page.dart';
import '../../presentation/pages/exercise_selection_page.dart';
import '../../presentation/pages/check_in_history_page.dart';
import '../../presentation/pages/analytics_page.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/widgets/custom_bottom_nav.dart';
import '../../core/theme/animations.dart';
import '../../core/utils/shared_preferences_service.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authControllerProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final isAuthenticated = authState.valueOrNull != null;
      final currentLocation = state.matchedLocation;
      
      // If on splash, wait for bootstrap then redirect
      if (currentLocation == '/splash') {
        // Check if bootstrap is complete by watching the provider
        // For now, allow splash to stay and let it handle navigation
        return null;
      }
      
      // Check onboarding status
      final isOnboardingCompleted = await SharedPreferencesService.isOnboardingCompleted();
      
      // If onboarding not completed, redirect to onboarding (unless already there)
      if (!isOnboardingCompleted && currentLocation != '/onboarding' && currentLocation != '/splash') {
        return '/onboarding';
      }
      
      // If onboarding completed and on onboarding page, redirect based on auth
      if (isOnboardingCompleted && currentLocation == '/onboarding') {
        return isAuthenticated ? '/home' : '/login';
      }
      
      // If not authenticated and not on login/splash/onboarding, go to login
      if (!isAuthenticated && currentLocation != '/login' && currentLocation != '/splash' && currentLocation != '/onboarding') {
        return '/login';
      }
      
      // If authenticated and on login, go to home
      if (isAuthenticated && currentLocation == '/login') {
        return '/home';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: AppAnimations.pageTransitionDuration,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: AppAnimations.pageTransitionDuration,
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: AppAnimations.pageTransitionDuration,
        ),
      ),
      GoRoute(
        path: '/check-in',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CheckInPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: AppAnimations.pageTransitionCurve),
            );
            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: AppAnimations.pageTransitionDuration,
        ),
      ),
      GoRoute(
        path: '/check-in/history',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CheckInHistoryPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppAnimations.pageTransitionCurve,
            ));
            return SlideTransition(position: slideAnimation, child: child);
          },
          transitionDuration: AppAnimations.pageTransitionDuration,
        ),
      ),
      GoRoute(
        path: '/analytics',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AnalyticsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppAnimations.pageTransitionCurve,
            ));
            return SlideTransition(position: slideAnimation, child: child);
          },
          transitionDuration: AppAnimations.pageTransitionDuration,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child, state: state),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DashboardPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: AppAnimations.pageTransitionCurve,
                ));
                return SlideTransition(position: slideAnimation, child: child);
              },
              transitionDuration: AppAnimations.pageTransitionDuration,
            ),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const CalendarPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: AppAnimations.pageTransitionCurve,
                ));
                return SlideTransition(position: slideAnimation, child: child);
              },
              transitionDuration: AppAnimations.pageTransitionDuration,
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfilePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: AppAnimations.pageTransitionCurve,
                ));
                return SlideTransition(position: slideAnimation, child: child);
              },
              transitionDuration: AppAnimations.pageTransitionDuration,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/workout/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: WorkoutRunnerPage(workoutId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: AppAnimations.pageTransitionCurve),
              );
              return ScaleTransition(
                scale: scaleAnimation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            transitionDuration: AppAnimations.pageTransitionDuration,
          );
        },
      ),
      GoRoute(
        path: '/workout/new',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final selectedDate = extra is DateTime ? extra : null;
          return CustomTransitionPage(
            key: state.pageKey,
            child: WorkoutEditPage(selectedDate: selectedDate),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: AppAnimations.pageTransitionCurve),
              );
              return ScaleTransition(
                scale: scaleAnimation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            transitionDuration: AppAnimations.pageTransitionDuration,
          );
        },
      ),
      GoRoute(
        path: '/workout/:id/edit',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: WorkoutEditPage(workoutId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: AppAnimations.pageTransitionCurve),
              );
              return ScaleTransition(
                scale: scaleAnimation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            transitionDuration: AppAnimations.pageTransitionDuration,
          );
        },
      ),
      GoRoute(
        path: '/exercise-selection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ExerciseSelectionPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: AppAnimations.pageTransitionCurve),
            );
            return ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: AppAnimations.pageTransitionDuration,
        ),
      ),
    ],
  );
}

// Modern HomeShell with Custom Bottom Navigation
class HomeShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;
  
  const HomeShell({required this.child, required this.state, super.key});
  
  int _getCurrentIndex() {
    final location = state.matchedLocation;
    if (location == '/home') return 0;
    if (location == '/calendar') return 1;
    if (location == '/profile') return 2;
    return 0;
  }
  
  void _onNavTap(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/calendar');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _getCurrentIndex(),
        onTap: (index) => _onNavTap(index, context),
      ),
    );
  }
}
