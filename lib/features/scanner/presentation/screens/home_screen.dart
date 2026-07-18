import 'package:flutter/material.dart';
import 'package:labelwise/core/analytics/analytics_service.dart';
import 'package:labelwise/core/crashlytics/crashlytics_service.dart';
import 'package:labelwise/core/theme/app_tokens.dart';
import 'package:labelwise/features/scanner/data/product_repository.dart';
import 'package:labelwise/features/scanner/data/recent_scan.dart';
import 'package:labelwise/features/scanner/data/recent_scans_repository.dart';
import 'package:labelwise/features/premium/presentation/screens/premium_screen.dart';
import 'package:labelwise/features/scanner/presentation/screens/barcode_scanner_screen.dart';
import 'package:labelwise/features/scanner/presentation/screens/product_result_screen.dart';
import 'package:labelwise/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:labelwise/features/scanner/presentation/widgets/recent_scans_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecentScansRepository _recentScansRepository =
      const RecentScansRepository();

  late Future<List<RecentScan>> _recentScans;

  @override
  void initState() {
    super.initState();
    _recentScans = _recentScansRepository.getRecentScans();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CrashlyticsService.instance.setCurrentScreen('home');
      CrashlyticsService.instance.setCurrentFlow('home');
    });
  }

  void _refreshRecentScans() {
    if (!mounted) return;
    setState(() {
      _recentScans = _recentScansRepository.getRecentScans();
    });
  }

  Future<void> _openBarcodeScanner(BuildContext context) async {
    await AnalyticsService.instance.logScanStarted(searchType: 'scan');
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (!context.mounted || barcode == null || barcode.isEmpty) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ScannerScreen(initialBarcode: barcode),
      ),
    );
    _refreshRecentScans();
  }

  Future<void> _openManualLookup(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const ScannerScreen()),
    );
    _refreshRecentScans();
  }

  Future<void> _openRecentScan(BuildContext context, RecentScan scan) async {
    try {
      final productRepository = ProductRepository();
      final product = await productRepository.getProductByBarcode(scan.barcode);
      if (!context.mounted) return;
      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ürün bilgileri şu anda açılamadı. İnternetini kontrol edip tekrar dene.',
            ),
          ),
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ProductResultScreen(product: product),
        ),
      );
      _refreshRecentScans();
    } on Object catch (error) {
      debugPrint('RecentScans: open failed error=$error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ürün bilgileri şu anda açılamadı. İnternetini kontrol edip tekrar dene.',
          ),
        ),
      );
    }
  }

  Future<void> _clearRecentScans() async {
    await _recentScansRepository.clear();
    _refreshRecentScans();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.pagePadding),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1C5A49), Color(0xFF143B31)],
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.hero),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 28,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: const Icon(
                            Icons.eco_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionSpacing),
                        Text(
                          'LabelWise',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.smallSpacing),
                        Text(
                          'Markette ne aldığını 5 saniyede anla.',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.itemSpacing),
                        Text(
                          'Barkodu okut, ürünün besin değerlerini, içerik profilini ve daha dengeli alternatifleri gör.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                            color: const Color(0xFFD8E6DF),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionSpacing),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: FilledButton.icon(
                            onPressed: () => _openBarcodeScanner(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.button,
                                ),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            icon: const Icon(Icons.barcode_reader, size: 24),
                            label: const Text('Barkod Tara'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.itemSpacing),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _openManualLookup(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            icon: const Icon(Icons.keyboard_alt_outlined),
                            label: const Text('Barkodu elle gir'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  Material(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    elevation: 0.5,
                    shadowColor: const Color(0x0D000000),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _openManualLookup(context),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.cardPadding),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.softSurface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Barkodu elle gir',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryText,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Kameraya ihtiyaç duymadan barkod numarasını yazarak hızlıca ürün arayabilirsiniz.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.45,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.mutedText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacingLarge),
                  RecentScansSection(
                    recentScans: _recentScans,
                    onTap: (scan) => _openRecentScan(context, scan),
                    onClear: _clearRecentScans,
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacingLarge),
                  _PremiumTeaserCard(
                    onTap: () {
                      AnalyticsService.instance.logPremiumCtaClicked(
                        source: 'home_screen',
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const PremiumScreen(sourceScreen: 'home_screen'),
                        ),
                      );
                    },
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

class _PremiumTeaserCard extends StatelessWidget {
  const _PremiumTeaserCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              borderRadius: BorderRadius.circular(AppRadii.chip),
            ),
            child: Text(
              'Premium',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.itemSpacing),
          Text(
            'LabelWise Premium',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.smallSpacing),
          Text(
            'Daha uzun geçmiş, ürün karşılaştırma ve gelişmiş analizler yakında Premium’da.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              child: const Text('Premium’u Gör'),
            ),
          ),
        ],
      ),
    );
  }
}
