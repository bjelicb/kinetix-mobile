import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../core/utils/shared_preferences_service.dart';
import '../../core/utils/haptic_feedback.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/neon_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;

  final List<OnboardingScreen> _screens = [
    OnboardingScreen(
      title: 'Welcome to Kinetix',
      description: 'Your personal fitness companion for tracking workouts, progress, and achieving your goals.',
      icon: Icons.fitness_center_rounded,
      gradient: AppGradients.primary,
    ),
    OnboardingScreen(
      title: 'Track Your Progress',
      description: 'Log workouts, monitor strength gains, and track your fitness journey with daily check-ins.',
      icon: Icons.trending_up_rounded,
      gradient: AppGradients.secondary,
    ),
    OnboardingScreen(
      title: 'Smart Workout Features',
      description: 'Use our smart input system for logging sets, RPE tracking, and personalized workout plans.',
      icon: Icons.auto_awesome_rounded,
      gradient: AppGradients.success,
    ),
    OnboardingScreen(
      title: 'Permissions Needed',
      description: 'We need camera access for check-in photos and storage access to save your workout data locally.',
      icon: Icons.security_rounded,
      gradient: AppGradients.card,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      AppHaptic.light();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    AppHaptic.medium();
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await SharedPreferencesService.setOnboardingCompleted(true);
    AppHaptic.success();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Skip Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _totalPages,
                  itemBuilder: (context, index) {
                    return _buildOnboardingScreen(_screens[index]);
                  },
                ),
              ),

              // Page Indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _totalPages,
                    (index) => _buildPageIndicator(index == _currentPage),
                  ),
                ),
              ),

              // Next/Get Started Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: NeonButton(
                  text: _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                  icon: _currentPage == _totalPages - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  onPressed: _nextPage,
                  gradient: AppGradients.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingScreen(OnboardingScreen screen) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: screen.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              screen.icon,
              size: 60,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 48),
          
          // Title
          Text(
            screen.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Description
          Text(
            screen.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        gradient: isActive ? AppGradients.primary : AppGradients.card,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingScreen {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;

  OnboardingScreen({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}

