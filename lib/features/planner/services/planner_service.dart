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
    return MealPlan.fromJson(response.data);
  }

  /// POST /meal-plan/:id
  Future<void> addRecipeToPlan(int recipeId, {String? date}) async {
    final data = date != null ? {'date': date} : null;
    await _dio.post('/meal-plan/$recipeId', data: data);
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

  // ── Planner Notes ──────────────────────────

  /// GET /planner-notes → Map<date, text>
  Future<Map<String, String>> fetchNotes() async {
    final response = await _dio.get('/planner-notes');
    final list = response.data as List<dynamic>;
    final map = <String, String>{};
    for (final item in list) {
      map[item['date'] as String] = item['text'] as String;
    }
    return map;
  }

  /// PUT /planner-notes/:date
  Future<void> upsertNote(String date, String text) async {
    await _dio.put('/planner-notes/$date', data: {'text': text});
  }

  /// DELETE /planner-notes/:date
  Future<void> deleteNote(String date) async {
    await _dio.delete('/planner-notes/$date');
  }
}
