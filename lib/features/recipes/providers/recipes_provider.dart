import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pantry/providers/pantry_provider.dart';
import '../models/recipe_models.dart';
import '../services/recipes_service.dart';

/// ──────────────────────────────────────────────
/// Recipes Provider
/// Mirrors: pp-frontend recipesSlice + favoritesSlice
/// ──────────────────────────────────────────────

final recipesServiceProvider = Provider((_) => RecipesService());

// ── Suggestions ──

final recipeSuggestionsProvider =
    FutureProvider.family<List<Recipe>, String>((ref, filter) async {
  final service = ref.read(recipesServiceProvider);
  return service.fetchSuggestions(filter: filter);
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

class SavedRecipesNotifier extends AsyncNotifier<List<Recipe>> {
  @override
  Future<List<Recipe>> build() async {
    final service = ref.read(recipesServiceProvider);
    return service.fetchSavedRecipes();
  }

  Future<void> toggleSave(Recipe recipe) async {
    final service = ref.read(recipesServiceProvider);
    final previous = state.valueOrNull ?? [];
    final isSaved = previous.any((r) => r.id == recipe.id);
    
    // Optimistic update
    if (isSaved) {
      state = AsyncData(previous.where((r) => r.id != recipe.id).toList());
    } else {
      state = AsyncData([...previous, recipe]);
    }

    try {
      await service.toggleSave(recipe.id);
      // Re-fetch to ensure sync with backend
      ref.invalidateSelf();
    } catch (e, st) {
      // Revert on error
      state = AsyncData(previous);
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final savedRecipesProvider =
    AsyncNotifierProvider<SavedRecipesNotifier, List<Recipe>>(() {
  return SavedRecipesNotifier();
});

final generateAiRecipeProvider = FutureProvider.family<RecipeDetail, String>((ref, query) async {
  return ref.read(recipesServiceProvider).generateFromName(query);
});

final generateAiListProvider = FutureProvider<List<AiRecipe>>((ref) async {
  final pantryState = ref.watch(pantryProvider);
  final pantryItems = pantryState.value ?? [];
  
  if (pantryItems.isEmpty) return [];
  
  final ingredients = pantryItems.map((e) => {
    'name': e.rawName,
    'quantity': '${e.quantity} ${e.unit}'.trim(),
  }).toList();
  return ref.read(recipesServiceProvider).generateFromIngredients(ingredients);
});

final generateAiImageProvider = FutureProvider.family<String, AiRecipe>((ref, recipe) async {
  return ref.read(recipesServiceProvider).generateImage(recipe.title, recipe.finalDish);
});
