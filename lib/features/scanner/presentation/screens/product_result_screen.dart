import 'package:flutter/material.dart';
import 'package:labelwise/features/analysis/models/analysis_result.dart';
import 'package:labelwise/features/analysis/models/labelwise_score_result.dart';
import 'package:labelwise/features/analysis/services/analysis_service.dart';
import 'package:labelwise/features/analysis/services/labelwise_score_engine.dart';
import 'package:labelwise/features/corrections/presentation/screens/correction_report_screen.dart';
import 'package:labelwise/features/scanner/data/product.dart';
import 'package:labelwise/features/scanner/data/product_repository.dart';
import 'package:labelwise/features/scanner/presentation/screens/submit_product_screen.dart';

class ProductResultScreen extends StatefulWidget {
  const ProductResultScreen({required this.product, super.key});

  final Product product;

  @override
  State<ProductResultScreen> createState() => _ProductResultScreenState();
}

class _ProductResultScreenState extends State<ProductResultScreen>
    with SingleTickerProviderStateMixin {
  final ProductRepository _productRepository = ProductRepository();

  late final AnimationController _entranceController;
  late final Future<String?>? _signedFrontImageUrl;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    final publicImageUrl = widget.product.imageUrl?.trim();
    final frontImagePath = widget.product.frontImagePath?.trim();
    _signedFrontImageUrl =
        (publicImageUrl == null || publicImageUrl.isEmpty) &&
            frontImagePath != null &&
            frontImagePath.isNotEmpty
        ? _productRepository.createSubmittedProductPhotoSignedUrl(
            frontImagePath,
          )
        : null;
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final productName = product.productName.isEmpty
        ? 'Bilinmeyen Ürün'
        : product.productName;
    final brand = product.brands.isEmpty ? 'Bilinmeyen Marka' : product.brands;
    final displayName = _displayProductName(productName, brand);
    final category = product.category?.trim();
    final showCategory =
        category != null && category.isNotEmpty && category != 'Belirsiz';
    final missingNutritionCount = [
      product.energyKcal,
      product.fat,
      product.saturatedFat,
      product.sugars,
      product.fiber,
      product.protein,
      product.salt,
    ].where((value) => value == null).length;
    final hasIncompleteNutrition = missingNutritionCount > 0;
    final hasInsufficientNutrition = missingNutritionCount >= 3;
    debugPrint(
      'Product nutrition debug: '
      'energyKcal=${product.energyKcal}, '
      'fat=${product.fat}, '
      'saturatedFat=${product.saturatedFat}, '
      'sugars=${product.sugars}, '
      'fiber=${product.fiber}, '
      'protein=${product.protein}, '
      'salt=${product.salt}',
    );
    final scoreResult = const LabelWiseScoreEngine().calculate(product);

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
                  _StaggeredSection(
                    animation: _entranceController,
                    start: 0,
                    child: _ProductImageCard(
                      imageUrl: product.imageUrl,
                      signedFrontImageUrl: _signedFrontImageUrl,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _StaggeredSection(
                    animation: _entranceController,
                    start: 0.06,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: const Color(0xFF17211B),
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Marka: $brand',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: const Color(0xFF657069)),
                        ),
                        if (showCategory) ...[
                          const SizedBox(height: 10),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1EB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              child: Text(
                                'Kategori: $category',
                                style: const TextStyle(
                                  color: Color(0xFF42614F),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _StaggeredSection(
                    animation: _entranceController,
                    start: 0.12,
                    child: _LabelWiseScoreCard(
                      result: scoreResult,
                      animation: _entranceController,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StaggeredSection(
                    animation: _entranceController,
                    start: 0.18,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _NutriScoreBadge(grade: product.nutriscoreGrade),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StaggeredSection(
                    animation: _entranceController,
                    start: 0.21,
                    child: _DataTrustCard(
                      product: product,
                      hasIncompleteNutrition: hasIncompleteNutrition,
                      onCorrection: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                CorrectionReportScreen(product: product),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  _StaggeredSection(
                    animation: _entranceController,
                    start: 0.24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Beslenme Değerleri',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF17211B),
                                    ),
                              ),
                            ),
                            if (hasInsufficientNutrition) ...[
                              const SizedBox(width: 10),
                              const _MissingDataBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),
                        _NutrientGrid(product: product),
                        if (hasInsufficientNutrition) ...[
                          const SizedBox(height: 14),
                          _MissingNutritionHelperCard(barcode: product.barcode),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _StaggeredSection(
                    animation: _entranceController,
                    start: 0.30,
                    child: _ScoreReasonsCard(product: product),
                  ),
                  const SizedBox(height: 20),
                  _StaggeredSection(
                    animation: _entranceController,
                    start: 0.36,
                    child: _AnalysisCard(product: product),
                  ),
                  const SizedBox(height: 20),
                  _StaggeredSection(
                    animation: _entranceController,
                    start: 0.42,
                    child: const _PremiumAlternativesCard(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _displayProductName(String productName, String brand) {
    final trimmedName = productName.trim();
    final trimmedBrand = brand.trim();
    if (trimmedBrand.isEmpty || trimmedBrand == 'Bilinmeyen Marka') {
      return trimmedName;
    }

    final normalizedName = _normalizeForComparison(trimmedName);
    final normalizedBrand = _normalizeForComparison(trimmedBrand);
    return normalizedName.startsWith(normalizedBrand)
        ? trimmedName
        : '$trimmedBrand $trimmedName';
  }

  String _normalizeForComparison(String value) {
    return value.replaceAll('İ', 'I').toLowerCase();
  }
}

class _StaggeredSection extends StatelessWidget {
  const _StaggeredSection({
    required this.animation,
    required this.start,
    required this.child,
  });

  final Animation<double> animation;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: SizedBox(width: double.infinity, child: child),
      builder: (context, child) {
        final rawProgress = ((animation.value - start) / 0.42).clamp(0.0, 1.0);
        final progress = Curves.easeOutCubic.transform(rawProgress);

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }
}

class _MissingDataBadge extends StatelessWidget {
  const _MissingDataBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECE9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          'Veri Eksik',
          style: TextStyle(
            color: Color(0xFF657069),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MissingNutritionHelperCard extends StatelessWidget {
  const _MissingNutritionHelperCard({required this.barcode});

  final String barcode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE4DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu ürünü geliştirmemize yardımcı olun',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF26342C),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Beslenme bilgileri eksik olan ürünleri inceleyerek LabelWise veritabanını geliştirebilirsiniz.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: const Color(0xFF657069),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      SubmitProductScreen(initialBarcode: barcode),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF175C3B),
              side: const BorderSide(color: Color(0xFFAAC0B2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('İncelemeye Gönder'),
          ),
        ],
      ),
    );
  }
}

class _NutrientGrid extends StatelessWidget {
  const _NutrientGrid({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final nutrients = [
      _NutrientData(
        icon: Icons.bolt_rounded,
        label: 'Enerji',
        amount: product.energyKcal,
        unit: 'kcal',
      ),
      _NutrientData(
        icon: Icons.water_drop_outlined,
        label: 'Yağ',
        amount: product.fat,
        unit: 'g',
      ),
      _NutrientData(
        icon: Icons.opacity_rounded,
        label: 'Doymuş Yağ',
        amount: product.saturatedFat,
        unit: 'g',
        severity: _saturatedFatSeverity(product.saturatedFat),
      ),
      _NutrientData(
        icon: Icons.cookie_outlined,
        label: 'Şeker',
        amount: product.sugars,
        unit: 'g',
        severity: _sugarSeverity(product.sugars),
      ),
      _NutrientData(
        icon: Icons.grass_rounded,
        label: 'Lif',
        amount: product.fiber,
        unit: 'g',
      ),
      _NutrientData(
        icon: Icons.fitness_center_rounded,
        label: 'Protein',
        amount: product.protein,
        unit: 'g',
      ),
      _NutrientData(
        icon: Icons.grain_rounded,
        label: 'Tuz',
        amount: product.salt,
        unit: 'g',
        severity: _saltSeverity(product.salt),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final nutrient in nutrients)
              SizedBox(
                width: itemWidth,
                height: 154,
                child: _NutrientCard(nutrient: nutrient),
              ),
          ],
        );
      },
    );
  }
}

class _NutrientCard extends StatelessWidget {
  const _NutrientCard({required this.nutrient});

  final _NutrientData nutrient;

  @override
  Widget build(BuildContext context) {
    final severity = nutrient.severity;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: const Color(0x12000000),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2ED),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    nutrient.icon,
                    size: 19,
                    color: const Color(0xFF236443),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nutrient.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF59635D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (nutrient.amount case final amount?)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatNumber(amount),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF17211B),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    nutrient.unit,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF78847C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              Text(
                'Veri Yok',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF8A928D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (severity != null) ...[
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: severity.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  child: Text(
                    severity.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: severity.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreReasonsCard extends StatelessWidget {
  const _ScoreReasonsCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (!product.hasNutritionData) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        shadowColor: const Color(0x14000000),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Beslenme verileri eksik olduğu için değerlendirme yapılamadı.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: const Color(0xFF657069),
            ),
          ),
        ),
      );
    }

    final reasons = _buildReasons(product);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: const Color(0x14000000),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF236443),
                ),
                const SizedBox(width: 10),
                Text(
                  'Neden bu puan?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF17211B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < reasons.length; index++) ...[
              _ReasonRow(reason: reasons[index]),
              if (index != reasons.length - 1) const SizedBox(height: 13),
            ],
          ],
        ),
      ),
    );
  }

  List<_ScoreReason> _buildReasons(Product product) {
    final reasons = <_ScoreReason>[];
    final values = [
      product.energyKcal,
      product.fat,
      product.saturatedFat,
      product.sugars,
      product.fiber,
      product.protein,
      product.salt,
    ];

    if (values.any((value) => value == null)) {
      reasons.add(
        const _ScoreReason(
          text: 'Besin değerleri eksik olduğu için değerlendirme sınırlı',
          color: Color(0xFF7A827D),
          icon: Icons.info_outline_rounded,
        ),
      );
    }
    if (product.sugars case final value?) {
      final severity = _sugarSeverity(value)!;
      reasons.add(
        _ScoreReason(
          text: 'Şeker ${severity.label.toLowerCase()}',
          color: severity.color,
        ),
      );
    }
    if (product.salt case final value?) {
      final severity = _saltSeverity(value)!;
      reasons.add(
        _ScoreReason(
          text: 'Tuz ${severity.label.toLowerCase()}',
          color: severity.color,
        ),
      );
    }
    if (product.saturatedFat case final value?) {
      final severity = _saturatedFatSeverity(value)!;
      reasons.add(
        _ScoreReason(
          text: 'Doymuş yağ ${severity.label.toLowerCase()}',
          color: severity.color,
        ),
      );
    }
    if (product.protein != null && product.protein! >= 10) {
      reasons.add(
        const _ScoreReason(
          text: 'Protein iyi',
          color: Color(0xFF27844B),
          icon: Icons.check_rounded,
        ),
      );
    }
    if (product.fiber != null && product.fiber! >= 3) {
      reasons.add(
        const _ScoreReason(
          text: 'Lif iyi',
          color: Color(0xFF27844B),
          icon: Icons.check_rounded,
        ),
      );
    }
    if (reasons.isEmpty) {
      reasons.add(
        const _ScoreReason(
          text: 'Mevcut besin değerleri üzerinden hesaplandı',
          color: Color(0xFF4A8A67),
          icon: Icons.check_rounded,
        ),
      );
    }

    return reasons.take(4).toList(growable: false);
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({required this.reason});

  final _ScoreReason reason;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: reason.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(reason.icon, size: 15, color: reason.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            reason.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4B5750),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreReason {
  const _ScoreReason({
    required this.text,
    required this.color,
    this.icon = Icons.circle,
  });

  final String text;
  final Color color;
  final IconData icon;
}

class _NutrientData {
  const _NutrientData({
    required this.icon,
    required this.label,
    required this.amount,
    required this.unit,
    this.severity,
  });

  final IconData icon;
  final String label;
  final double? amount;
  final String unit;
  final _NutrientSeverity? severity;
}

class _NutrientSeverity {
  const _NutrientSeverity(this.label, this.color);

  final String label;
  final Color color;
}

String _formatNumber(double value) {
  final number = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return number;
}

_NutrientSeverity? _sugarSeverity(double? value) {
  if (value == null) return null;
  if (value >= 20) {
    return const _NutrientSeverity('Çok yüksek', Color(0xFFB84A3A));
  }
  if (value >= 10) {
    return const _NutrientSeverity('Yüksek', Color(0xFFD56A31));
  }
  if (value >= 5) {
    return const _NutrientSeverity('Orta', Color(0xFFB38416));
  }
  return const _NutrientSeverity('Düşük', Color(0xFF27844B));
}

_NutrientSeverity? _saturatedFatSeverity(double? value) {
  if (value == null) return null;
  if (value >= 10) {
    return const _NutrientSeverity('Çok yüksek', Color(0xFFB84A3A));
  }
  if (value >= 5) {
    return const _NutrientSeverity('Yüksek', Color(0xFFD56A31));
  }
  if (value >= 2) {
    return const _NutrientSeverity('Orta', Color(0xFFB38416));
  }
  return const _NutrientSeverity('Düşük', Color(0xFF27844B));
}

_NutrientSeverity? _saltSeverity(double? value) {
  if (value == null) return null;
  if (value >= 1.5) {
    return const _NutrientSeverity('Çok yüksek', Color(0xFFB84A3A));
  }
  if (value >= 0.8) {
    return const _NutrientSeverity('Yüksek', Color(0xFFD56A31));
  }
  if (value >= 0.3) {
    return const _NutrientSeverity('Orta', Color(0xFFB38416));
  }
  return const _NutrientSeverity('Düşük', Color(0xFF27844B));
}

class _LabelWiseScoreCard extends StatelessWidget {
  const _LabelWiseScoreCard({required this.result, required this.animation});

  final LabelWiseScoreResult result;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final score = result.score;
    final visualColor = score == null ? result.color : _scoreRingColor(score);
    final gradientEnd = Color.alphaBlend(
      visualColor.withValues(alpha: 0.10),
      Colors.white,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, gradientEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: visualColor.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D17211B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: score == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yeterli Beslenme Verisi Bulunamadı',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF26342C),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bu ürün için beslenme değerleri henüz yeterli olmadığı için LabelWise Skoru oluşturulamadı.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: const Color(0xFF657069),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD8E0DB)),
                    ),
                    child: const Text(
                      'Bu durum uygulamadan değil, ürün verisinin eksik olmasından kaynaklanmaktadır.',
                      style: TextStyle(height: 1.45, color: Color(0xFF59635D)),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  _AnimatedScoreRing(
                    score: score,
                    color: visualColor,
                    animation: animation,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LabelWise Score',
                          style: TextStyle(
                            color: Color(0xFF657069),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          result.category,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: const Color(0xFF17211B),
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _helperText(score),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF59635D),
                                height: 1.35,
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

  String _helperText(int score) {
    if (score >= 90) return 'Mükemmel bir tercih.';
    if (score >= 80) return 'Genel olarak güçlü bir seçenek.';
    if (score >= 70) return 'Genel olarak dikkatli tüketilebilir.';
    if (score >= 60) return 'Dengeli tüketim daha uygun olabilir.';
    if (score >= 50) {
      return 'Bazı değerler nedeniyle dikkatli tüketilebilir.';
    }
    if (score >= 40) return 'Sık tüketim için uygun olmayabilir.';
    if (score >= 20) return 'Ara sıra tüketim daha uygun olabilir.';
    return 'Beslenme açısından zayıf bir tercih.';
  }
}

class _AnimatedScoreRing extends StatelessWidget {
  const _AnimatedScoreRing({
    required this.score,
    required this.color,
    required this.animation,
  });

  final int score;
  final Color color;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final rawProgress = ((animation.value - 0.12) / 0.88).clamp(0.0, 1.0);
        final progress = Curves.easeOutCubic.transform(rawProgress);
        final value = score * progress;

        return SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  '${value.round()}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: const Color(0xFF17211B),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Color _scoreRingColor(int score) {
  if (score >= 90) return const Color(0xFF238447);
  if (score >= 80) return const Color(0xFF63A94B);
  if (score >= 70) return const Color(0xFF8EAD3D);
  if (score >= 60) return const Color(0xFFA6AA3D);
  if (score >= 50) return const Color(0xFFD58B2A);
  if (score >= 30) return const Color(0xFFD86138);
  return const Color(0xFFC33F39);
}

class _ProductImageCard extends StatelessWidget {
  const _ProductImageCard({
    required this.imageUrl,
    required this.signedFrontImageUrl,
  });

  final String? imageUrl;
  final Future<String?>? signedFrontImageUrl;

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
        child: url != null && url.isNotEmpty
            ? _ProductNetworkImage(url: url)
            : signedFrontImageUrl == null
            ? const _ImagePlaceholder()
            : FutureBuilder<String?>(
                future: signedFrontImageUrl,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ColoredBox(
                      color: Color(0xFFF2F5F3),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final signedUrl = snapshot.data;
                  return signedUrl == null || signedUrl.isEmpty
                      ? const _ImagePlaceholder()
                      : _ProductNetworkImage(url: signedUrl);
                },
              ),
      ),
    );
  }
}

