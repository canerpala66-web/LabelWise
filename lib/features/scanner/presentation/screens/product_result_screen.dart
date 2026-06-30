import 'package:flutter/material.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class ProductResultScreen extends StatelessWidget {
  const ProductResultScreen({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    final nutriscoreGrade = product.nutriscoreGrade?.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Product Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.productName.isEmpty
                  ? 'Unknown product'
                  : product.productName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Brand: ${product.brands.isEmpty ? 'Unknown brand' : product.brands}',
            ),
            const SizedBox(height: 8),
            Text(
              'Nutri-Score: ${nutriscoreGrade == null || nutriscoreGrade.isEmpty ? 'Unknown' : nutriscoreGrade.toUpperCase()}',
            ),
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 24),
              Center(
                child: Image.network(
                  imageUrl,
                  height: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              product.ingredientsText.isEmpty
                  ? 'Ingredients unavailable.'
                  : product.ingredientsText,
            ),
          ],
        ),
      ),
    );
  }
}
