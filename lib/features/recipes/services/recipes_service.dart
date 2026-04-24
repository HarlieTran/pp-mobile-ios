import '../../../core/network/api_client.dart';
import '../models/recipe_models.dart';

/// ──────────────────────────────────────────────
/// Recipes API Service
/// Mirrors: pp-backend modules/recipes/services/*
///   - recipes.service.ts
///   - recipe-save.service.ts
///   - recipe-generate.service.ts
///   - recipe-generate-list.service.ts
///   - recipe-search.service.ts
///   - recipe-cook.service.ts
///   - spoonacular.service.ts
/// ──────────────────────────────────────────────

class RecipesService {
  final _dio = ApiClient.instance.dio;

  Future<List<Recipe>> fetchSuggestions({int limit = 12, String filter = 'All'}) async {
    final response = await _dio.post('/recipes/suggestions', data: {
      'limit': limit,
      if (filter != 'All') 'filter': filter,
    });
    final list = (response.data['recipes'] ?? response.data) as List<dynamic>;
    return list
        .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// GET /recipes/search?q=
  Future<List<Recipe>> searchRecipes(String query) async {
    final response = await _dio.get('/recipes/search', queryParameters: {
      'q': query,
    });
    final list = response.data['recipes'] as List<dynamic>;
    return list
        .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// GET /recipes/:id
  Future<RecipeDetail> fetchRecipeDetail(int id) async {
    final response = await _dio.get('/recipes/$id');
    return RecipeDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /recipes/from-name
  Future<RecipeDetail> generateFromName(String name,
      {int targetServings = 4, String? imageUrl, List<String>? ingredientHint}) async {
    final response = await _dio.post('/recipes/from-name', data: {
      'name': name,
      'targetServings': targetServings,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (ingredientHint != null) 'ingredientHint': ingredientHint,
    });
    return RecipeDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /recipes/generate-list
  Future<List<AiRecipe>> generateFromIngredients(
      List<Map<String, String>> ingredients) async {
    final response = await _dio.post('/recipes/generate-list', data: {
      'ingredients': ingredients,
    });
    final list = response.data['recipes'] as List<dynamic>;
    return list
        .map((r) => AiRecipe.fromJson(r as Map<String, dynamic>))
        .toList();
  }



  /// POST /recipes/generate-image
  Future<String> generateImage(String title, String description) async {
    final response = await _dio.post('/recipes/generate-image', data: {
      'title': title,
      'description': description,
    });
    return response.data['imageUrl'] as String;
  }

  /// GET /recipes/saved
  Future<List<Recipe>> fetchSavedRecipes() async {
    final response = await _dio.get('/recipes/saved');
    final list = response.data as List<dynamic>;
    return list
        .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// POST /recipes/:id/save (toggle)
  Future<Map<String, dynamic>> toggleSave(int id) async {
    final response = await _dio.post('/recipes/$id/save');
    return response.data as Map<String, dynamic>;
  }

  /// POST /recipes/cook
  Future<CookResult> cookRecipe({
    int? recipeId,
    List<RecipeIngredient>? ingredients,
    double? servingsUsed,
    bool dryRun = false,
  }) async {
    final response = await _dio.post('/recipes/cook', data: {
      if (recipeId != null) 'recipeId': recipeId,
      if (ingredients != null)
        'ingredients': ingredients
            .map((i) => {
                  'name': i.name,
                  if (i.amount != null) 'amount': i.amount,
                  if (i.unit != null) 'unit': i.unit,
                })
            .toList(),
      if (servingsUsed != null) 'servingsUsed': servingsUsed,
      'dryRun': dryRun,
    });
    return CookResult.fromJson(response.data as Map<String, dynamic>);
  }
}