class _ProductNetworkImage extends StatelessWidget {
  const _ProductNetworkImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const _ImagePlaceholder();
      },
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: _badgeColor(normalizedGrade),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'Nutri-Score: $displayGrade',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _showNutriScoreInfo(context),
          tooltip: 'Nutri-Score hakkında bilgi',
          icon: const Icon(Icons.info_outline_rounded, size: 20),
          color: const Color(0xFF657069),
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Future<void> _showNutriScoreInfo(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Nutri-Score nedir?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            "Nutri-Score, Avrupa'da kullanılan bilimsel bir ön yüz beslenme etiketidir.\n"
            'Ürünleri A (en iyi) ile E (en düşük) arasında değerlendirir.\n\n'
            "LabelWise Skoru ise Nutri-Score'un yanında besin değerlerini daha anlaşılır şekilde yorumlamak için geliştirilmiştir.",
            style: TextStyle(height: 1.5, color: Color(0xFF4B5750)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anladım'),
            ),
          ],
        );
      },
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

class _DataTrustCard extends StatelessWidget {
  const _DataTrustCard({
    required this.product,
    required this.hasIncompleteNutrition,
    required this.onCorrection,
  });

  final Product product;
  final bool hasIncompleteNutrition;
  final VoidCallback onCorrection;

