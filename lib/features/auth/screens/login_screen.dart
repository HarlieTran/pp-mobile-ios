import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

enum LoginState { splash, landing, form }

/// Feature: 3.1 Landing & Auth — Login Screen
/// Design: Cinematic video background with multi-stage animation
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late VideoPlayerController _videoController;
  
  LoginState _loginState = LoginState.splash;

  // Animations
  late AnimationController _landingController;
  late Animation<double> _landingFadeAnimation;
  
  late AnimationController _formController;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    
    // Video Setup
    _videoController = VideoPlayerController.asset('assets/videos/landing_bg.mp4')
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
        setState(() {}); // trigger rebuild to show video
      });

    // Landing setup
    _landingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _landingFadeAnimation = CurvedAnimation(parent: _landingController, curve: Curves.easeIn);

    // Form setup
    _formController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _formFadeAnimation = CurvedAnimation(parent: _formController, curve: Curves.easeOut);
    _formSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic));

    // Start Sequence
    _startSequence();

    // Check auth status right away (e.g., after hot restart)
    Future.microtask(() => ref.read(authProvider.notifier).checkAuthStatus());
  }

  void _startSequence() async {
    // Stage 1: Splash (0-3s)
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    
    // Stage 2: Landing
    setState(() => _loginState = LoginState.landing);
    _landingController.forward();
  }

  void _showForm() {
    // Stage 3: Form
    if (_loginState == LoginState.form) return;
    
    _landingController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _loginState = LoginState.form);
      _formController.forward();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _landingController.dispose();
    _formController.dispose();
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Video Background
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
            
          // 2. Dark Overlay
          Container(
            color: Colors.black.withValues(alpha: 0.55), // Darkened for text legibility
          ),
          
          // 3. Main Content
          SafeArea(
            child: Stack(
              children: [
                // Animated Logo
                AnimatedAlign(
                  alignment: _loginState == LoginState.splash 
                      ? Alignment.center 
                      : Alignment.topCenter,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOutCubic,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeInOutCubic,
                          height: _loginState == LoginState.splash ? 64 : 42,
                          width: _loginState == LoginState.splash ? 64 : 42,
                          child: SvgPicture.asset(
                            'assets/images/app-logo.svg',
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeInOutCubic,
                          style: TextStyle(
                            fontFamily: 'Matter',
                            fontSize: _loginState == LoginState.splash ? 26 : 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                          child: const Text('PantryPal'),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Landing Buttons
                if (_loginState != LoginState.splash && _loginState != LoginState.form)
                  Positioned(
                    bottom: 48,
                    left: 28,
                    right: 28,
                    child: FadeTransition(
                      opacity: _landingFadeAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AuthSubmitButton(
                            label: 'Log In',
                            isPrimary: true,
                            onTap: _showForm,
                          ),
                          const SizedBox(height: 16),
                          _AuthSubmitButton(
                            label: 'Create Account',
                            isPrimary: false,
                            onTap: () => context.go('/signup'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                // Login Form
                if (_loginState == LoginState.form)
                  Positioned.fill(
                    child: FadeTransition(
                      opacity: _formFadeAnimation,
                      child: SlideTransition(
                        position: _formSlideAnimation,
                        child: Theme(
                          data: ThemeData.dark().copyWith(
                            inputDecorationTheme: InputDecorationTheme(
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.3),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white30),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white30),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white),
                              ),
                              hintStyle: const TextStyle(color: Colors.white54, fontFamily: 'Matter'),
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 160), // Push down below logo
                                
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
                                    color: Colors.white,
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
                                    color: Colors.white70,
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
                                    fontSize: 15,
                                    color: Colors.white,
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
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    suffixIcon: GestureDetector(
                                      onTap: () =>
                                          setState(() => _obscurePassword = !_obscurePassword),
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: Text(
                                          _obscurePassword ? 'Show' : 'Hide',
                                          style: const TextStyle(
                                            fontFamily: 'Matter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
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
                                      color: AppColors.destructive.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      authState.errorMessage!,
                                      style: const TextStyle(
                                        fontFamily: 'Matter',
                                        color: Color(0xFFFFB4AB), // Lighter red for dark mode
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),

                                // Primary submit
                                _AuthSubmitButton(
                                  label: 'Sign In',
                                  isPrimary: true,
                                  isLoading: authState.isLoading,
                                  onTap: () => ref.read(authProvider.notifier).signIn(
                                        _emailController.text.trim(),
                                        _passwordController.text,
                                      ),
                                ),
                                const SizedBox(height: 48), // Padding at bottom
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Back button for Form view
          if (_loginState == LoginState.form)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              left: 16,
              child: FadeTransition(
                opacity: _formFadeAnimation,
                child: IconButton(
                  onPressed: () {
                    // Go back to landing state
                    _formController.reverse().then((_) {
                      if (!mounted) return;
                      setState(() => _loginState = LoginState.landing);
                      _landingController.forward();
                    });
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Auth label ──
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
        color: Colors.white70,
      ),
    );
  }
}

// ── Auth submit button ──
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
          color: isPrimary ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isPrimary ? AppColors.primary : Colors.white,
            width: isPrimary ? 1 : 1.5,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isPrimary ? AppColors.foreground : Colors.white,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontFamily: 'Matter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? AppColors.foreground : Colors.white,
                ),
              ),
      ),
    );
  }
}
