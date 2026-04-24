import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../../features/profile/widgets/settings_drawer.dart';

final GlobalKey<ScaffoldState> shellScaffoldKey = GlobalKey<ScaffoldState>();

/// ──────────────────────────────────────────────
/// ShellScaffold
/// Persistent bottom NavigationBar + central Scan FAB
/// Wraps all main-app tab routes via ShellRoute
/// ──────────────────────────────────────────────

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  int _tabIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/pantry') && loc != '/pantry/scan' && !loc.startsWith('/pantry/scan/review')) return 1;
    if (loc.startsWith('/recipes')) return 2;
    if (loc.startsWith('/planner')) return 3;
    return 0; // Home
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _tabIndex(context);

    return Scaffold(
      key: shellScaffoldKey,
      drawer: const SettingsDrawer(),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavButton(
                icon: LucideIcons.chefHat,
                label: 'Kitchen',
                isActive: currentIndex == 0,
                onTap: () => context.go('/'),
              ),
              _NavButton(
                icon: LucideIcons.package,
                label: 'Pantry',
                isActive: currentIndex == 1,
                onTap: () => context.go('/pantry'),
              ),

              // Magic Button
              GestureDetector(
                onTap: () => context.push('/pantry/scan'),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryLight.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.scan, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),

              _NavButton(
                icon: LucideIcons.bookOpen,
                label: 'Recipes',
                isActive: currentIndex == 2,
                onTap: () => context.go('/recipes'),
              ),
              _NavButton(
                icon: LucideIcons.calendarDays,
                label: 'Planner',
                isActive: currentIndex == 3,
                onTap: () => context.go('/planner'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isActive ? 16 : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isActive ? 1.0 : 0.0,
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
