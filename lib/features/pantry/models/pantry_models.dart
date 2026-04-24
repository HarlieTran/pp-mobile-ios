// ──────────────────────────────────────────────
// Pantry Item Model
// Mirrors: pp-backend modules/pantry/model/pantry.types.ts
// ──────────────────────────────────────────────

enum ExpiryStatus { expired, expiringSoon, fresh, noDate }

class PantryItem {
  final String id;
  final String rawName;
  final double quantity;
  final String unit;
  final String? expiryDate;
  final String? notes;
  final ExpiryStatus expiryStatus;
  final int? daysUntilExpiry;
  final String category;

  const PantryItem({
    required this.id,
    required this.rawName,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    this.notes,
    this.expiryStatus = ExpiryStatus.noDate,
    this.daysUntilExpiry,
    this.category = 'Other',
  });

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'].toString(),
      rawName: json['rawName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      expiryDate: json['expiryDate'] as String?,
      notes: json['notes'] as String?,
      expiryStatus: _parseExpiryStatus(json['status'] as String?),
      daysUntilExpiry: json['daysUntilExpiry'] as int?,
      category: json['category'] as String? ?? 'Other',
    );
  }

  static ExpiryStatus _parseExpiryStatus(String? status) {
    switch (status) {
      case 'expired':
        return ExpiryStatus.expired;
      case 'expiring_soon':
        return ExpiryStatus.expiringSoon;
      case 'fresh':
        return ExpiryStatus.fresh;
      default:
        return ExpiryStatus.noDate;
    }
  }
}

class AddPantryItemPayload {
  final String rawName;
  final double quantity;
  final String unit;
  final String? expiryDate;
  final String? notes;

  const AddPantryItemPayload({
    required this.rawName,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'rawName': rawName,
        'quantity': quantity,
        'unit': unit,
        if (expiryDate != null) 'expiryDate': expiryDate,
        if (notes != null) 'notes': notes,
      };
}

class UpdatePantryItemPayload {
  final double? quantity;
  final String? unit;
  final String? expiryDate;
  final String? notes;

  const UpdatePantryItemPayload({this.quantity, this.unit, this.expiryDate, this.notes});

  Map<String, dynamic> toJson() => {
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (expiryDate != null) 'expiryDate': expiryDate,
        if (notes != null) 'notes': notes,
      };
}

class ParsedIngredient {
  final String name;
  final String quantity;
  final String unit;
  final String category;

  const ParsedIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
  });

  factory ParsedIngredient.fromJson(Map<String, dynamic> json) {
    return ParsedIngredient(
      name: json['name']?.toString() ?? 'Unknown Item',
      quantity: json['quantity']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
    );
  }
}

class ExpiryHelper {
  static String guessCategory(String name) {
    final lowerName = name.toLowerCase();
    final singular = lowerName.endsWith('ies') ? lowerName.substring(0, lowerName.length - 3) + 'y' 
                   : lowerName.endsWith('es') ? lowerName.substring(0, lowerName.length - 2) 
                   : lowerName.endsWith('s') ? lowerName.substring(0, lowerName.length - 1) 
                   : lowerName;

    final produce = ["tomato", "potato", "carrot", "cucumber", "onion", "garlic", "apple", "banana", "broccoli", "pepper", "spinach", "lettuce", "strawberry", "radish", "eggplant", "salad", "celery", "mushroom", "zucchini", "squash", "cabbage", "cauliflower", "asparagus", "corn", "bean", "pea", "grape", "orange", "lemon", "lime", "berry", "melon", "peach", "plum", "cherry", "avocado", "kale", "mango", "fruit", "pear", "kiwi", "pineapple"];
    final dairy = ["milk", "egg", "cheese", "butter", "cream", "yogurt", "ghee", "kefir", "whey"];
    final meat = ["beef", "chicken", "pork", "sausage", "ham", "bacon", "turkey", "tenderloin", "lamb", "veal", "duck", "venison", "prosciutto", "salami"];
    final seafood = ["fish", "salmon", "tuna", "shrimp", "crab", "lobster", "scallop", "clam", "mussel", "oyster", "squid", "octopus", "cod", "halibut", "tilapia", "anchovy", "sardine"];
    final spices = ["salt", "pepper", "parsley", "basil", "oregano", "cinnamon", "cumin", "spice", "herb", "thyme", "rosemary", "sage", "cilantro", "mint", "dill", "chive", "paprika", "nutmeg", "clove", "ginger", "turmeric", "saffron", "cardamom", "coriander"];
    final condiments = ["oil", "vinegar", "mustard", "ketchup", "mayo", "sauce", "dressing", "sugar", "syrup", "honey", "jam", "jelly", "spread", "dip", "salsa", "relish", "soy", "teriyaki", "sriracha"];
    
    bool matches(List<String> keywords) => keywords.any((k) => lowerName.contains(k) || singular.contains(k));
    
    if (matches(produce)) return 'produce';
    if (matches(dairy)) return 'dairy';
    if (matches(meat)) return 'meat';
    if (matches(seafood)) return 'seafood';
    if (matches(spices)) return 'spices';
    if (matches(condiments)) return 'condiments';
    
    return 'other';
  }

  static int getDefaultLifespanDays(String category) {
    switch (category.toLowerCase()) {
      case 'produce': return 14;
      case 'condiments & oils':
      case 'condiments': return 180;
      case 'dairy & eggs':
      case 'dairy': return 14;
      case 'meat & poultry':
      case 'meat': return 4;
      case 'spices & herbs':
      case 'spices': return 365;
      case 'seafood': return 3;
      default: return 30;
    }
  }
}
