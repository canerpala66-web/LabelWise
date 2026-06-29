class Product {
  const Product({
    required this.productName,
    required this.brands,
    required this.imageUrl,
    required this.ingredientsText,
  });

  final String productName;
  final String brands;
  final String? imageUrl;
  final String ingredientsText;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productName: (json['product_name'] as String?)?.trim() ?? '',
      brands: (json['brands'] as String?)?.trim() ?? '',
      imageUrl: (json['image_url'] as String?)?.trim(),
      ingredientsText: (json['ingredients_text'] as String?)?.trim() ?? '',
    );
  }
}
