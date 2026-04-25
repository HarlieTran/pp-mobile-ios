// ──────────────────────────────────────────────
// Recipe Models
// Mirrors: pp-backend modules/recipes
// ──────────────────────────────────────────────

class AiRecipe {
  final String title;
  final String servings;
  final String estimatedTime;
  final String finalDish;
  final List<AiRecipeIngredient> ingredients;

  const AiRecipe({
    required this.title,
    required this.servings,
    required this.estimatedTime,
    required this.finalDish,
    this.ingredients = const [],
  });

  factory AiRecipe.fromJson(Map<String, dynamic> json) {
    return AiRecipe(
      title: json['title'] as String? ?? 'Unknown Recipe',
      servings: json['servings'] as String? ?? '2',
      estimatedTime: json['estimatedTime'] as String? ?? '30 mins',
      finalDish: json['finalDish'] as String? ?? '',
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => AiRecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AiRecipeIngredient {
  final String name;
  final String quantity;
  final bool fromPantry;

  const AiRecipeIngredient({
    required this.name,
    required this.quantity,
    required this.fromPantry,
  });

  factory AiRecipeIngredient.fromJson(Map<String, dynamic> json) {
    return AiRecipeIngredient(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      fromPantry: json['fromPantry'] as bool? ?? false,
    );
  }
}

class Recipe {
  final int id;
  final String title;
  final String? imageUrl;
  final int? readyInMinutes;
  final int? servings;
  final bool isSaved;
  final String? source; // 'spoonacular' | 'ai'
  final int? usedIngredientCount;
  final int? missedIngredientCount;

  const Recipe({
    required this.id,
    required this.title,
    this.imageUrl,
    this.readyInMinutes,
    this.servings,
    this.isSaved = false,
    this.source,
    this.usedIngredientCount,
    this.missedIngredientCount,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      readyInMinutes: (json['readyInMinutes'] ?? json['readyMinutes']) as int?,
      servings: json['servings'] as int?,
      isSaved: json['isSaved'] as bool? ?? false,
      source: json['source'] as String?,
      usedIngredientCount: json['usedIngredientCount'] as int?,
      missedIngredientCount: json['missedIngredientCount'] as int?,
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
    // Parse ingredients (custom or spoonacular)
    final ingList = json['ingredients'] ?? json['extendedIngredients'];
    final parsedIngredients = (ingList as List<dynamic>?)
            ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse instructions
    List<String> parsedInstructions = [];
    if (json['instructions'] is List) {
      parsedInstructions = (json['instructions'] as List).map((e) => e.toString()).toList();
    } else if (json['analyzedInstructions'] is List && (json['analyzedInstructions'] as List).isNotEmpty) {
      final steps = (json['analyzedInstructions'][0]['steps'] as List<dynamic>?);
      if (steps != null) {
        parsedInstructions = steps.map((s) => s['step'].toString()).toList();
      }
    } else if (json['instructions'] is String && (json['instructions'] as String).isNotEmpty) {
      parsedInstructions = [(json['instructions'] as String).replaceAll(RegExp(r'<[^>]*>'), '').trim()];
    }

    return RecipeDetail(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Generated Recipe',
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      readyInMinutes: (json['readyInMinutes'] ?? json['readyMinutes']) as int?,
      servings: json['servings'] as int?,
      isSaved: json['isSaved'] as bool? ?? false,
      source: json['source'] as String?,
      summary: json['summary'] as String?,
      ingredients: parsedIngredients,
      instructions: parsedInstructions,
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
      name: (json['name'] ?? json['rawName'] ?? '') as String,
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
    );
  }
}

class CookResult {
  final int? recipeId;
  final bool isDryRun;
  final List<CookUpdatedItem> updatedItems;
  final List<CookRemovedItem> removedItems;
  final List<String> unmatchedIngredients;
  final List<String> warnings;

  const CookResult({
    this.recipeId,
    this.isDryRun = false,
    this.updatedItems = const [],
    this.removedItems = const [],
    this.unmatchedIngredients = const [],
    this.warnings = const [],
  });

  factory CookResult.fromJson(Map<String, dynamic> json) {
    return CookResult(
      recipeId: json['recipeId'] as int?,
      isDryRun: json['dryRun'] as bool? ?? false,
      updatedItems: (json['updatedItems'] as List<dynamic>?)
              ?.map((e) => CookUpdatedItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      removedItems: (json['removedItems'] as List<dynamic>?)
              ?.map((e) => CookRemovedItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      unmatchedIngredients: (json['unmatchedIngredients'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class CookUpdatedItem {
  final String itemId;
  final String name;
  final double beforeQty;
  final double afterQty;

  const CookUpdatedItem({
    required this.itemId,
    required this.name,
    required this.beforeQty,
    required this.afterQty,
  });

  factory CookUpdatedItem.fromJson(Map<String, dynamic> json) {
    return CookUpdatedItem(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      beforeQty: (json['beforeQty'] as num).toDouble(),
      afterQty: (json['afterQty'] as num).toDouble(),
    );
  }
}

class CookRemovedItem {
  final String itemId;
  final String name;
  final double beforeQty;

  const CookRemovedItem({
    required this.itemId,
    required this.name,
    required this.beforeQty,
  });

  factory CookRemovedItem.fromJson(Map<String, dynamic> json) {
    return CookRemovedItem(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      beforeQty: (json['beforeQty'] as num).toDouble(),
    );
  }
}
