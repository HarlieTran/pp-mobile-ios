import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/global_header.dart';
import '../../pantry/providers/pantry_provider.dart';
import '../../pantry/models/pantry_models.dart';
import '../../planner/providers/planner_provider.dart';
import '../../planner/models/planner_models.dart';
import '../../recipes/providers/recipes_provider.dart';

/// Feature: 3.3 Dashboard — Central hub
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(pantryProvider.notifier).fetchItems();
      ref.read(plannerProvider.notifier).fetchPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pantryState = ref.watch(pantryProvider);
    final planState = ref.watch(plannerProvider);
    final recipesState = ref.watch(recipeSuggestionsProvider('All'));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildEfficiencyCard(pantryState),
            const SizedBox(height: 32),
            _buildExpiringSoon(pantryState),
            const SizedBox(height: 40),
            _buildTodaysPlan(planState),
            const SizedBox(height: 48),
            _buildCuratedRecipes(recipesState),
            const SizedBox(height: 48),
            _buildPantryMagic(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader() {
    return const GlobalHeader(title: 'My kitchen');
  }

  Widget _buildEfficiencyCard(AsyncValue<List<PantryItem>> pantryState) {
    int total = 0;
    int expiring = 0;
    int optimizedPct = 0;

    pantryState.whenData((items) {
      total = items.length;
      expiring = items.where((i) => i.expiryStatus == ExpiryStatus.expiringSoon || i.expiryStatus == ExpiryStatus.expired).length;
      optimizedPct = total == 0 ? 0 : (((total - expiring) / total) * 100).round();
    });

    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D5C3E), // Dark green from mockup
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF006241).withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Efficiency level',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Executive chef',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                // Toggle Week/Month/All
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    children: [
                      _buildToggleTab('Week', true),
                      _buildToggleTab('Month', false),
                      _buildToggleTab('All', false),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '12',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ITEMS UTILIZED',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '0.8 kg',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'FOOD WASTE SAVED',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '450 / 3000 exp',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Progress bar
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: total == 0 ? 0.15 : (optimizedPct / 100).clamp(0.15, 1.0), // Min 15% to show some progress like mockup
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isSelected ? const Color(0xFF0D5C3E) : Colors.white,
        ),
      ),
    );
  }

  Widget _buildExpiringSoon(AsyncValue<List<PantryItem>> pantryState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Expiring soon',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/pantry'),
                child: Row(
                  children: [
                    Text(
                      'Manage',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0D5C3E),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF0D5C3E)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: pantryState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
            data: (items) {
              final expiring = items.where((i) => i.expiryStatus == ExpiryStatus.expiringSoon || i.expiryStatus == ExpiryStatus.expired).toList();
              expiring.sort((a, b) => (a.daysUntilExpiry ?? 999).compareTo(b.daysUntilExpiry ?? 999));

              if (expiring.isEmpty) {
                return Center(
                  child: Text(
                    'All items are fresh!',
                    style: GoogleFonts.outfit(color: AppColors.textHint, fontWeight: FontWeight.w500),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: expiring.length,
                separatorBuilder: (_, __) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final item = expiring[index];
                  final isExpired = item.expiryStatus == ExpiryStatus.expired;
                  final isSoon = item.daysUntilExpiry != null && item.daysUntilExpiry! <= 3;
                  final color = isExpired ? AppColors.error : (isSoon ? const Color(0xFFFF5252) : const Color(0xFF0D5C3E));
                  
                  // Simple emoji mapping for mockup look
                  String emoji = '🥫';
                  final name = item.rawName.toLowerCase();
                  if (name.contains('milk')) emoji = '🥛';
                  else if (name.contains('spinach') || name.contains('lettuce')) emoji = '🥬';
                  else if (name.contains('avocado')) emoji = '🥑';
                  else if (name.contains('chicken') || name.contains('poultry')) emoji = '🍗';
                  else if (name.contains('egg')) emoji = '🥚';
                  else if (name.contains('cheese')) emoji = '🧀';
                  else if (name.contains('apple')) emoji = '🍎';

                  String timeStr = isExpired ? 'Expired' : (item.daysUntilExpiry == 0 ? 'Today' : '${item.daysUntilExpiry}d left');
                  if (!isExpired && !isSoon) timeStr = 'Fresh';

                  return Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(4), // p-1 equivalent
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2), // border-2
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF9FAFB), // bg-gray-50
                          ),
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 32)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          _capitalizeWords(item.rawName),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysPlan(AsyncValue<dynamic> planState) {
    int recipeCount = 0;
    if (planState.value != null) {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      recipeCount = (planState.value!.entries as List).where((e) => e.date == todayStr).length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's plan",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (recipeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F0E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$recipeCount recipe${recipeCount == 1 ? '' : 's'}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D5C3E),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        planState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox(),
          data: (plan) {
            final today = DateTime.now();
            final todayStr = DateFormat('yyyy-MM-dd').format(today);
            List entries = (plan.entries as List).where((e) => e.date == todayStr).toList();
            
            if (entries.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'No meals planned for today.',
                      style: GoogleFonts.outfit(color: AppColors.textHint, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _PlanEntryCard(entry: entry);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCuratedRecipes(AsyncValue<dynamic> recipesState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Curated for your pantry",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        recipesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox(),
          data: (recipes) {
            if (recipes.isEmpty) return const SizedBox();
            
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recipes.length > 2 ? 2 : recipes.length, // Show top 2 like mockup
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                
                return GestureDetector(
                  onTap: () => context.push('/recipes/${recipe.id}'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                              child: recipe.imageUrl != null
                                  ? CachedNetworkImage(imageUrl: recipe.imageUrl!, width: 128, height: 128, fit: BoxFit.cover)
                                  : Container(width: 128, height: 128, color: AppColors.surfaceTint),
                            ),
                            if (index == 0) // Chef's pick tag
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D5C3E),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "CHEF'S PICK",
                                    style: GoogleFonts.outfit(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.title,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            '${recipe.readyInMinutes ?? 20} min',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textHint,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: const BoxDecoration(
                                              color: AppColors.border,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '4 items in stock', // Mocked as requested
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF0D5C3E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(LucideIcons.play, color: Color(0xFF0D5C3E), size: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPantryMagic() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F0EB), // Beige background from mockup
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -40,
                bottom: -40,
                child: Transform.rotate(
                  angle: 0.2,
                  child: Icon(
                    LucideIcons.chefHat,
                    size: 160,
                    color: const Color(0xFF0D5C3E).withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                right: 24,
                top: 48,
                child: Icon(
                  LucideIcons.sparkles,
                  size: 40,
                  color: const Color(0xFF8BAA9E),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pantry magic',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 180,
                      child: Text(
                        'Let our AI chef browse your fridge and create the perfect menu.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/recipes/ai-chef'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D5C3E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Start AI chef',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.sparkle, size: 16),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
}

  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class _PlanEntryCard extends StatefulWidget {
  final MealPlanEntry entry;
  const _PlanEntryCard({required this.entry});

  @override
  State<_PlanEntryCard> createState() => _PlanEntryCardState();
}

class _PlanEntryCardState extends State<_PlanEntryCard> {
  bool isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/planner'),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.entry.imageUrl != null 
                    ? CachedNetworkImage(imageUrl: widget.entry.imageUrl!, width: 80, height: 80, fit: BoxFit.cover)
                    : Container(width: 80, height: 80, color: AppColors.surfaceTint),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.entry.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isCompleted ? AppColors.textHint : AppColors.textPrimary,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Planned',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                          ),
                        ),
                        Text(
                          '  •  ${widget.entry.readyInMinutes ?? 20} min',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  isCompleted = !isCompleted;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Icon(
                  isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  color: isCompleted ? const Color(0xFF0D5C3E) : AppColors.border,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
