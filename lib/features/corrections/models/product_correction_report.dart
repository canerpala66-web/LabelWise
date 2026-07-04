class ProductCorrectionReport {
  const ProductCorrectionReport({
    required this.id,
    required this.barcode,
    required this.reportedIssue,
    required this.status,
    this.productName,
    this.brand,
    this.correctedEnergyKcal,
    this.correctedFat,
    this.correctedSaturatedFat,
    this.correctedSugars,
    this.correctedFiber,
    this.correctedProtein,
    this.correctedSalt,
    this.note,
    this.source,
    this.createdAt,
    this.reviewedAt,
    this.reviewNote,
  });

  final String id;
  final String barcode;
  final String? productName;
  final String? brand;
  final String reportedIssue;
  final double? correctedEnergyKcal;
  final double? correctedFat;
  final double? correctedSaturatedFat;
  final double? correctedSugars;
  final double? correctedFiber;
  final double? correctedProtein;
  final double? correctedSalt;
  final String? note;
  final String status;
  final String? source;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewNote;

  bool get hasCorrectedNutrition =>
      correctedNutrition.values.any((value) => value != null);

  Map<String, double?> get correctedNutrition => {
    'energy_kcal': correctedEnergyKcal,
    'fat': correctedFat,
    'saturated_fat': correctedSaturatedFat,
    'sugars': correctedSugars,
    'fiber': correctedFiber,
    'protein': correctedProtein,
    'salt': correctedSalt,
  };

  factory ProductCorrectionReport.fromJson(Map<String, dynamic> json) {
    return ProductCorrectionReport(
      id: _string(json['id']) ?? '',
      barcode: _string(json['barcode']) ?? '',
      productName: _string(json['product_name']),
      brand: _string(json['brand']),
      reportedIssue: _string(json['reported_issue']) ?? 'Diğer',
      correctedEnergyKcal: _number(json['corrected_energy_kcal']),
      correctedFat: _number(json['corrected_fat']),
      correctedSaturatedFat: _number(json['corrected_saturated_fat']),
      correctedSugars: _number(json['corrected_sugars']),
      correctedFiber: _number(json['corrected_fiber']),
      correctedProtein: _number(json['corrected_protein']),
      correctedSalt: _number(json['corrected_salt']),
      note: _string(json['note']),
      status: _string(json['status']) ?? 'pending',
      source: _string(json['source']),
      createdAt: _dateTime(json['created_at']),
      reviewedAt: _dateTime(json['reviewed_at']),
      reviewNote: _string(json['review_note']),
    );
  }

  static String? _string(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static DateTime? _dateTime(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}
