import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/pantry/screens/pantry_screen.dart';
import '../../features/pantry/screens/scan_screen.dart';
import '../../features/recipes/screens/recipe_feed_screen.dart';
import '../../features/recipes/screens/recipe_detail_screen.dart';
import '../../features/planner/screens/planner_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/favourites_screen.dart';

/// ──────────────────────────────────────────────
/// App Router
/// Mirrors: pp-backend modules/api/routes/router.ts
/// Centralized route definitions
/// ──────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // ── Auth ──
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),

    // ── Onboarding ──
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

    // ── Main App (Shell) ──
    GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/pantry', builder: (_, __) => const PantryScreen()),
    GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),
    GoRoute(
      path: '/recipes',
      builder: (_, __) => const RecipeFeedScreen(),
    ),
    GoRoute(
      path: '/recipes/:id',
      builder: (context, state) => RecipeDetailScreen(
        recipeId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(path: '/planner', builder: (_, __) => const PlannerScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/favourites', builder: (_, __) => const FavouritesScreen()),
  ],
);
