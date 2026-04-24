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

  Future<void> addRecipe(int recipeId, {String? date}) async {
    await _service.addRecipeToPlan(recipeId, date: date);
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

// ── Planner Notes Provider ────────────────────

final plannerNotesProvider =
    StateNotifierProvider<PlannerNotesNotifier, Map<String, String>>(
  (ref) => PlannerNotesNotifier(ref.read(plannerServiceProvider)),
);

class PlannerNotesNotifier extends StateNotifier<Map<String, String>> {
  final PlannerService _service;

  PlannerNotesNotifier(this._service) : super({});

  Future<void> fetchNotes() async {
    try {
      final notes = await _service.fetchNotes();
      state = notes;
    } catch (_) {
      // Keep current state on error
    }
  }

  Future<void> saveNote(String date, String text) async {
    // Optimistic update
    final updated = Map<String, String>.from(state);
    updated[date] = text;
    state = updated;
    try {
      await _service.upsertNote(date, text);
    } catch (_) {
      // Rollback on error
      final rollback = Map<String, String>.from(state);
      rollback.remove(date);
      state = rollback;
    }
  }

  Future<void> deleteNote(String date) async {
    final prev = state[date];
    // Optimistic remove
    final updated = Map<String, String>.from(state);
    updated.remove(date);
    state = updated;
    try {
      await _service.deleteNote(date);
    } catch (_) {
      // Rollback on error
      if (prev != null) {
        final rollback = Map<String, String>.from(state);
        rollback[date] = prev;
        state = rollback;
      }
    }
  }
}