  @override
  Widget build(BuildContext context) {
    final isLabelWiseData =
        product.source.trim().toLowerCase() == 'user_submission';
    final badgeText = isLabelWiseData ? 'LabelWise verisi' : 'Topluluk verisi';
    final description = isLabelWiseData
        ? 'Bu ürün bilgileri LabelWise incelemesinden geçirilerek veritabanına eklenmiştir.'
        : 'Bu ürün bilgileri OpenFoodFacts gibi topluluk kaynaklarından alınmış olabilir. Ambalaj üzerindeki bilgilerle küçük farklılıklar gösterebilir.';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: const Color(0x12000000),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Veri Güvenilirliği',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF17211B),
              ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: isLabelWiseData
                    ? const Color(0xFFE7F3EB)
                    : const Color(0xFFF0F2F1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: isLabelWiseData
                        ? const Color(0xFF2F7049)
                        : const Color(0xFF59645D),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: const Color(0xFF657069),
              ),
            ),
            if (hasIncompleteNutrition) ...[
              const SizedBox(height: 10),
              const Text(
                'Beslenme verileri eksik veya sınırlı olabilir.',
                style: TextStyle(
                  height: 1.4,
                  color: Color(0xFF78827C),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE8ECE9)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bu bilgiler doğru değil mi?',
                    style: TextStyle(
                      color: Color(0xFF4B5750),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onCorrection,
                  child: const Text('Düzeltme Bildir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatefulWidget {
  const _AnalysisCard({required this.product});

  final Product product;

  @override
  State<_AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<_AnalysisCard> {
  final AnalysisService _analysisService = const AnalysisService();
  final ProductRepository _productRepository = ProductRepository();

  AnalysisResult? _result;
  bool _isLoading = false;
  bool _isCached = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final cachedResult = _cachedAnalysis(widget.product);
    if (cachedResult == null) {
      debugPrint('AI cache miss');
      return;
    }

    debugPrint('AI cache hit');
    _result = cachedResult;
    _isCached = true;
  }

  Future<void> _generateAnalysis({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedResult = _cachedAnalysis(widget.product);
      if (cachedResult != null) {
        debugPrint('AI cache hit');
        setState(() {
          _result = cachedResult;
          _isCached = true;
          _errorMessage = null;
        });
        return;
      }
      debugPrint('AI cache miss');
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Calling OpenAI analysis');
      final result = await _analysisService.generateAnalysis(widget.product);
      await _productRepository.updateAiAnalysis(
        barcode: widget.product.barcode,
        summary: result.summary,
        riskLevel: result.riskLevel,
      );
      debugPrint('AI analysis saved to Supabase');

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _isLoading = false;
        _isCached = false;
      });
    } on Object catch (error, stackTrace) {
      debugPrint('AI analysis failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Yapay zeka yorumu oluşturulamadı. Lütfen tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: const Color(0x12000000),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yapay Zeka Yorumu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF17211B),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Güvenli yorum hazırlanıyor...',
                      style: TextStyle(color: Color(0xFF657069)),
                    ),
                  ],
                ),
              )
            else if (result != null) ...[
              Text(
                result.summary,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: const Color(0xFF3D4841),
                ),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _riskColor(result.riskLevel).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    'Risk seviyesi: ${_localizedRiskLevel(result.riskLevel)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _riskColor(result.riskLevel),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (_isCached) ...[
                const SizedBox(height: 10),
                const Text(
                  'Önceden oluşturulmuş yorum',
                  style: TextStyle(fontSize: 12, color: Color(0xFF78847C)),
                ),
              ],
            ] else ...[
              Text(
                'Beslenme değerlerine göre kısa ve anlaşılır bir yorum oluşturabilirsiniz.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: const Color(0xFF657069),
                ),
              ),
              if (_errorMessage case final message?) ...[
                const SizedBox(height: 12),
                Text(message, style: const TextStyle(color: Color(0xFFB3261E))),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _generateAnalysis(),
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(
                  _errorMessage == null ? 'Analizi Oluştur' : 'Tekrar Dene',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _localizedRiskLevel(String riskLevel) {
    return switch (_normalizeRiskLevel(riskLevel)) {
      'düşük' => 'Düşük',
      'orta' => 'Orta',
      'yüksek' => 'Yüksek',
      _ => 'Bilinmiyor',
    };
  }

  Color _riskColor(String riskLevel) {
    return switch (_normalizeRiskLevel(riskLevel)) {
      'düşük' => const Color(0xFF27844B),
      'orta' => const Color(0xFFB38416),
      'yüksek' => const Color(0xFFB84A3A),
      _ => const Color(0xFF7A827D),
    };
  }

  AnalysisResult? _cachedAnalysis(Product product) {
    final summary = product.aiSummary?.trim();
    final riskLevel = product.aiRiskLevel?.trim();
    if (summary == null ||
        summary.isEmpty ||
        riskLevel == null ||
        riskLevel.isEmpty) {
      return null;
    }

    return AnalysisResult(
      summary: summary,
      riskLevel: _normalizeRiskLevel(riskLevel),
    );
  }

  String _normalizeRiskLevel(String riskLevel) {
    return switch (riskLevel.trim().toLowerCase()) {
      'low' || 'düşük' => 'düşük',
      'medium' || 'orta' => 'orta',
      'high' || 'yüksek' => 'yüksek',
      _ => 'bilinmiyor',
    };
  }
}

class _PremiumAlternativesCard extends StatelessWidget {
  const _PremiumAlternativesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173F2D), Color(0xFF0E2E22)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24123828),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
                color: Color(0xFFFFD782),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Daha Sağlıklı Alternatifler',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD782),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          child: Text(
                            'Premium',
                            style: TextStyle(
                              color: Color(0xFF3D2B08),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Benzer ürünler arasında daha iyi seçenekleri keşfedin.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFD4E3DA),
                      height: 1.4,
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
