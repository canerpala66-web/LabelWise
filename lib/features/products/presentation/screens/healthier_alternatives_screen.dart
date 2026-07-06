import 'package:flutter/material.dart';
import 'package:labelwise/features/analysis/services/labelwise_score_engine.dart';
import 'package:labelwise/features/products/models/product_alternative.dart';
import 'package:labelwise/features/products/services/product_alternatives_service.dart';
import 'package:labelwise/features/scanner/data/product.dart';
import 'package:labelwise/features/scanner/data/product_repository.dart';
import 'package:labelwise/features/scanner/presentation/screens/product_result_screen.dart';

class HealthierAlternativesScreen extends StatefulWidget {
  const HealthierAlternativesScreen({required this.product, super.key});

  final Product product;

  @override
  State<HealthierAlternativesScreen> createState() =>
      _HealthierAlternativesScreenState();
}

class _HealthierAlternativesScreenState
    extends State<HealthierAlternativesScreen> {
  late final ProductAlternativesService _service;
  late final int? _currentScore;
  late final Future<List<ProductAlternative>>? _alternatives;

  @override
  void initState() {
    super.initState();
    debugPrint('AlternativesDebug: screen opened');
    _service = ProductAlternativesService();
    _currentScore = const LabelWiseScoreEngine()
        .calculate(widget.product)
        .score;
    _alternatives = _currentScore == null
        ? null
        : _service.findAlternatives(widget.product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        title: const Text('Daha Sağlıklı Alternatifler'),
        backgroundColor: const Color(0xFFF4F6F5),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _currentScore == null
            ? const _MessageState(
                icon: Icons.compare_arrows_rounded,
                message: 'Bu ürün için alternatif karşılaştırması yapılamıyor.',
              )
            : FutureBuilder<List<ProductAlternative>>(
                future: _alternatives,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const _MessageState(
                      icon: Icons.cloud_off_outlined,
                      message:
                          'Alternatifler yüklenemedi. Lütfen tekrar deneyin.',
                    );
                  }
                  final alternatives = snapshot.data ?? const [];
                  if (alternatives.isEmpty) {
                    return const _MessageState(
                      icon: Icons.search_off_rounded,
                      message: 'Henüz yeterli alternatif yok.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: alternatives.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _AlternativeCard(alternative: alternatives[index]);
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({required this.alternative});

  final ProductAlternative alternative;

  @override
  Widget build(BuildContext context) {
    final product = alternative.product;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductResultScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AlternativeImage(product: product),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF17211B),
                      ),
                    ),
                    if (product.brands.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.brands,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF657069)),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'LabelWise Skoru: ${alternative.score}',
                      style: const TextStyle(
                        color: Color(0xFF176B43),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final reason in alternative.reasons)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '• $reason',
                          style: const TextStyle(
                            color: Color(0xFF526159),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 26),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8A948E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlternativeImage extends StatefulWidget {
  const _AlternativeImage({required this.product});

  final Product product;

  @override
  State<_AlternativeImage> createState() => _AlternativeImageState();
}

class _AlternativeImageState extends State<_AlternativeImage> {
  late final Future<String?> _imageUrl;

  @override
  void initState() {
    super.initState();
    final publicUrl = widget.product.imageUrl?.trim();
    _imageUrl = publicUrl != null && publicUrl.isNotEmpty
        ? Future.value(publicUrl)
        : ProductRepository().createSubmittedProductPhotoSignedUrl(
            widget.product.frontImagePath,
          );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _imageUrl,
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 88,
            height: 88,
            child: imageUrl == null || imageUrl.isEmpty
                ? const _ImagePlaceholder()
                : Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                  ),
          ),
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEEF2EF),
      child: Center(
        child: Icon(Icons.inventory_2_outlined, color: Color(0xFF87938C)),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFF718078)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF3F4B44),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
