// ──────────────────────────────────────────────
// Recipe Models
// Mirrors: pp-backend modules/recipes
// ──────────────────────────────────────────────

class Recipe {
  final int id;
  final String title;
  final String? imageUrl;
  final int? readyInMinutes;
  final int? servings;
  final bool isSaved;
  final String? source; // 'spoonacular' | 'ai'

  const Recipe({
    required this.id,
    required this.title,
    this.imageUrl,
    this.readyInMinutes,
    this.servings,
    this.isSaved = false,
    this.source,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      readyInMinutes: json['readyInMinutes'] as int?,
      servings: json['servings'] as int?,
      isSaved: json['isSaved'] as bool? ?? false,
      source: json['source'] as String?,
    );
  }
}

class RecipeDetail extends Recipe {
  final String? summary;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;

  const RecipeDetail({
    required super.id,
    required super.title,
    super.imageUrl,
    super.readyInMinutes,
    super.servings,
    super.isSaved,
    super.source,
    this.summary,
    this.ingredients = const [],
    this.instructions = const [],
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    return RecipeDetail(
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      readyInMinutes: json['readyInMinutes'] as int?,
      servings: json['servings'] as int?,
      isSaved: json['isSaved'] as bool? ?? false,
      source: json['source'] as String?,
      summary: json['summary'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) =>
                  RecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class RecipeIngredient {
  final String name;
  final double? amount;
  final String? unit;

  const RecipeIngredient({
    required this.name,
    this.amount,
    this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
    );
  }
}

class CookResult {
  final List<CookDeduction> deductions;
  final bool isDryRun;

  const CookResult({required this.deductions, this.isDryRun = false});

  factory CookResult.fromJson(Map<String, dynamic> json) {
    return CookResult(
      deductions: (json['deductions'] as List<dynamic>?)
              ?.map(
                  (e) => CookDeduction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isDryRun: json['dryRun'] as bool? ?? false,
    );
  }
}

class CookDeduction {
  final String ingredientName;
  final double amountUsed;
  final String? unit;

  const CookDeduction({
    required this.ingredientName,
    required this.amountUsed,
    this.unit,
  });

  factory CookDeduction.fromJson(Map<String, dynamic> json) {
    return CookDeduction(
      ingredientName: json['ingredientName'] as String,
      amountUsed: (json['amountUsed'] as num).toDouble(),
      unit: json['unit'] as String?,
    );
  }
}
