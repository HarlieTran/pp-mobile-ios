import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../recipes/providers/recipes_provider.dart';

/// Feature: 3.8 Favourites — Saved recipes grid
class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedRecipesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceTint,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  Text(
                    'Saved Recipes',
                    style: TextStyle(fontFamily: 'Matter', 
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: savedAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Failed to load favourites',
                      style: TextStyle(fontFamily: 'Matter', color: AppColors.textHint)),
                ),
                data: (recipes) {
                  if (recipes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_outline_rounded,
                              size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No saved recipes yet',
                            style: TextStyle(fontFamily: 'Matter', 
                                fontSize: 16, color: AppColors.textHint),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the bookmark icon on any recipe to save it',
                            style: TextStyle(fontFamily: 'Matter', 
                                fontSize: 14, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: recipes.length,
                    itemBuilder: (context, i) {
                      final recipe = recipes[i];
                      return GestureDetector(
                        onTap: () => context.go('/recipes/${recipe.id}'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              Expanded(
                                flex: 3,
                                child: recipe.imageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: recipe.imageUrl!,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: AppColors.surfaceTint,
                                        child: const Center(
                                          child: Icon(Icons.restaurant,
                                              color: AppColors.textHint),
                                        ),
                                      ),
                              ),
                              // Info
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.title,
                                        style: TextStyle(fontFamily: 'Matter', 
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      if (recipe.readyInMinutes != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.schedule_rounded,
                                                size: 14, color: AppColors.textHint),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${recipe.readyInMinutes} min',
                                              style: TextStyle(fontFamily: 'Matter', 
                                                fontSize: 12,
                                                color: AppColors.textHint,
                                              ),
                                            ),
                                          ],
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
            ),
          ],
        ),
      ),
    );
  }
}
