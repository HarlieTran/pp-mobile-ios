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

CustomTransitionPage _fadeTransition(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
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
        return '/login';
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
        pageBuilder: (_, __) => _fadeTransition(const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, __) => _fadeTransition(const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (_, __) => _fadeTransition(const SignupScreen()),
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (_, state) => _fadeTransition(
          VerifyEmailScreen(email: state.extra as String? ?? ''),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, __) => _fadeTransition(const OnboardingScreen()),
      ),

      // ── Main app shell ──
      ShellRoute(
        builder: (_, __, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, __) => _fadeTransition(const HomeTab()),
          ),
          GoRoute(
            path: '/pantry',
            pageBuilder: (_, __) => _fadeTransition(const PantryScreen()),
            routes: [
              GoRoute(
                path: 'scan',
                pageBuilder: (_, __) => _fadeTransition(const ScanScreen()),
                routes: [
                  GoRoute(
                    path: 'review',
                    pageBuilder: (_, state) => _fadeTransition(
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
            pageBuilder: (_, __) => _fadeTransition(const RecipeFeedScreen()),
            routes: [
              GoRoute(
                path: 'ai-chef',
                pageBuilder: (_, state) => _fadeTransition(
                  AiChefScreen(initialQuery: state.extra as String?),
                ),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (_, state) => _fadeTransition(
                  RecipeDetailScreen(
                    recipeId: int.parse(state.pathParameters['id']!),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'cook',
                    pageBuilder: (_, state) => _fadeTransition(
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
            pageBuilder: (_, __) => _fadeTransition(const ProfileDetailsScreen()),
          ),
          GoRoute(
            path: '/preferences',
            pageBuilder: (_, __) => _fadeTransition(const PreferencesScreen()),
          ),
          GoRoute(
            path: '/favourites',
            pageBuilder: (_, __) => _fadeTransition(const FavouritesScreen()),
          ),
          GoRoute(
            path: '/planner',
            pageBuilder: (_, __) => _fadeTransition(const PlannerScreen()),
          ),
        ],
      ),
    ],
  );
}
