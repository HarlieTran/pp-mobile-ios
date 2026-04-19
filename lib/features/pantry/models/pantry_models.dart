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

  const PantryItem({
    required this.id,
    required this.rawName,
    required this.quantity,
    required this.unit,
    this.expiryDate,
    this.notes,
    this.expiryStatus = ExpiryStatus.noDate,
    this.daysUntilExpiry,
  });

  factory PantryItem.fromJson(Map<String, dynamic> json) {
    return PantryItem(
      id: json['id'].toString(),
      rawName: json['rawName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      expiryDate: json['expiryDate'] as String?,
      notes: json['notes'] as String?,
      expiryStatus: _parseExpiryStatus(json['expiryStatus'] as String?),
      daysUntilExpiry: json['daysUntilExpiry'] as int?,
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
      name: json['name'] as String,
      quantity: json['quantity']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
    );
  }
}
