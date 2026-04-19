// ──────────────────────────────────────────────
// Meal Plan Models
// Mirrors: pp-backend modules/meal-plan
// ──────────────────────────────────────────────

class MealPlan {
  final List<MealPlanEntry> entries;

  const MealPlan({this.entries = const []});

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final list = (json['entries'] ?? json['meals'] ?? []) as List<dynamic>;
    return MealPlan(
      entries: list
          .map((e) => MealPlanEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MealPlanEntry {
  final int recipeId;
  final String title;
  final String? imageUrl;

  const MealPlanEntry({
    required this.recipeId,
    required this.title,
    this.imageUrl,
  });

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) {
    return MealPlanEntry(
      recipeId: json['recipeId'] as int? ?? json['id'] as int,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
