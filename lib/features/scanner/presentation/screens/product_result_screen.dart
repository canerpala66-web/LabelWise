import 'package:flutter/material.dart';
import 'package:labelwise/features/analysis/models/analysis_result.dart';
import 'package:labelwise/features/analysis/services/analysis_service.dart';
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
                  _AnalysisCard(product: product),
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

class _AnalysisCard extends StatefulWidget {
  const _AnalysisCard({required this.product});

  final Product product;

  @override
  State<_AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<_AnalysisCard> {
  final AnalysisService _analysisService = const AnalysisService();

  AnalysisResult? _result;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _generateAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _analysisService.generateAnalysis(widget.product);

      if (!mounted) {
        return;
      }

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } on Object catch (error, stackTrace) {
      debugPrint('Manual LabelWise Analysis error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Analiz oluşturulamadı. Lütfen tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

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
              'Yapay Zeka Yorumu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF17211B),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (result != null) ...[
              Text(
                'Sağlık Puanı',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF657069),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${result.labelwiseScore}/100',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17211B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Risk Seviyesi',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF657069),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _localizedRiskLevel(result.riskLevel),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17211B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                result.summary,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: const Color(0xFF3D4841),
                ),
              ),
            ] else ...[
              if (_errorMessage case final message?) ...[
                Text(message, style: const TextStyle(color: Color(0xFFB3261E))),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: _generateAnalysis,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Analizi Oluştur'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _localizedRiskLevel(String riskLevel) {
    return switch (riskLevel) {
      'low' => 'Düşük',
      'high' => 'Yüksek',
      _ => 'Orta',
    };
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
