import 'package:flutter/material.dart';
import 'package:labelwise/features/corrections/data/product_correction_repository.dart';
import 'package:labelwise/features/corrections/models/product_correction_report.dart';
import 'package:labelwise/features/scanner/data/product.dart';

class CorrectionReportDetailScreen extends StatefulWidget {
  const CorrectionReportDetailScreen({required this.reportId, super.key});

  final String reportId;

  @override
  State<CorrectionReportDetailScreen> createState() =>
      _CorrectionReportDetailScreenState();
}

class _CorrectionReportDetailScreenState
    extends State<CorrectionReportDetailScreen> {
  final ProductCorrectionRepository _repository = ProductCorrectionRepository();
  final TextEditingController _reviewNoteController = TextEditingController();

  late Future<_CorrectionDetailData?> _detail;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _detail = _load();
  }

  Future<_CorrectionDetailData?> _load() async {
    final report = await _repository.fetchCorrectionReportById(widget.reportId);
    if (report == null) return null;
    final product = await _repository.fetchProductByBarcode(report.barcode);
    if (mounted && _reviewNoteController.text.isEmpty) {
      _reviewNoteController.text = report.reviewNote ?? '';
    }
    return _CorrectionDetailData(report: report, product: product);
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() {
      _detail = future;
    });
    await future;
  }

  Future<void> _approve(ProductCorrectionReport report) async {
    setState(() => _isProcessing = true);
    try {
      await _repository.approveCorrectionReport(
        report.id,
        reviewNote: _reviewNoteController.text,
      );
      if (!mounted) return;
      await _showCompletion(
        'Düzeltme onaylandı ve ürün bilgileri güncellendi.',
      );
    } on Object catch (error, stackTrace) {
      debugPrint('CorrectionAdmin: failed step=approve UI, error=$error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showError('Düzeltme onaylanamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<void> _confirmReject(ProductCorrectionReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Düzeltme reddedilsin mi?'),
          content: const Text('Bu bildirim ana ürün verisini değiştirmeyecek.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB84A3A),
              ),
              child: const Text('Reddet'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await _repository.rejectCorrectionReport(
        report.id,
        reviewNote: _reviewNoteController.text,
      );
      if (!mounted) return;
      await _showCompletion('Düzeltme bildirimi reddedildi.');
    } on Object catch (error, stackTrace) {
      debugPrint('CorrectionAdmin: failed step=reject UI, error=$error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showError('Düzeltme reddedilemedi. Lütfen tekrar deneyin.');
    }
  }

  Future<void> _showCompletion(String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF27844B),
            size: 38,
          ),
          content: Text(message, textAlign: TextAlign.center),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _reviewNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text(
          'Düzeltme İncelemesi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F7F5),
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<_CorrectionDetailData?>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DetailErrorState(onRetry: _reload);
          }
          final detail = snapshot.data;
          if (detail == null) {
            return const Center(child: Text('Düzeltme bildirimi bulunamadı.'));
          }

          final report = detail.report;
          final product = detail.product;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailSection(
                      title: 'Ürün Bilgileri',
                      children: [
                        _DetailRow(label: 'Barkod', value: report.barcode),
                        _DetailRow(
                          label: 'Ürün adı',
                          value: _text(report.productName),
                        ),
                        _DetailRow(label: 'Marka', value: _text(report.brand)),
                        _DetailRow(
                          label: 'Bildirim tarihi',
                          value: _formatDate(report.createdAt),
                        ),
                        _DetailRow(
                          label: 'Durum',
                          value: _statusLabel(report.status),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailSection(
                      title: 'Bildirilen Sorun',
                      children: [
                        Text(
                          report.reportedIssue,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF26342C),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          report.note?.trim().isNotEmpty == true
                              ? report.note!
                              : 'Ek not girilmemiş.',
                          style: const TextStyle(
                            height: 1.5,
                            color: Color(0xFF637068),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _NutritionSection(
                      title: 'Mevcut Ürün Değerleri',
                      product: product,
                    ),
                    const SizedBox(height: 16),
                    _SuggestedNutritionSection(report: report),
                    const SizedBox(height: 16),
                    _ComparisonSection(report: report, product: product),
                    const SizedBox(height: 16),
                    _DetailSection(
                      title: 'Admin İnceleme Notu',
                      children: [
                        TextField(
                          controller: _reviewNoteController,
                          enabled: report.status == 'pending',
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'İnceleme notu',
                            filled: true,
                            fillColor: const Color(0xFFF7F9F7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (report.status == 'pending') ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: _isProcessing || product == null
                              ? null
                              : () => _approve(report),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF175C3B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Düzeltmeyi Onayla'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _confirmReject(report),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB84A3A),
                            side: const BorderSide(color: Color(0xFFD8A39B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Düzeltmeyi Reddet'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CorrectionDetailData {
  const _CorrectionDetailData({required this.report, required this.product});

  final ProductCorrectionReport report;
  final Product? product;
}

class _NutritionSection extends StatelessWidget {
  const _NutritionSection({required this.title, required this.product});

  final String title;
  final Product? product;

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return const _DetailSection(
        title: 'Mevcut Ürün Değerleri',
        children: [
          Text(
            'Bu barkoda ait ürün ana veritabanında bulunamadı.',
            style: TextStyle(height: 1.5, color: Color(0xFF637068)),
          ),
        ],
      );
    }
    return _DetailSection(
      title: title,
      children: _nutritionRows(
        energyKcal: product!.energyKcal,
        fat: product!.fat,
        saturatedFat: product!.saturatedFat,
        sugars: product!.sugars,
        fiber: product!.fiber,
        protein: product!.protein,
        salt: product!.salt,
        nullText: 'Veri yok',
      ),
    );
  }
}

class _SuggestedNutritionSection extends StatelessWidget {
  const _SuggestedNutritionSection({required this.report});

  final ProductCorrectionReport report;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Önerilen Düzeltmeler',
      children: _nutritionRows(
        energyKcal: report.correctedEnergyKcal,
        fat: report.correctedFat,
        saturatedFat: report.correctedSaturatedFat,
        sugars: report.correctedSugars,
        fiber: report.correctedFiber,
        protein: report.correctedProtein,
        salt: report.correctedSalt,
        nullText: 'Değişiklik yok',
      ),
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  const _ComparisonSection({required this.report, required this.product});

  final ProductCorrectionReport report;
  final Product? product;

  @override
  Widget build(BuildContext context) {
    final changes =
        <({String label, double? current, double suggested, String unit})>[
          if (report.correctedEnergyKcal case final value?)
            (
              label: 'Enerji',
              current: product?.energyKcal,
              suggested: value,
              unit: 'kcal',
            ),
          if (report.correctedFat case final value?)
            (label: 'Yağ', current: product?.fat, suggested: value, unit: 'g'),
          if (report.correctedSaturatedFat case final value?)
            (
              label: 'Doymuş Yağ',
              current: product?.saturatedFat,
              suggested: value,
              unit: 'g',
            ),
          if (report.correctedSugars case final value?)
            (
              label: 'Şeker',
              current: product?.sugars,
              suggested: value,
              unit: 'g',
            ),
          if (report.correctedFiber case final value?)
            (
              label: 'Lif',
              current: product?.fiber,
              suggested: value,
              unit: 'g',
            ),
          if (report.correctedProtein case final value?)
            (
              label: 'Protein',
              current: product?.protein,
              suggested: value,
              unit: 'g',
            ),
          if (report.correctedSalt case final value?)
            (label: 'Tuz', current: product?.salt, suggested: value, unit: 'g'),
        ];

    return _DetailSection(
      title: 'Karşılaştırma',
      children: changes.isEmpty
          ? const [Text('Karşılaştırılacak beslenme düzeltmesi yok.')]
          : [
              for (var index = 0; index < changes.length; index++)
                _ComparisonRow(
                  label: changes[index].label,
                  current: _nutritionValue(
                    changes[index].current,
                    changes[index].unit,
                    nullText: 'Veri yok',
                  ),
                  suggested: _nutritionValue(
                    changes[index].suggested,
                    changes[index].unit,
                    nullText: 'Veri yok',
                  ),
                  isLast: index == changes.length - 1,
                ),
            ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.suggested,
    required this.isLast,
  });

  final String label;
  final String current;
  final String suggested;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Mevcut: $current')),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Color(0xFF78847C),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F3EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Önerilen: $suggested',
                        style: const TextStyle(
                          color: Color(0xFF175C3B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFE7ECE9)),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF17211B),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 126,
                child: Text(
                  label,
                  style: const TextStyle(color: Color(0xFF637068)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF26342C),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFE7ECE9)),
      ],
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Düzeltme bilgileri yüklenemedi.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }
}

List<Widget> _nutritionRows({
  required double? energyKcal,
  required double? fat,
  required double? saturatedFat,
  required double? sugars,
  required double? fiber,
  required double? protein,
  required double? salt,
  required String nullText,
}) {
  final values = [
    (label: 'Enerji', value: energyKcal, unit: 'kcal'),
    (label: 'Yağ', value: fat, unit: 'g'),
    (label: 'Doymuş Yağ', value: saturatedFat, unit: 'g'),
    (label: 'Şeker', value: sugars, unit: 'g'),
    (label: 'Lif', value: fiber, unit: 'g'),
    (label: 'Protein', value: protein, unit: 'g'),
    (label: 'Tuz', value: salt, unit: 'g'),
  ];
  return [
    for (var index = 0; index < values.length; index++)
      _DetailRow(
        label: values[index].label,
        value: _nutritionValue(
          values[index].value,
          values[index].unit,
          nullText: nullText,
        ),
        isLast: index == values.length - 1,
      ),
  ];
}

String _nutritionValue(double? value, String unit, {required String nullText}) {
  if (value == null) return nullText;
  final formatted = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$formatted $unit';
}

String _text(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? 'Belirtilmemiş' : text;
}

String _statusLabel(String status) {
  return switch (status) {
    'approved' => 'Onaylandı',
    'rejected' => 'Reddedildi',
    _ => 'Bekliyor',
  };
}

String _formatDate(DateTime? dateTime) {
  if (dateTime == null) return 'Tarih bilinmiyor';
  final local = dateTime.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}.${twoDigits(local.month)}.${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
