import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/pantry/screens/pantry_screen.dart';
import '../../features/pantry/screens/scan_screen.dart';
import '../../features/pantry/screens/scan_review_screen.dart';
import '../../features/pantry/models/pantry_models.dart';
import '../../features/recipes/screens/recipe_feed_screen.dart';
import '../../features/recipes/screens/recipe_detail_screen.dart';
import '../../features/recipes/screens/cook_screen.dart';
import '../../features/recipes/screens/ai_chef_screen.dart';
import '../../features/recipes/models/recipe_models.dart';
import '../../features/planner/screens/planner_screen.dart';
import '../../features/profile/screens/profile_details_screen.dart';
import '../../features/profile/screens/preferences_screen.dart';
import '../../features/profile/screens/favourites_screen.dart';
import 'shell_scaffold.dart';

CustomTransitionPage _fadeSlideTransition(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: const Duration(milliseconds: 600),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
  );
}

/// ──────────────────────────────────────────────
/// App Router — Enhanced with ShellRoute + Auth Guard
/// Mirrors: enhancement.md specification
/// ──────────────────────────────────────────────

GoRouter appRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authed = ref.read(authProvider).isAuthenticated;
      const publicPaths = [
        '/splash',
        '/login',
        '/signup',
        '/verify-email',
        '/onboarding',
      ];
      if (!authed && !publicPaths.contains(state.matchedLocation)) {
        return '/splash';
      }
      if (authed && state.matchedLocation == '/login') {
        return '/';
      }
      return null;
    },
    routes: [
      // ── Public routes ──
      GoRoute(
        path: '/splash',
        pageBuilder: (_, __) => _fadeSlideTransition(const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, __) => _fadeSlideTransition(const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (_, __) => _fadeSlideTransition(const SignupScreen()),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (_, state) => _fadeSlideTransition(
          VerifyEmailScreen(email: state.extra as String? ?? ''),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, __) => _fadeSlideTransition(const OnboardingScreen()),
      ),

      // ── Main app shell ──
      ShellRoute(
        builder: (_, __, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, __) => _fadeSlideTransition(const HomeTab()),
          ),
          GoRoute(
            path: '/pantry',
            pageBuilder: (_, __) => _fadeSlideTransition(const PantryScreen()),
            routes: [
              GoRoute(
                path: 'scan',
                pageBuilder: (_, __) => _fadeSlideTransition(const ScanScreen()),
                routes: [
                  GoRoute(
                    path: 'review',
                    pageBuilder: (_, state) => _fadeSlideTransition(
                      ScanReviewScreen(
                        items: state.extra as List<ParsedIngredient>,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/recipes',
            pageBuilder: (_, __) => _fadeSlideTransition(const RecipeFeedScreen()),
            routes: [
              GoRoute(
                path: 'ai-chef',
                pageBuilder: (_, state) => _fadeSlideTransition(
                  AiChefScreen(initialQuery: state.extra as String?),
                ),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (_, state) => _fadeSlideTransition(
                  RecipeDetailScreen(
                    recipeId: int.parse(state.pathParameters['id']!),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'cook',
                    pageBuilder: (_, state) => _fadeSlideTransition(
                      CookScreen(
                        recipe: state.extra as RecipeDetail,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/profile-details',
            pageBuilder: (_, __) => _fadeSlideTransition(const ProfileDetailsScreen()),
          ),
          GoRoute(
            path: '/preferences',
            pageBuilder: (_, __) => _fadeSlideTransition(const PreferencesScreen()),
          ),
          GoRoute(
            path: '/favourites',
            pageBuilder: (_, __) => _fadeSlideTransition(const FavouritesScreen()),
          ),
          GoRoute(
            path: '/planner',
            pageBuilder: (_, __) => _fadeSlideTransition(const PlannerScreen()),
          ),
        ],
      ),
    ],
  );
}
