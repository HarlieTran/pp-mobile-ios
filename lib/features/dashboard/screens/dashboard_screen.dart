import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../pantry/providers/pantry_provider.dart';
import '../../pantry/models/pantry_models.dart';
import '../../pantry/widgets/expiry_tag.dart';

/// Feature: 3.3 Dashboard — Central hub
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(pantryProvider.notifier).fetchItems());
  }

  @override
  Widget build(BuildContext context) {
    final pantryState = ref.watch(pantryProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _DashboardHome(pantryState: pantryState),
          const _PantryTabPlaceholder(),
          const _RecipesTabPlaceholder(),
          const _ProfileTabPlaceholder(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) {
          if (i == 1) { context.go('/pantry'); return; }
          if (i == 2) { context.go('/recipes'); return; }
          if (i == 3) { context.go('/profile'); return; }
          setState(() => _currentTab = i);
        },
        backgroundColor: AppColors.surface,
        elevation: 8,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen_rounded),
            label: 'Pantry',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded),
            label: 'Recipes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final AsyncValue<List<PantryItem>> pantryState;
  const _DashboardHome({required this.pantryState});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: topPadding + 32, // Simplified logic
        left: 24,
        right: 24,
        bottom: 48,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good evening! 👋',
                    style: TextStyle(fontFamily: 'Matter', 
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your Awesome Kitchen',
                    style: TextStyle(fontFamily: 'Matter', 
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.document_scanner_outlined,
                  label: 'Scan Receipt',
                  color: AppColors.accent,
                  onTap: () => context.go('/scan'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI Chef',
                  color: AppColors.primary,
                  onTap: () => context.go('/recipes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Expiring Soon
          Text(
            'Expiring Soon',
            style: TextStyle(fontFamily: 'Matter', 
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          pantryState.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Text('Could not load pantry', style: TextStyle(color: AppColors.textHint)),
            ),
            data: (items) {
              final expiring = items
                  .where((i) =>
                      i.expiryStatus == ExpiryStatus.expiringSoon ||
                      i.expiryStatus == ExpiryStatus.expired)
                  .take(6)
                  .toList();

              if (expiring.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'All items are fresh! Nothing expiring soon.',
                          style: TextStyle(fontFamily: 'Matter', 
                            fontSize: 14,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: expiring.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final item = expiring[i];
                    return Container(
                      width: 130,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.rawName,
                            style: TextStyle(fontFamily: 'Matter', 
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          ExpiryTag(
                            status: item.expiryStatus,
                            daysUntilExpiry: item.daysUntilExpiry,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // Pantry Summary
          Text(
            'Pantry Overview',
            style: TextStyle(fontFamily: 'Matter', 
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          pantryState.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) {
              return Row(
                children: [
                  _StatCard(
                    count: items.length.toString(),
                    label: 'Total Items',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 14),
                  _StatCard(
                    count: items
                        .where((i) => i.expiryStatus == ExpiryStatus.fresh)
                        .length
                        .toString(),
                    label: 'Fresh',
                    icon: Icons.eco_outlined,
                    color: AppColors.expiryFresh,
                  ),
                  const SizedBox(width: 14),
                  _StatCard(
                    count: items
                        .where((i) => i.expiryStatus == ExpiryStatus.expired)
                        .length
                        .toString(),
                    label: 'Expired',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.expiryExpired,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(fontFamily: 'Matter', 
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(fontFamily: 'Matter', 
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontFamily: 'Matter', 
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder tabs for IndexedStack
class _PantryTabPlaceholder extends StatelessWidget {
  const _PantryTabPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Pantry'));
}

class _RecipesTabPlaceholder extends StatelessWidget {
  const _RecipesTabPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Recipes'));
}

class _ProfileTabPlaceholder extends StatelessWidget {
  const _ProfileTabPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Profile'));
}
