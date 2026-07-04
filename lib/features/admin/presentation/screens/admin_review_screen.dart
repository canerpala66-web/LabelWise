import 'package:flutter/material.dart';
import 'package:labelwise/features/admin/models/submitted_product.dart';
import 'package:labelwise/features/admin/presentation/screens/correction_report_detail_screen.dart';
import 'package:labelwise/features/admin/presentation/screens/submitted_product_detail_screen.dart';
import 'package:labelwise/features/corrections/data/product_correction_repository.dart';
import 'package:labelwise/features/corrections/models/product_correction_report.dart';
import 'package:labelwise/features/scanner/data/submitted_product_repository.dart';

enum _AdminArea { submissions, corrections }

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  _AdminArea _area = _AdminArea.submissions;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F7F5),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Admin İnceleme',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF175C3B),
            indicatorColor: Color(0xFF175C3B),
            tabs: [
              Tab(text: 'Bekleyen'),
              Tab(text: 'Onaylanan'),
              Tab(text: 'Reddedilen'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<_AdminArea>(
                  segments: const [
                    ButtonSegment(
                      value: _AdminArea.submissions,
                      label: Text('Ürün Gönderimleri'),
                      icon: Icon(Icons.inventory_2_outlined),
                    ),
                    ButtonSegment(
                      value: _AdminArea.corrections,
                      label: Text('Veri Düzeltmeleri'),
                      icon: Icon(Icons.edit_note_rounded),
                    ),
                  ],
                  selected: {_area},
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  onSelectionChanged: (selection) {
                    setState(() {
                      _area = selection.first;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                _area == _AdminArea.submissions
                    ? 'İnceleme bekleyen ürünleri kontrol edip onaylayabilir veya reddedebilirsiniz.'
                    : 'Kullanıcıların bildirdiği ürün veri düzeltmelerini inceleyin.',
                style: const TextStyle(height: 1.45, color: Color(0xFF637068)),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: _area == _AdminArea.submissions
                    ? const [
                        _SubmissionList(status: 'pending'),
                        _SubmissionList(status: 'approved'),
                        _SubmissionList(status: 'rejected'),
                      ]
                    : const [
                        _CorrectionList(status: 'pending'),
                        _CorrectionList(status: 'approved'),
                        _CorrectionList(status: 'rejected'),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CorrectionList extends StatefulWidget {
  const _CorrectionList({required this.status});

  final String status;

  @override
  State<_CorrectionList> createState() => _CorrectionListState();
}

class _CorrectionListState extends State<_CorrectionList> {
  final ProductCorrectionRepository _repository = ProductCorrectionRepository();
  late Future<List<ProductCorrectionReport>> _reports;

  @override
  void initState() {
    super.initState();
    _reports = _load();
  }

  Future<List<ProductCorrectionReport>> _load() {
    return _repository.fetchCorrectionReports(status: widget.status);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _reports = future;
    });
    await future;
  }

  Future<void> _openDetail(ProductCorrectionReport report) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CorrectionReportDetailScreen(reportId: report.id),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductCorrectionReport>>(
      future: _reports,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(
            onRetry: _refresh,
            message: 'Düzeltme bildirimleri yüklenemedi.',
          );
        }

        final reports = snapshot.data ?? const [];
        if (reports.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Icon(
                  Icons.fact_check_outlined,
                  size: 44,
                  color: Color(0xFF8A948E),
                ),
                SizedBox(height: 12),
                Text(
                  'İncelenecek düzeltme bildirimi yok.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF637068)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _CorrectionCard(
                report: report,
                onReview: () => _openDetail(report),
              );
            },
          ),
        );
      },
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({required this.report, required this.onReview});

  final ProductCorrectionReport report;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final productName = report.productName?.trim();
    final title = productName == null || productName.isEmpty
        ? 'İsimsiz ürün'
        : productName;
    final brand = report.brand?.trim();
    final note = report.note?.trim();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF17211B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _StatusBadge(status: report.status),
              ],
            ),
            if (brand != null && brand.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(brand, style: const TextStyle(color: Color(0xFF637068))),
            ],
            const SizedBox(height: 12),
            _MetaRow(icon: Icons.qr_code_rounded, text: report.barcode),
            const SizedBox(height: 7),
            _MetaRow(icon: Icons.report_outlined, text: report.reportedIssue),
            const SizedBox(height: 7),
            _MetaRow(
              icon: Icons.schedule_rounded,
              text: _formatDate(report.createdAt),
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(height: 1.4, color: Color(0xFF4B5750)),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              _correctionSummary(report),
              style: const TextStyle(height: 1.4, color: Color(0xFF4B5750)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onReview,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF175C3B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('İncele'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _correctionSummary(ProductCorrectionReport report) {
    final values = <String>[
      if (report.correctedEnergyKcal != null)
        'Enerji ${_number(report.correctedEnergyKcal!)} kcal',
      if (report.correctedFat != null) 'Yağ ${_number(report.correctedFat!)} g',
      if (report.correctedSaturatedFat != null)
        'Doymuş yağ ${_number(report.correctedSaturatedFat!)} g',
      if (report.correctedSugars != null)
        'Şeker ${_number(report.correctedSugars!)} g',
      if (report.correctedFiber != null)
        'Lif ${_number(report.correctedFiber!)} g',
      if (report.correctedProtein != null)
        'Protein ${_number(report.correctedProtein!)} g',
      if (report.correctedSalt != null)
        'Tuz ${_number(report.correctedSalt!)} g',
    ];
    return values.isEmpty ? 'Beslenme düzeltmesi yok.' : values.join(' • ');
  }

  String _number(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class _SubmissionList extends StatefulWidget {
  const _SubmissionList({required this.status});

  final String status;

  @override
  State<_SubmissionList> createState() => _SubmissionListState();
}

class _SubmissionListState extends State<_SubmissionList> {
  final SubmittedProductRepository _repository = SubmittedProductRepository();
  late Future<List<SubmittedProduct>> _submissions;

  @override
  void initState() {
    super.initState();
    _submissions = _load();
  }

  Future<List<SubmittedProduct>> _load() {
    return _repository.fetchSubmittedProducts(status: widget.status);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _submissions = future;
    });
    await future;
  }

  Future<void> _openDetail(SubmittedProduct submission) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) =>
            SubmittedProductDetailScreen(submissionId: submission.id),
      ),
    );
    if (changed == true && mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SubmittedProduct>>(
      future: _submissions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(onRetry: _refresh);
        }

        final submissions = snapshot.data ?? const [];
        if (submissions.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Icon(Icons.inbox_outlined, size: 44, color: Color(0xFF8A948E)),
                SizedBox(height: 12),
                Text(
                  'Bu durumda ürün bulunmuyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF637068)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: submissions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final submission = submissions[index];
              return _SubmissionCard(
                submission: submission,
                onReview: () => _openDetail(submission),
              );
            },
          ),
        );
      },
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.submission, required this.onReview});

  final SubmittedProduct submission;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final brand = submission.brand?.trim();
    final photoLabels = <String>[
      if (submission.frontImagePath != null) 'Ön yüz var',
      if (submission.nutritionImagePath != null) 'Beslenme tablosu var',
      if (submission.ingredientsImagePath != null) 'İçindekiler var',
    ];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    submission.name.isEmpty ? 'İsimsiz ürün' : submission.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF17211B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _StatusBadge(status: submission.status),
              ],
            ),
            if (brand != null && brand.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(brand, style: const TextStyle(color: Color(0xFF637068))),
            ],
            const SizedBox(height: 12),
            _MetaRow(icon: Icons.qr_code_rounded, text: submission.barcode),
            const SizedBox(height: 7),
            _MetaRow(
              icon: Icons.schedule_rounded,
              text: _formatDate(submission.createdAt),
            ),
            const SizedBox(height: 12),
            Text(
              _nutritionSummary(submission),
              style: const TextStyle(height: 1.4, color: Color(0xFF4B5750)),
            ),
            if (photoLabels.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final label in photoLabels) _PhotoPresence(label: label),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onReview,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF175C3B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('İncele'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nutritionSummary(SubmittedProduct submission) {
    final values = <String>[
      if (submission.energyKcal != null)
        'Enerji ${_number(submission.energyKcal!)} kcal',
      if (submission.sugars != null) 'Şeker ${_number(submission.sugars!)} g',
      if (submission.salt != null) 'Tuz ${_number(submission.salt!)} g',
    ];
    return values.isEmpty ? 'Beslenme verisi yok.' : values.join(' • ');
  }

  String _number(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('Onaylandı', const Color(0xFF27844B)),
      'rejected' => ('Reddedildi', const Color(0xFFB84A3A)),
      _ => ('Bekliyor', const Color(0xFFB38416)),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PhotoPresence extends StatelessWidget {
  const _PhotoPresence({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF42614F),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF78847C)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty ? 'Belirtilmemiş' : text,
            style: const TextStyle(color: Color(0xFF637068)),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.onRetry,
    this.message = 'Gönderilen ürünler yüklenemedi.',
  });

  final Future<void> Function() onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF637068)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime? dateTime) {
  if (dateTime == null) return 'Tarih bilinmiyor';
  final local = dateTime.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}.${twoDigits(local.month)}.${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
