import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/recipes_provider.dart';

/// Feature: 3.6 Recipe Detail — Full recipe view with cook action
class RecipeDetailScreen extends ConsumerWidget {
  final int recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));

    return Scaffold(
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) {
          print('Error loading recipe: $e\n$stack');
          return Center(child: Text('Error loading recipe'));
        },
        data: (recipe) {
          return CustomScrollView(
            slivers: [
              // Hero image
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      onPressed: () {
                        ref.read(recipesServiceProvider).toggleSave(recipeId);
                      },
                      icon: Icon(
                        recipe.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 22,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: recipe.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: recipe.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.surfaceTint,
                          child: const Center(
                            child: Icon(Icons.restaurant,
                                size: 64, color: AppColors.textHint),
                          ),
                        ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        recipe.title,
                        style: TextStyle(fontFamily: 'Matter', 
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Meta chips
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          if (recipe.readyInMinutes != null)
                            _MetaChip(
                              icon: Icons.schedule_rounded,
                              label: '${recipe.readyInMinutes} min',
                            ),
                          if (recipe.servings != null)
                            _MetaChip(
                              icon: Icons.people_outline_rounded,
                              label: '${recipe.servings} servings',
                            ),
                          if (recipe.source != null)
                            _MetaChip(
                              icon: recipe.source == 'ai'
                                  ? Icons.auto_awesome
                                  : Icons.public,
                              label: recipe.source == 'ai' ? 'AI Chef' : 'Spoonacular',
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Ingredients
                      Text(
                        'Ingredients',
                        style: TextStyle(fontFamily: 'Matter', 
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...recipe.ingredients.map(
                        (ing) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                height: 8,
                                width: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${ing.name}${ing.amount != null ? ' — ${ing.amount} ${ing.unit ?? ""}' : ""}',
                                  style: TextStyle(fontFamily: 'Matter', 
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Instructions
                      if (recipe.instructions.isNotEmpty) ...[
                        Text(
                          'Instructions',
                          style: TextStyle(fontFamily: 'Matter', 
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...recipe.instructions.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 28,
                                  width: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: TextStyle(fontFamily: 'Matter', 
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(fontFamily: 'Matter', 
                                      fontSize: 15,
                                      height: 1.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.local_fire_department_rounded),
        label: Text(
          'Cook Now',
          style: TextStyle(fontFamily: 'Matter', fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontFamily: 'Matter', 
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
