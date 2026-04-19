import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/planner_models.dart';
import '../services/planner_service.dart';

/// ──────────────────────────────────────────────
/// Planner Provider
/// Mirrors: pp-frontend mealPlannerSlice
/// ──────────────────────────────────────────────

final plannerServiceProvider = Provider((_) => PlannerService());

final plannerProvider =
    StateNotifierProvider<PlannerNotifier, AsyncValue<MealPlan>>(
  (ref) => PlannerNotifier(ref.read(plannerServiceProvider)),
);

class PlannerNotifier extends StateNotifier<AsyncValue<MealPlan>> {
  final PlannerService _service;

  PlannerNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> fetchPlan() async {
    state = const AsyncValue.loading();
    try {
      final plan = await _service.fetchMealPlan();
      state = AsyncValue.data(plan);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRecipe(int recipeId) async {
    await _service.addRecipeToPlan(recipeId);
    await fetchPlan(); // Refresh
  }

  Future<void> removeRecipe(int recipeId) async {
    await _service.removeRecipeFromPlan(recipeId);
    await fetchPlan();
  }

  Future<void> clearPlan() async {
    await _service.clearPlan();
    state = const AsyncValue.data(MealPlan());
  }
}
