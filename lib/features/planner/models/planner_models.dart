// ──────────────────────────────────────────────
// Meal Plan Models
// Mirrors: pp-backend modules/meal-plan
// ──────────────────────────────────────────────

class MealPlan {
  final List<MealPlanEntry> entries;

  const MealPlan({this.entries = const []});

  factory MealPlan.fromJson(dynamic json) {
    if (json is List) {
      return MealPlan(
        entries: json.map((e) {
          if (e is Map) {
            return MealPlanEntry.fromJson(Map<String, dynamic>.from(e));
          }
          return const MealPlanEntry(recipeId: 0, title: 'Unknown');
        }).toList(),
      );
    }
    if (json is Map) {
      final list = (json['entries'] ?? json['meals'] ?? []) as List<dynamic>;
      return MealPlan(
        entries: list
            .map((e) {
              if (e is Map) {
                return MealPlanEntry.fromJson(Map<String, dynamic>.from(e));
              }
              return const MealPlanEntry(recipeId: 0, title: 'Unknown');
            })
            .toList(),
      );
    }
    return const MealPlan();
  }
}

class MealPlanEntry {
  final int recipeId;
  final String title;
  final String? imageUrl;
  final String? date;
  final int? readyInMinutes;
  final List<MealPlanIngredient> requiredIngredients;

  const MealPlanEntry({
    required this.recipeId,
    required this.title,
    this.imageUrl,
    this.date,
    this.readyInMinutes,
    this.requiredIngredients = const [],
  });

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    if (json['recipeId'] != null) {
      parsedId = int.tryParse(json['recipeId'].toString()) ?? 0;
    } else if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    return MealPlanEntry(
      recipeId: parsedId,
      title: json['title']?.toString() ?? 'Unknown Recipe',
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      date: json['date']?.toString(),
      readyInMinutes: json['readyInMinutes'] != null 
          ? int.tryParse(json['readyInMinutes'].toString())
          : null,
      requiredIngredients: (json['requiredIngredients'] as List<dynamic>?)
              ?.map((e) => MealPlanIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MealPlanIngredient {
  final String name;
  final String quantity;

  const MealPlanIngredient({
    required this.name,
    required this.quantity,
  });

  factory MealPlanIngredient.fromJson(Map<String, dynamic> json) {
    return MealPlanIngredient(
      name: json['name']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '',
    );
  }
}
