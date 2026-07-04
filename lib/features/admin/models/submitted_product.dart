class SubmittedProduct {
  const SubmittedProduct({
    required this.id,
    required this.barcode,
    required this.name,
    required this.status,
    this.brand,
    this.ingredientsText,
    this.energyKcal,
    this.fat,
    this.saturatedFat,
    this.sugars,
    this.fiber,
    this.protein,
    this.salt,
    this.frontImagePath,
    this.nutritionImagePath,
    this.ingredientsImagePath,
    this.source,
    this.createdAt,
    this.reviewedAt,
    this.reviewNote,
  });

  final String id;
  final String barcode;
  final String name;
  final String status;
  final String? brand;
  final String? ingredientsText;
  final double? energyKcal;
  final double? fat;
  final double? saturatedFat;
  final double? sugars;
  final double? fiber;
  final double? protein;
  final double? salt;
  final String? frontImagePath;
  final String? nutritionImagePath;
  final String? ingredientsImagePath;
  final String? source;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewNote;

  bool get hasNutritionData => [
    energyKcal,
    fat,
    saturatedFat,
    sugars,
    fiber,
    protein,
    salt,
  ].any((value) => value != null);

  factory SubmittedProduct.fromJson(Map<String, dynamic> json) {
    final rawStatus = _string(json['status'])?.toLowerCase();
    final status = const {'pending', 'approved', 'rejected'}.contains(rawStatus)
        ? rawStatus!
        : 'pending';

    return SubmittedProduct(
      id: _string(json['id']) ?? '',
      barcode: _string(json['barcode']) ?? '',
      name: _string(json['name']) ?? '',
      brand: _string(json['brand']),
      ingredientsText: _string(json['ingredients_text']),
      energyKcal: _number(json['energy_kcal']),
      fat: _number(json['fat']),
      saturatedFat: _number(json['saturated_fat']),
      sugars: _number(json['sugars']),
      fiber: _number(json['fiber']),
      protein: _number(json['protein']),
      salt: _number(json['salt']),
      frontImagePath: _string(json['front_image_path']),
      nutritionImagePath: _string(json['nutrition_image_path']),
      ingredientsImagePath: _string(json['ingredients_image_path']),
      status: status,
      source: _string(json['source']),
      createdAt: _dateTime(json['created_at']),
      reviewedAt: _dateTime(json['reviewed_at']),
      reviewNote: _string(json['review_note']),
    );
  }

  static String? _string(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static DateTime? _dateTime(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
