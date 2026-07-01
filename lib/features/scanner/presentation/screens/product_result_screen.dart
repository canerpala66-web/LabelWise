import 'package:flutter/material.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class ProductResultScreen extends StatelessWidget {
  const ProductResultScreen({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final productName = product.productName.isEmpty
        ? 'Bilinmeyen Ürün'
        : product.productName;
    final brand = product.brands.isEmpty ? 'Bilinmeyen Marka' : product.brands;
    final ingredients = product.ingredientsText.isEmpty
        ? 'İçindekiler bilgisi bulunamadı'
        : product.ingredientsText;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        backgroundColor: const Color(0xFFF4F6F5),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductImageCard(imageUrl: product.imageUrl),
                  const SizedBox(height: 24),
                  Text(
                    productName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17211B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Marka: $brand',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF657069),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _NutriScoreBadge(grade: product.nutriscoreGrade),
                  const SizedBox(height: 28),
                  _ContentCard(
                    title: 'İçindekiler',
                    child: Text(
                      ingredients,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: const Color(0xFF3D4841),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _PlaceholderCard(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Yapay Zeka Yorumu',
                    message: 'Yakında',
                  ),
                  const SizedBox(height: 16),
                  const _PlaceholderCard(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Daha Sağlıklı Alternatifler',
                    message: 'Premium özellik yakında',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductImageCard extends StatelessWidget {
  const _ProductImageCard({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: double.infinity,
        height: 280,
        child: url == null || url.isEmpty
            ? const _ImagePlaceholder()
            : Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const _ImagePlaceholder();
                },
              ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE9EEEB),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 44,
              color: Color(0xFF78847C),
            ),
            SizedBox(height: 8),
            Text(
              'Görsel bulunamadı',
              style: TextStyle(color: Color(0xFF657069)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutriScoreBadge extends StatelessWidget {
  const _NutriScoreBadge({required this.grade});

  final String? grade;

  @override
  Widget build(BuildContext context) {
    final normalizedGrade = grade?.trim().toUpperCase();
    final isKnown = const {'A', 'B', 'C', 'D', 'E'}.contains(normalizedGrade);
    final displayGrade = isKnown ? normalizedGrade! : 'Bilinmiyor';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _badgeColor(normalizedGrade),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Text(
          'Nutri-Score: $displayGrade',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Color _badgeColor(String? grade) {
    return switch (grade) {
      'A' => const Color(0xFF16843B),
      'B' => const Color(0xFF57A53A),
      'C' => const Color(0xFFD49B18),
      'D' => const Color(0xFFE46F21),
      'E' => const Color(0xFFC83E35),
      _ => const Color(0xFF7A827D),
    };
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF17211B),
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0xFFE9EEEB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF657069)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D4841),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF78847C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
