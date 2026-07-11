import 'package:flutter/material.dart';
import 'package:labelwise/features/analysis/services/labelwise_score_engine.dart';
import 'package:labelwise/features/products/models/product_alternative.dart';
import 'package:labelwise/features/products/services/product_alternatives_service.dart';
import 'package:labelwise/features/scanner/data/product.dart';
import 'package:labelwise/features/scanner/data/product_repository.dart';
import 'package:labelwise/features/scanner/presentation/screens/product_result_screen.dart';

const _backgroundColor = Color(0xFFF5F5F1);
const _inkColor = Color(0xFF18251E);
const _mutedColor = Color(0xFF657069);
const _greenColor = Color(0xFF176B43);
const _softGreenColor = Color(0xFFE8F3EC);

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
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Alternatifler',
          style: TextStyle(
            color: _inkColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentScore == null) {
      return _AlternativesListFrame(
        product: widget.product,
        currentScore: null,
        children: const [_EmptyState()],
      );
    }

    return FutureBuilder<List<ProductAlternative>>(
      future: _alternatives,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _AlternativesListFrame(
            product: widget.product,
            currentScore: _currentScore,
            children: const [_LoadingState()],
          );
        }
        if (snapshot.hasError) {
          return _AlternativesListFrame(
            product: widget.product,
            currentScore: _currentScore,
            children: const [_ErrorState()],
          );
        }

        final alternatives = snapshot.data ?? const [];
        if (alternatives.isEmpty) {
          return _AlternativesListFrame(
            product: widget.product,
            currentScore: _currentScore,
            children: const [_EmptyState()],
          );
        }

        return _AlternativesListFrame(
          product: widget.product,
          currentScore: _currentScore,
          resultCount: alternatives.length,
          children: [
            for (final alternative in alternatives)
              _AlternativeCard(
                key: ValueKey(alternative.product.barcode),
                alternative: alternative,
                currentScore: _currentScore,
              ),
          ],
        );
      },
    );
  }
}

class _AlternativesListFrame extends StatelessWidget {
  const _AlternativesListFrame({
    required this.product,
    required this.currentScore,
    required this.children,
    this.resultCount,
  });

