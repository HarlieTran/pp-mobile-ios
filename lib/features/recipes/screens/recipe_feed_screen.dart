import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/recipes_provider.dart';
import '../models/recipe_models.dart';

/// Feature: 3.6 Recipe Suggestions & AI Chef — Feed
class RecipeFeedScreen extends ConsumerStatefulWidget {
  const RecipeFeedScreen({super.key});

  @override
  ConsumerState<RecipeFeedScreen> createState() => _RecipeFeedScreenState();
}

class _RecipeFeedScreenState extends ConsumerState<RecipeFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(recipeSuggestionsProvider);

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
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceTint,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  Text(
                    'Recipes',
                    style: TextStyle(fontFamily: 'Matter', 
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go('/favourites'),
                    icon: const Icon(Icons.bookmark_outline_rounded, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceTint,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search recipes...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textHint,
                  labelStyle: TextStyle(fontFamily: 'Matter', 
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  dividerHeight: 0,
                  tabs: const [
                    Tab(text: 'Pantry Matches'),
                    Tab(text: 'AI Creations'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pantry Matches
                  suggestions.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text('Could not load recipes',
                          style: TextStyle(fontFamily: 'Matter', color: AppColors.textHint)),
                    ),
                    data: (recipes) => _RecipeGrid(recipes: recipes),
                  ),

                  // AI Creations
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 48,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'AI Chef',
                          style: TextStyle(fontFamily: 'Matter', 
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Generate unique recipes from\nyour pantry ingredients',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Matter', 
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                          label: Text(
                            'Generate Recipes',
                            style: TextStyle(fontFamily: 'Matter', fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                          ),
                        ),
                      ],
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

class _RecipeGrid extends StatelessWidget {
  final List<Recipe> recipes;
  const _RecipeGrid({required this.recipes});

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_outlined,
                size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No recipes found',
              style: TextStyle(fontFamily: 'Matter', fontSize: 16, color: AppColors.textHint),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to your pantry first',
              style: TextStyle(fontFamily: 'Matter', fontSize: 14, color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: recipes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final recipe = recipes[i];
        return GestureDetector(
          onTap: () {
            print('Tapped recipe: ${recipe.id}');
            context.push('/recipes/${recipe.id}');
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                if (recipe.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: recipe.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 180,
                      color: AppColors.surfaceTint,
                      child: const Center(
                        child: Icon(Icons.restaurant, color: AppColors.textHint),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 120,
                    color: AppColors.surfaceTint,
                    child: const Center(
                      child: Icon(Icons.restaurant, size: 40, color: AppColors.textHint),
                    ),
                  ),

                // Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.title,
                        style: TextStyle(fontFamily: 'Matter', 
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (recipe.readyInMinutes != null) ...[
                            Icon(Icons.schedule_rounded,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.readyInMinutes} min',
                              style: TextStyle(fontFamily: 'Matter', 
                                  fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                          if (recipe.servings != null) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.people_outline_rounded,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.servings} servings',
                              style: TextStyle(fontFamily: 'Matter', 
                                  fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                          const Spacer(),
                          Icon(
                            recipe.isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 22,
                            color: recipe.isSaved
                                ? AppColors.accent
                                : AppColors.textHint,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
