import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

/// Feature: 3.8 Favourites & Profile — Profile screen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).fetchProfile());
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceTint,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  Text(
                    'Profile',
                    style: TextStyle(fontFamily: 'Matter', 
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceTint,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Avatar & Name
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 88,
                      width: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    profileState.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => Text(
                        'User',
                        style: TextStyle(fontFamily: 'Matter', 
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      data: (profile) => Column(
                        children: [
                          Text(
                            profile.displayName ?? 'PantryPal User',
                            style: TextStyle(fontFamily: 'Matter', 
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (profile.email != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              profile.email!,
                              style: TextStyle(fontFamily: 'Matter', 
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Preferences
              profileState.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (profile) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dietary Preferences',
                      style: TextStyle(fontFamily: 'Matter', 
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (profile.dietType.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.dietType
                            .map((d) => _Tag(label: d, color: AppColors.primary))
                            .toList(),
                      )
                    else
                      Text(
                        'No preferences set',
                        style: TextStyle(fontFamily: 'Matter', 
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                      ),
                    const SizedBox(height: 24),

                    Text(
                      'Allergies',
                      style: TextStyle(fontFamily: 'Matter', 
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (profile.allergies.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.allergies
                            .map((a) => _Tag(label: a, color: AppColors.accent))
                            .toList(),
                      )
                    else
                      Text(
                        'No allergies listed',
                        style: TextStyle(fontFamily: 'Matter', 
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Menu Items
              _MenuItem(
                icon: Icons.bookmark_outline_rounded,
                label: 'Saved Recipes',
                onTap: () => context.go('/favourites'),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.calendar_today_outlined,
                label: 'Meal Planner',
                onTap: () => context.go('/planner'),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.tune_rounded,
                label: 'Re-take Onboarding',
                onTap: () => context.go('/onboarding'),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'App Settings',
                onTap: () {},
              ),
              const SizedBox(height: 24),

              // Logout
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).signOut();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(
                    'Sign Out',
                    style: TextStyle(fontFamily: 'Matter', fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'Matter', 
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontFamily: 'Matter', 
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
