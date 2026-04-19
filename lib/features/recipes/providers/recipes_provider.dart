import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe_models.dart';
import '../services/recipes_service.dart';

/// ──────────────────────────────────────────────
/// Recipes Provider
/// Mirrors: pp-frontend recipesSlice + favoritesSlice
/// ──────────────────────────────────────────────

final recipesServiceProvider = Provider((_) => RecipesService());

// ── Suggestions ──

final recipeSuggestionsProvider =
    FutureProvider<List<Recipe>>((ref) async {
  final service = ref.read(recipesServiceProvider);
  return service.fetchSuggestions();
});

// ── Recipe Detail ──

final recipeDetailProvider =
    FutureProvider.family<RecipeDetail, int>((ref, id) async {
  final service = ref.read(recipesServiceProvider);
  return service.fetchRecipeDetail(id);
});

// ── Search ──

final recipeSearchProvider =
    FutureProvider.family<List<Recipe>, String>((ref, query) async {
  final service = ref.read(recipesServiceProvider);
  return service.searchRecipes(query);
});

// ── Saved / Favourites ──

final savedRecipesProvider =
    FutureProvider<List<Recipe>>((ref) async {
  final service = ref.read(recipesServiceProvider);
  return service.fetchSavedRecipes();
});
