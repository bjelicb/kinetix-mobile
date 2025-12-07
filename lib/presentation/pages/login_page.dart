import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../core/constants/app_assets.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/theme_controller.dart';
import '../../presentation/widgets/gradient_background.dart';
import '../../presentation/widgets/neon_button.dart';
import '../../presentation/widgets/gradient_card.dart';
import '../../presentation/widgets/trainer_avatar.dart';
import '../../presentation/widgets/auth_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      await ref.read(authControllerProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // GoRouter redirect will automatically navigate to /home
      // when authState changes, so we don't need to manually navigate
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
    return GradientBackground(
      gradient: AppGradients.loginBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: MediaQuery.of(context).size.height * 0.05,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    // Hex logo with smooth shimmer animation
                    Image.asset(
                      AppAssets.logoHex,
                      width: MediaQuery.of(context).size.width * 0.35,
                      height: MediaQuery.of(context).size.width * 0.35,
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic)
                        .shimmer(
                          duration: 2500.ms,
                          color: AppColors.primary.withValues(alpha: 0.3),
                          curve: Curves.easeInOutCubic,
                        ),
                    const SizedBox(height: 24),
                    // Kinetix branding text with smooth animation
                    ShaderMask(
                      shaderCallback: (bounds) => AppGradients.primary.createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      child: Text(
                        'KINETIX',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: Colors.white,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 700.ms, delay: 100.ms, curve: Curves.easeOutCubic)
                        .slideY(begin: -0.3, end: 0, duration: 700.ms, delay: 100.ms, curve: Curves.easeOutCubic),
                    const SizedBox(height: 32),
                    // Trainer avatars with smooth animation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TrainerAvatar(
                          image: AppAssets.trainerMilan,
                          theme: TrainerTheme.milan,
                          size: MediaQuery.of(context).size.width * 0.18,
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 200.ms, curve: Curves.easeOutCubic)
                            .scale(begin: const Offset(0.8, 0.8), duration: 800.ms, delay: 200.ms, curve: Curves.easeOutCubic),
                        const SizedBox(width: 32),
                        TrainerAvatar(
                          image: AppAssets.trainerAca,
                          theme: TrainerTheme.aca,
                          size: MediaQuery.of(context).size.width * 0.18,
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 400.ms, curve: Curves.easeOutCubic)
                            .scale(begin: const Offset(0.8, 0.8), duration: 800.ms, delay: 400.ms, curve: Curves.easeOutCubic),
                      ],
                    ),
                    const SizedBox(height: 48),
                    
                    // Login Card with smooth entrance animation
                    GradientCard(
                      gradient: AppGradients.card,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome Back',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 600.ms, curve: Curves.easeOutCubic)
                              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 600.ms, curve: Curves.easeOutCubic),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 700.ms, curve: Curves.easeOutCubic)
                              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 700.ms, curve: Curves.easeOutCubic),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: AppColors.textSecondary),
                              prefixIcon: const Icon(Icons.email_rounded, color: AppColors.primary),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 800.ms, curve: Curves.easeOutCubic)
                              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 800.ms, curve: Curves.easeOutCubic),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: AppColors.textPrimary),
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: AppColors.textSecondary),
                              prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primary),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 900.ms, curve: Curves.easeOutCubic)
                              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 900.ms, curve: Curves.easeOutCubic),
                          const SizedBox(height: 32),
                          NeonButton(
                            text: 'Login',
                            icon: Icons.login_rounded,
                            onPressed: authState.isLoading ? null : _handleLogin,
                            isLoading: authState.isLoading,
                            gradient: AppGradients.primary,
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 1000.ms, curve: Curves.easeOutCubic)
                              .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 1000.ms, curve: Curves.easeOutCubic),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 500.ms, curve: Curves.easeOutCubic)
                        .scale(begin: const Offset(0.95, 0.95), duration: 800.ms, delay: 500.ms, curve: Curves.easeOutCubic),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Full-screen overlay for login process
            AnimatedOpacity(
              opacity: authState.isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: authState.isLoading
                  ? IgnorePointer(
                      ignoring: !authState.isLoading,
                      child: AuthOverlay(
                        key: const ValueKey('login_overlay'),
                        statusText: 'Signing in...',
                        loaderSize: 80,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

