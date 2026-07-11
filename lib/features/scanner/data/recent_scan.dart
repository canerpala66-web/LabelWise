class RecentScan {
  const RecentScan({
    required this.barcode,
    required this.productName,
    required this.brand,
    required this.openedAt,
    this.imageUrl,
    this.category,
    this.labelwiseScore,
  });

  final String barcode;
  final String productName;
  final String brand;
  final String? imageUrl;
  final String? category;
  final int? labelwiseScore;
  final DateTime openedAt;

  factory RecentScan.fromJson(Map<String, dynamic> json) {
    return RecentScan(
      barcode: _text(json['barcode']) ?? '',
      productName: _text(json['product_name']) ?? 'Bilinmeyen Ürün',
      brand: _text(json['brand']) ?? 'Bilinmeyen Marka',
      imageUrl: _text(json['image_url']),
      category: _text(json['category']),
      labelwiseScore: _int(json['labelwise_score']),
      openedAt:
          DateTime.tryParse(_text(json['opened_at']) ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'product_name': productName,
      'brand': brand,
      'image_url': imageUrl,
      'category': category,
      'labelwise_score': labelwiseScore,
      'opened_at': openedAt.toIso8601String(),
    };
  }

  static String? _text(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
