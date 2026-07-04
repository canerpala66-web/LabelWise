import 'package:flutter/material.dart';
import 'package:labelwise/features/admin/models/submitted_product.dart';
import 'package:labelwise/features/scanner/data/submitted_product_repository.dart';

class SubmittedProductDetailScreen extends StatefulWidget {
  const SubmittedProductDetailScreen({required this.submissionId, super.key});

  final String submissionId;

  @override
  State<SubmittedProductDetailScreen> createState() =>
      _SubmittedProductDetailScreenState();
}

class _SubmittedProductDetailScreenState
    extends State<SubmittedProductDetailScreen> {
  final SubmittedProductRepository _repository = SubmittedProductRepository();
  final TextEditingController _reviewNoteController = TextEditingController();

  late Future<SubmittedProduct?> _submission;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _submission = _loadSubmission();
  }

  Future<SubmittedProduct?> _loadSubmission() async {
    final submission = await _repository.fetchSubmittedProductById(
      widget.submissionId,
    );
    if (mounted && submission != null && _reviewNoteController.text.isEmpty) {
      _reviewNoteController.text = submission.reviewNote ?? '';
    }
    return submission;
  }

  Future<void> _reload() async {
    final future = _loadSubmission();
    setState(() {
      _submission = future;
    });
    await future;
  }

  Future<void> _approve(SubmittedProduct submission) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      await _repository.approveSubmission(
        submission.id,
        reviewNote: _reviewNoteController.text,
      );
      if (!mounted) return;
      await _showCompletion(
        'Ürün onaylandı ve LabelWise veritabanına aktarıldı.',
      );
    } on Object catch (error, stackTrace) {
      debugPrint('AdminReview: failed step=approve UI, error=$error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      _showError('Ürün onaylanamadı. Lütfen tekrar deneyin.');
    }
  }

  Future<void> _confirmReject(SubmittedProduct submission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ürün reddedilsin mi?'),
          content: const Text('Bu gönderim ana veritabanına eklenmeyecek.'),
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
    setState(() {
      _isProcessing = true;
    });
    try {
      await _repository.rejectSubmission(
        submission.id,
        reviewNote: _reviewNoteController.text,
      );
      if (!mounted) return;
      await _showCompletion('Gönderim reddedildi.');
    } on Object catch (error, stackTrace) {
      debugPrint('AdminReview: failed step=reject UI, error=$error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      _showError('Gönderim reddedilemedi. Lütfen tekrar deneyin.');
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
    if (mounted) {
      Navigator.of(context).pop(true);
    }
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
          'Ürün İncelemesi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F7F5),
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<SubmittedProduct?>(
        future: _submission,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DetailErrorState(onRetry: _reload);
          }

          final submission = snapshot.data;
          if (submission == null) {
            return const Center(child: Text('Gönderim bulunamadı.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailSection(
                      title: 'Temel Bilgiler',
                      children: [
                        _DetailRow(label: 'Barkod', value: submission.barcode),
                        _DetailRow(label: 'Ürün adı', value: submission.name),
                        _DetailRow(
                          label: 'Marka',
                          value: _textOrFallback(submission.brand),
                        ),
                        _DetailRow(
                          label: 'Gönderim tarihi',
                          value: _formatDate(submission.createdAt),
                        ),
                        _DetailRow(
                          label: 'Durum',
                          value: _statusLabel(submission.status),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailSection(
                      title: 'Fotoğraflar',
                      children: _photoWidgets(submission),
                    ),
                    const SizedBox(height: 16),
                    _DetailSection(
                      title: 'Beslenme Değerleri',
                      children: [
                        _DetailRow(
                          label: 'Enerji',
                          value: _nutritionValue(submission.energyKcal, 'kcal'),
                        ),
                        _DetailRow(
                          label: 'Yağ',
                          value: _nutritionValue(submission.fat, 'g'),
                        ),
                        _DetailRow(
                          label: 'Doymuş Yağ',
                          value: _nutritionValue(submission.saturatedFat, 'g'),
                        ),
                        _DetailRow(
                          label: 'Şeker',
                          value: _nutritionValue(submission.sugars, 'g'),
                        ),
                        _DetailRow(
                          label: 'Lif',
                          value: _nutritionValue(submission.fiber, 'g'),
                        ),
                        _DetailRow(
                          label: 'Protein',
                          value: _nutritionValue(submission.protein, 'g'),
                        ),
                        _DetailRow(
                          label: 'Tuz',
                          value: _nutritionValue(submission.salt, 'g'),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailSection(
                      title: 'İçindekiler',
                      children: [
                        Text(
                          submission.ingredientsText?.trim().isNotEmpty == true
                              ? submission.ingredientsText!
                              : 'İçindekiler bilgisi girilmemiş.',
                          style: const TextStyle(
                            height: 1.5,
                            color: Color(0xFF4B5750),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailSection(
                      title: 'İnceleme Notu',
                      children: [
                        TextField(
                          controller: _reviewNoteController,
                          enabled: submission.status == 'pending',
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
                    if (submission.status == 'pending') ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _approve(submission),
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
                              : const Text('Onayla ve Ürüne Aktar'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _confirmReject(submission),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB84A3A),
                            side: const BorderSide(color: Color(0xFFD8A39B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Reddet'),
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

  List<Widget> _photoWidgets(SubmittedProduct submission) {
    final photos = <({String title, String? path})>[
      (title: 'Ürün Ön Yüzü', path: submission.frontImagePath),
      (title: 'Beslenme Tablosu', path: submission.nutritionImagePath),
      (title: 'İçindekiler', path: submission.ingredientsImagePath),
    ];

    return [
      for (var index = 0; index < photos.length; index++) ...[
        _SignedPhotoPreview(
          repository: _repository,
          title: photos[index].title,
          path: photos[index].path,
        ),
        if (index != photos.length - 1) const SizedBox(height: 14),
      ],
    ];
  }

  String _nutritionValue(double? value, String unit) {
    if (value == null) return 'Veri yok';
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$formatted $unit';
  }

  String _textOrFallback(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? 'Belirtilmemiş' : text;
  }
}

class _SignedPhotoPreview extends StatefulWidget {
  const _SignedPhotoPreview({
    required this.repository,
    required this.title,
    required this.path,
  });

  final SubmittedProductRepository repository;
  final String title;
  final String? path;

  @override
  State<_SignedPhotoPreview> createState() => _SignedPhotoPreviewState();
}

class _SignedPhotoPreviewState extends State<_SignedPhotoPreview> {
  late final Future<String?> _signedUrl;

  @override
  void initState() {
    super.initState();
    _signedUrl = widget.repository.createPhotoSignedUrl(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (path == null || path.isEmpty)
          const _MissingPhotoState()
        else
          FutureBuilder<String?>(
            future: _signedUrl,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final signedUrl = snapshot.data;
              if (snapshot.hasError || signedUrl == null || signedUrl.isEmpty) {
                return _PhotoPathFallback(path: path);
              }

              return Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  signedUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint(
                      'AdminPhotoPreview: image load failed '
                      'path=$path, error=$error',
                    );
                    return _PhotoPathFallback(path: path);
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}

class _PhotoPathFallback extends StatelessWidget {
  const _PhotoPathFallback({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Fotoğraf önizlemesi yüklenemedi.\n$path',
        style: const TextStyle(
          height: 1.4,
          color: Color(0xFF7A827D),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MissingPhotoState extends StatelessWidget {
  const _MissingPhotoState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Fotoğraf eklenmemiş.',
        style: TextStyle(color: Color(0xFF637068)),
      ),
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
                  value.isEmpty ? 'Belirtilmemiş' : value,
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
          const Text('Gönderim bilgileri yüklenemedi.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }
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
