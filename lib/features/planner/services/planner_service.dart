import '../../../core/network/api_client.dart';
import '../models/planner_models.dart';

/// ──────────────────────────────────────────────
/// Meal Plan API Service
/// Mirrors: pp-backend modules/meal-plan/services/meal-plan.service.ts
/// Endpoints: GET /meal-plan, POST /meal-plan/:id,
///            POST /meal-plan/ai, DELETE /meal-plan/:id,
///            DELETE /meal-plan
/// ──────────────────────────────────────────────

class PlannerService {
  final _dio = ApiClient.instance.dio;

  /// GET /meal-plan
  Future<MealPlan> fetchMealPlan() async {
    final response = await _dio.get('/meal-plan');
    return MealPlan.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /meal-plan/:id
  Future<void> addRecipeToPlan(int recipeId) async {
    await _dio.post('/meal-plan/$recipeId');
  }

  /// POST /meal-plan/ai
  Future<void> addAiRecipeToPlan(Map<String, dynamic> aiRecipe) async {
    await _dio.post('/meal-plan/ai', data: aiRecipe);
  }

  /// DELETE /meal-plan/:id
  Future<void> removeRecipeFromPlan(int recipeId) async {
    await _dio.delete('/meal-plan/$recipeId');
  }

  /// DELETE /meal-plan
  Future<void> clearPlan() async {
    await _dio.delete('/meal-plan');
  }
}
