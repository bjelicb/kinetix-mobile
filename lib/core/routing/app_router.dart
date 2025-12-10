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
import '../../presentation/pages/settings_page.dart';
import '../../presentation/pages/workout_history_page.dart';
import '../../presentation/pages/admin_dashboard_page.dart';
import '../../presentation/pages/payment_page.dart';
import '../../presentation/pages/weigh_in_page.dart';
import '../../presentation/pages/ai_messages_page.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/widgets/custom_bottom_nav.dart';
import '../../core/theme/animations.dart';
import '../../core/utils/shared_preferences_service.dart';
import '../../data/datasources/local_data_source.dart';
import '../../domain/entities/user.dart';

part 'app_router.g.dart';

/// Helper function to check if user should be required to check in
/// Returns true if:
/// - User is a CLIENT (not TRAINER)
/// - User has an active plan
/// - User has a workout scheduled for today
/// - The workout is NOT completed
/// - User has NOT already checked in today
Future<bool> _shouldRequireCheckIn(User? user) async {
  // If no user, no check-in required
  if (user == null) return false;
  
  // Only clients need to check in
  if (user.role != 'CLIENT') return false;
  
  final localDataSource = LocalDataSource();
  
  // Check if user has an active plan
  final activePlan = await localDataSource.getActivePlan();
  debugPrint('[AppRouter:CheckInValidation] Active plan check: ${activePlan != null}');
  
  if (activePlan == null) {
    debugPrint('[AppRouter:CheckInValidation] No active plan - Check-in NOT required');
    return false;
  }
  
  debugPrint('[AppRouter:CheckInValidation] Active plan found: ${activePlan.name}');
  
  // Check if user already checked in today
  final todayCheckIn = await localDataSource.getTodayCheckIn();
  if (todayCheckIn != null) {
    debugPrint('[AppRouter:CheckInValidation] Already checked in today - Check-in NOT required');
    return false;
  }
  
  // Check if there's a queued check-in for today (offline mode)
  final unsyncedCheckIns = await localDataSource.getUnsyncedCheckIns();
  if (unsyncedCheckIns.isNotEmpty) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (final checkIn in unsyncedCheckIns) {
      final checkInDate = DateTime(
        checkIn.timestamp.year,
        checkIn.timestamp.month,
        checkIn.timestamp.day,
      );
      
      if (checkInDate.isAtSameMomentAs(today)) {
        debugPrint('[AppRouter:CheckInValidation] Found queued check-in for today - Bypassing requirement');
        return false;
      }
    }
  }
  
  // Check if user has workouts scheduled for today
  final todayWorkouts = await localDataSource.getTodayWorkouts();
  
  // No workouts today, no check-in required
  if (todayWorkouts.isEmpty) return false;
  
  // Check if any workout is not completed
  // If all workouts are completed, no check-in required
  final hasIncompleteWorkout = todayWorkouts.any((workout) => !workout.isCompleted);
  
  return hasIncompleteWorkout;
}

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
      
      // Mandatory check-in flow (only for clients with incomplete workout today)
      if (isAuthenticated) {
        final user = authState.valueOrNull;
        
        // Allow access to check-in pages, login, splash, onboarding, payment without check-in requirement
        final allowedRoutesWithoutCheckIn = [
          '/check-in',
          '/check-in/history',
          '/login',
          '/splash',
          '/onboarding',
          '/payment',
        ];
        
        if (allowedRoutesWithoutCheckIn.contains(currentLocation)) {
          return null; // Allow access
        }
        
        // Check if check-in is required
        try {
          final requiresCheckIn = await _shouldRequireCheckIn(user);
          
          if (requiresCheckIn) {
            // Redirect to check-in if not already there or on check-in history
            if (currentLocation != '/check-in' && currentLocation != '/check-in/history') {
              return '/check-in';
            }
          }
        } catch (e) {
          // If error checking check-in requirement, allow access (fail gracefully)
          // This prevents blocking user if there's a temporary error
        }
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
        builder: (context, state, child) => HomeShell(state: state, child: child),
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
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) {
              // SECURITY: Check admin role
              final user = ref.read(authControllerProvider).valueOrNull;
              if (user?.role != 'ADMIN') {
                return CustomTransitionPage(
                  key: state.pageKey,
                  child: Scaffold(
                    appBar: AppBar(title: const Text('Access Denied')),
                    body: const Center(
                      child: Text('You do not have permission to access this page.'),
                    ),
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: AppAnimations.pageTransitionDuration,
                );
              }
              
              return CustomTransitionPage(
                key: state.pageKey,
                child: const AdminDashboardPage(),
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
              );
            },
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
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsPage(),
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
        path: '/workout-history',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WorkoutHistoryPage(),
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
        path: '/payment',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PaymentPage(),
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
        path: '/weigh-in',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WeighInPage(),
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
        path: '/ai-messages',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AIMessagesPage(),
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
    if (location == '/admin') return 3;
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
      case 3:
        context.go('/admin');
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
