import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/router/shell_scaffold.dart';
import '../../planner/providers/planner_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/recipes_provider.dart';
import '../models/recipe_models.dart';

/// Feature: 3.6 Recipe Detail — Full recipe view with cook action
class RecipeDetailScreen extends ConsumerWidget {
  final int recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));
    final plannerAsync = ref.watch(plannerProvider);
    final isPlanned = plannerAsync.valueOrNull?.entries.any((item) => item.recipeId == recipeId) ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Error loading recipe')),
        data: (recipe) {
          return CustomScrollView(
            slivers: [
              // Hero image with overlaid icons and bottom rounded corner
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: const Color(0xFF006241),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 18),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.share2, color: Colors.white, size: 18),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sharing recipe...', style: GoogleFonts.outfit()),
                            backgroundColor: const Color(0xFF006241),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      recipe.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: recipe.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.surfaceTint,
                                child: const Center(
                                  child: Icon(LucideIcons.imageOff, size: 48, color: AppColors.textHint),
                                ),
                              ),
                              imageBuilder: (context, imageProvider) => Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Transform.scale(
                                  scale: 1.08,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(color: AppColors.surfaceTint),
                      // Top gradient for white icons visibility
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 120,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      // Bottom gradient for smooth transition
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(32),
                  child: Container(
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    // Swipe handle bar at the top of the white background
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        recipe.title,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E1E1E),
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Summary
                      Text(
                        recipe.summary?.replaceAll(RegExp(r'<[^>]*>'), '').split('.').first ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Stats Row — colorful pills
                      Row(
                        children: [
                          _StatPill(
                            icon: LucideIcons.utensils,
                            text: '${recipe.servings ?? 4} Servings',
                            bgColor: const Color(0xFFF4F8F2),
                            iconColor: const Color(0xFF006241),
                            textColor: const Color(0xFF006241),
                          ),
                          const SizedBox(width: 8),
                          _StatPill(
                            icon: LucideIcons.clock,
                            text: '${recipe.readyInMinutes ?? 45} min',
                            bgColor: const Color(0xFFFFF7ED),
                            iconColor: const Color(0xFFF97316),
                            textColor: const Color(0xFFEA580C),
                          ),
                          const SizedBox(width: 8),
                          const _StatPill(
                            icon: LucideIcons.flame,
                            text: '720 kcal',
                            bgColor: Color(0xFFFEF2F2),
                            iconColor: Color(0xFFEF4444),
                            textColor: Color(0xFFDC2626),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Ingredients section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F8F2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(LucideIcons.list, size: 16, color: Color(0xFF006241)),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Ingredients',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E1E1E),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4E9E2),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${recipe.ingredients.length} items',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF006241),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...recipe.ingredients.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF006241).withValues(alpha: 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${entry.value.amount != null ? '${entry.value.amount} ${entry.value.unit ?? ""} ' : ""}${entry.value.name}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF374151),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Instructions section
                      if (recipe.instructions.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF3F4F6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(LucideIcons.chefHat, size: 16, color: Color(0xFFF97316)),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Instructions',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E1E1E),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...recipe.instructions.asMap().entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF006241).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${entry.key + 1}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF006241),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            height: 1.5,
                                            color: const Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                try {
                                  if (isPlanned) {
                                    await ref.read(plannerProvider.notifier).removeRecipe(recipeId);
                                  } else {
                                    await ref.read(plannerProvider.notifier).addRecipe(recipeId);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isPlanned ? 'Removed from Meal Plan' : 'Added to Meal Plan', style: GoogleFonts.outfit()),
                                        backgroundColor: const Color(0xFF006241),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to add to Meal Plan', style: GoogleFonts.outfit()),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF006241),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF006241).withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.calendarPlus, size: 16, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      isPlanned ? 'Planned' : 'Add to Plan',
                                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => context.push('/recipes/$recipeId/cook', extra: recipe),
                              icon: const Icon(LucideIcons.flame, size: 16),
                              label: const Text('Cook Now'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF006241),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800),
                                elevation: 4,
                                shadowColor: const Color(0xFF004D33).withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (recipe.id >= 1500000000) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push('/recipes/ai-chef', extra: recipe.title);
                            },
                            icon: const Icon(LucideIcons.sparkles, size: 16),
                            label: Text(
                              'Generate another variation',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: recipeAsync.valueOrNull != null
          ? _BookmarkFab(recipe: recipeAsync.value!)
          : null,
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bgColor;
  final Color iconColor;
  final Color textColor;

  const _StatPill({
    required this.icon,
    required this.text,
    required this.bgColor,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkFab extends ConsumerStatefulWidget {
  final Recipe recipe;
  const _BookmarkFab({required this.recipe});

  @override
  ConsumerState<_BookmarkFab> createState() => _BookmarkFabState();
}

class _BookmarkFabState extends ConsumerState<_BookmarkFab> {
  Future<void> _toggle() async {
    try {
      await ref.read(savedRecipesProvider.notifier).toggleSave(widget.recipe);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save', style: GoogleFonts.outfit()), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedAsync = ref.watch(savedRecipesProvider);
    final savedRecipes = savedAsync.valueOrNull ?? [];
    final currentSaved = savedRecipes.any((r) => r.id == widget.recipe.id);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _toggle,
        icon: Icon(
          currentSaved ? Icons.favorite : Icons.favorite_border,
          color: const Color(0xFF006241),
          size: 28,
        ),
      ),
    );
  }
}
