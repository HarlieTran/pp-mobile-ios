import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

/// Feature: 3.1 Landing & Auth — Login Screen
/// Design: mirrors pp-frontend LandingPage.tsx + auth styles
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (_, next) {
      if (next.isAuthenticated) context.go('/');
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                  const SizedBox(height: 56),

                  // Logo + Brand
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/app-logo.svg',
                        height: 32,
                        width: 32,
                        colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PantryPal',
                        style: TextStyle(
                          fontFamily: 'Matter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Eyebrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 7,
                        width: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'WELCOME BACK',
                        style: TextStyle(
                          fontFamily: 'Matter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Headline
                  const Text(
                    'Sign in to your\naccount',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Matter',
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      height: 0.95,
                      letterSpacing: -2.0,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Keep your pantry, recipes, and meal plans in sync.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Matter',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email
                  const _AuthLabel('Email'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontFamily: 'Matter',
                      fontSize: 14,
                      color: AppColors.foreground,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'hello@pantrypal.com',
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Password
                  const _AuthLabel('Password'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(
                      fontFamily: 'Matter',
                      fontSize: 14,
                      color: AppColors.foreground,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            _obscurePassword ? 'Show' : 'Hide',
                            style: const TextStyle(
                              fontFamily: 'Matter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                      ),
                      suffixIconConstraints:
                          const BoxConstraints(minHeight: 0, minWidth: 0),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error
                  if (authState.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.destructive.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        authState.errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'Matter',
                          color: AppColors.destructive,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  // Primary submit — matches auth-submit--primary
                  _AuthSubmitButton(
                    label: 'Sign In',
                    isPrimary: true,
                    isLoading: authState.isLoading,
                    onTap: () => ref.read(authProvider.notifier).signIn(
                          _emailController.text.trim(),
                          _passwordController.text,
                        ),
                  ),
                  const SizedBox(height: 20),
                  // Don't have an account? Sign up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontFamily: 'Matter',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/signup'),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontFamily: 'Matter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
  }
}

// ── Auth label (mirrors .auth-label) ──
class _AuthLabel extends StatelessWidget {
  final String text;
  const _AuthLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Matter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ── Auth submit button (mirrors .auth-submit / .auth-submit--primary) ──
class _AuthSubmitButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback onTap;

  const _AuthSubmitButton({
    required this.label,
    required this.isPrimary,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isPrimary ? AppColors.primary : AppColors.border,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isPrimary ? AppColors.foreground : AppColors.primary,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontFamily: 'Matter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isPrimary ? AppColors.foreground : AppColors.foreground,
                ),
              ),
      ),
    );
  }
}
