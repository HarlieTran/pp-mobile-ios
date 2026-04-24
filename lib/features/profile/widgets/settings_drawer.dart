import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/waving_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class SettingsDrawer extends ConsumerWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);
    
    final profileName = profileState.valueOrNull?.displayName;
    final email = authState.email ?? 'Guest User';
    
    String displayName = 'Guest';
    if (profileName != null && profileName.isNotEmpty) {
      displayName = profileName;
    } else if (authState.email != null) {
      final name = authState.email!.split('@').first.replaceAll(RegExp(r'[0-9]'), '');
      if (name.isNotEmpty) {
        displayName = name[0].toUpperCase() + name.substring(1);
      }
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            // Header Profile Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: WavingAvatar(
                      radius: 36,
                      onTap: () {
                        context.pop();
                        context.push('/profile-details');
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, thickness: 1, color: AppColors.surfaceTint),
            
            // Drawer Menu Items
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: [
                        _DrawerItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Profile Details',
                          onTap: () {
                            context.pop(); // close drawer
                            context.push('/profile-details');
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.favorite_border_rounded,
                          title: 'Saved Recipes',
                          onTap: () {
                            context.pop();
                            context.push('/favourites');
                          },
                        ),
                        _DrawerItem(
                          icon: Icons.settings_outlined,
                          title: 'Preferences',
                          onTap: () {
                            context.pop();
                            context.push('/preferences');
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.surfaceTint),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: _DrawerItem(
                        icon: Icons.logout_rounded,
                        title: 'Log out',
                        textColor: AppColors.error,
                        iconColor: AppColors.error,
                        onTap: () async {
                          context.pop();
                          await ref.read(authProvider.notifier).signOut();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 24),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      onTap: onTap,
    );
  }
}