  final Product product;
  final int? currentScore;
  final int? resultCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
      children: [
        const Text(
          'Daha Sağlıklı\nAlternatifler',
          style: TextStyle(
            color: _inkColor,
            fontSize: 34,
            height: 1.05,
            letterSpacing: -1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Benzer ürünler arasında daha dengeli seçenekleri keşfedin.',
          style: TextStyle(color: _mutedColor, height: 1.5, fontSize: 15),
        ),
        const SizedBox(height: 24),
        _CurrentProductCard(product: product, score: currentScore),
        const SizedBox(height: 28),
        if (resultCount case final count?) ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ÖNE ÇIKAN SEÇENEKLER',
                  style: TextStyle(
                    color: _greenColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.25,
                  ),
                ),
              ),
              Text(
                '$count ürün',
                style: const TextStyle(
                  color: Color(0xFF849088),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _CurrentProductCard extends StatelessWidget {
  const _CurrentProductCard({required this.product, required this.score});

  final Product product;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final category = _displayCategory(product.category);
    final brand = product.brands.trim().isEmpty
        ? 'Marka bilgisi yok'
        : product.brands.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5F40),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22175C3B),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MEVCUT ÜRÜN',
                  style: TextStyle(
                    color: Color(0xFFB9D9C7),
                    fontSize: 9,
                    letterSpacing: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.productName.trim().isEmpty
                      ? 'Bilinmeyen Ürün'
                      : product.productName.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$brand  •  $category',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC7DBCF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ScoreBadge(score: score),
        ],
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({
    required this.alternative,
    required this.currentScore,
    super.key,
  });

  final ProductAlternative alternative;
  final int currentScore;

  void _openProduct(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductResultScreen(product: alternative.product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = alternative.product;
    final scoreDifference = alternative.score - currentScore;
    final brand = product.brands.trim().isEmpty
        ? 'Marka bilgisi yok'
        : product.brands.trim();
    final reasons = alternative.reasons
        .take(2)
        .map(_displayReason)
        .toList(growable: false);

    return Semantics(
      button: true,
      label: '${product.productName} ürününü gör',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        shadowColor: const Color(0x151C3A2B),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openProduct(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AlternativeImage(product: product),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _CategoryChip(
                                  category: _displayCategory(product.category),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _ScoreBadge(score: alternative.score),
                            ],
                          ),
                          const SizedBox(height: 11),
                          Text(
                            product.productName.trim().isEmpty
                                ? 'Bilinmeyen Ürün'
                                : product.productName.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _inkColor,
                              fontSize: 17,
                              height: 1.16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _mutedColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(height: 1, color: const Color(0xFFE9ECE9)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (scoreDifference > 0)
                      _ReasonChip(
                        label: '+$scoreDifference puan daha iyi',
                        highlighted: true,
                      ),
                    for (final reason in reasons) _ReasonChip(label: reason),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _softGreenColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ürünü Gör',
                        style: TextStyle(
                          color: _greenColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 7),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: _greenColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: score == null ? const Color(0xFFF0F2F0) : _softGreenColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: score == null
              ? const Color(0xFFDDE2DE)
              : const Color(0xFFC6E0CF),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            score?.toString() ?? '—',
            style: TextStyle(
              color: score == null ? _mutedColor : _greenColor,
              fontSize: 19,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'SKOR',
            style: TextStyle(
              color: Color(0xFF6C7E73),
              fontSize: 7,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F0),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF5C6961),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFDDF0E4) : const Color(0xFFF5F6F3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFC2DFC9)
              : const Color(0xFFE4E8E3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            highlighted
                ? Icons.trending_up_rounded
                : Icons.check_circle_outline_rounded,
            size: 15,
            color: _greenColor,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF3D5347),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
        return Container(
          width: 104,
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E9E5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl == null || imageUrl.isEmpty
                ? const _ImagePlaceholder()
                : Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => const _ImagePlaceholder(),
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : const _ImageLoading(),
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
      color: Color(0xFFF3F4F1),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 30,
          color: Color(0xFF96A099),
        ),
      ),
    );
  }
}

class _ImageLoading extends StatelessWidget {
  const _ImageLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF0F2EF),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF6F9B80),
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 54, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _greenColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Daha dengeli seçenekler aranıyor…',
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const _StateCard(
      icon: Icons.spa_outlined,
      iconBackground: _softGreenColor,
      iconColor: _greenColor,
      title: 'Henüz yeterli alternatif yok',
      description:
          'Bu kategori için daha iyi seçenekler veritabanımızda arttıkça burada görünecek.',
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const _StateCard(
      icon: Icons.cloud_off_outlined,
      iconBackground: Color(0xFFFFECE8),
      iconColor: Color(0xFFA94D40),
      title: 'Bir sorun oluştu',
      description: 'Alternatifler yüklenemedi. Lütfen tekrar deneyin.',
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E9E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F213A2D),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 29, color: iconColor),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _inkColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _mutedColor,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

String _displayCategory(String? category) {
  final trimmed = category?.trim();
  return trimmed == null || trimmed.isEmpty
      ? 'Kategori belirtilmemiş'
      : trimmed;
}

String _displayReason(String reason) {
  final normalized = reason.toLowerCase();
  if (normalized.contains('şeker') && normalized.contains('düşük')) {
    return 'Daha düşük şeker';
  }
  if (normalized.contains('tuz') && normalized.contains('düşük')) {
    return 'Daha düşük tuz';
  }
  if (normalized.contains('doymuş yağ') && normalized.contains('düşük')) {
    return 'Daha düşük doymuş yağ';
  }
  if (normalized.contains('labelwise') && normalized.contains('yüksek')) {
    return 'Daha yüksek LabelWise Skoru';
  }
  return reason;
}
