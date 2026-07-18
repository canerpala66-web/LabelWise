import 'package:flutter/material.dart';
import 'package:labelwise/features/analysis/services/labelwise_score_engine.dart';
import 'package:labelwise/core/analytics/analytics_service.dart';
import 'package:labelwise/core/crashlytics/crashlytics_service.dart';
import 'package:labelwise/core/theme/app_tokens.dart';
import 'package:labelwise/features/scanner/data/product.dart';
import 'package:labelwise/features/scanner/data/product_barcode_validator.dart';
import 'package:labelwise/features/scanner/data/product_repository.dart';
import 'package:labelwise/features/scanner/data/recent_scan.dart';
import 'package:labelwise/features/scanner/data/recent_scans_repository.dart';
import 'package:labelwise/features/scanner/presentation/screens/barcode_scanner_screen.dart';
import 'package:labelwise/features/scanner/presentation/screens/product_result_screen.dart';
import 'package:labelwise/features/scanner/presentation/screens/submit_product_screen.dart';
import 'package:labelwise/features/scanner/presentation/widgets/recent_scans_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.initialBarcode});

  final String? initialBarcode;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final ProductRepository _productRepository = ProductRepository();
  final RecentScansRepository _recentScansRepository =
      const RecentScansRepository();

  late Future<List<RecentScan>> _recentScans;
  bool _isLoading = false;
  String? _errorMessage;
  String? _missingBarcode;
  String? _failedBarcode;

  @override
  void initState() {
    super.initState();
    _recentScans = _recentScansRepository.getRecentScans();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CrashlyticsService.instance.setCurrentScreen('scanner');
      CrashlyticsService.instance.setCurrentFlow('product_lookup');
    });

    final initialBarcode = widget.initialBarcode?.trim();
    if (initialBarcode == null || initialBarcode.isEmpty) {
      return;
    }

    _barcodeController.text = initialBarcode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchProduct(searchType: 'scan');
      }
    });
  }

  Future<void> _scanBarcode() async {
    await AnalyticsService.instance.logScanStarted(searchType: 'scan');
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (!mounted || barcode == null || barcode.isEmpty) {
      return;
    }

    _barcodeController.text = barcode;
    await _searchProduct(searchType: 'scan');
  }

  void _refreshRecentScans() {
    if (!mounted) return;
    setState(() {
      _recentScans = _recentScansRepository.getRecentScans();
    });
  }

  void _openSubmission(String barcode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SubmitProductScreen(initialBarcode: barcode),
      ),
    );
  }

  Future<void> _openRecentScan(RecentScan scan) async {
    try {
      final product = await _productRepository.getProductByBarcode(
        scan.barcode,
      );
      if (!mounted) return;
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
      debugPrint('RecentScans: scanner open failed error=$error');
      if (!mounted) return;
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

  Future<void> _searchProduct({String searchType = 'manual'}) async {
    final validation = ProductBarcodeValidator.validate(
      _barcodeController.text,
    );

    if (!validation.isValid) {
      debugPrint(
        'Manual barcode ignored: rawValue=${_barcodeController.text}, '
        'ignored reason=${validation.reason}',
      );
      setState(() {
        _errorMessage = 'Lütfen geçerli bir barkod numarası girin.';
        _missingBarcode = null;
        _failedBarcode = null;
      });
      return;
    }

    final barcode = validation.value!;
    final barcodeLength = barcode.length;
    _barcodeController.text = barcode;
    FocusScope.of(context).unfocus();
    if (searchType == 'manual') {
      await AnalyticsService.instance.logManualBarcodeSearch(
        barcodeLength: barcodeLength,
      );
    }
    await AnalyticsService.instance.logProductLookupStarted(
      searchType: searchType,
      barcodeLength: barcodeLength,
    );
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _missingBarcode = null;
      _failedBarcode = null;
    });

    try {
      await CrashlyticsService.instance.setCurrentFlow('product_lookup');
      await CrashlyticsService.instance.setSafeContext(
        'search_type',
        searchType,
      );
      await CrashlyticsService.instance.setSafeContext(
        'barcode_length',
        barcodeLength,
      );
      var analyticsSource = 'products_cache';
      var product = await _productRepository.getProductByBarcode(barcode);

      if (product == null) {
        debugPrint('Cache miss: fetching from cache-openfoodfacts-product');
        analyticsSource = 'openfoodfacts_function';
        product = await _productRepository.cacheOpenFoodFactsProductFromFunction(
          barcode: barcode,
        );
      } else if (!product.hasNutritionData) {
        debugPrint(
          'Cache hit: incomplete nutrition, refreshing from cache-openfoodfacts-product',
        );
        analyticsSource = 'openfoodfacts_function';
        final refreshedProduct = await _productRepository
            .cacheOpenFoodFactsProductFromFunction(
              barcode: barcode,
              forceRefresh: true,
            );
        if (refreshedProduct != null) {
          product = refreshedProduct;
        }
      } else if (_needsCategoryRefresh(product)) {
        debugPrint(
          'Cache hit: category missing, refreshing from cache-openfoodfacts-product',
        );
        analyticsSource = 'openfoodfacts_function';
        final cachedProduct = product;
        final refreshedProduct = await _productRepository
            .cacheOpenFoodFactsProductFromFunction(
              barcode: barcode,
              forceRefresh: true,
            );
        if (refreshedProduct != null) {
          product = refreshedProduct;
        } else {
          product = cachedProduct;
        }
      } else {
        debugPrint('Cache hit: complete nutrition');
      }

      if (!mounted) {
        return;
      }

      final foundProduct = product;

      if (foundProduct == null) {
        await AnalyticsService.instance.logProductNotFound(
          searchType: searchType,
          barcodeLength: barcodeLength,
        );
        setState(() {
          _isLoading = false;
          _missingBarcode = barcode;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });

      await AnalyticsService.instance.logProductFound(
        source: _analyticsProductSource(foundProduct, analyticsSource),
        category: _analyticsCategory(foundProduct.category),
        scoreBand: _scoreBandFromProduct(foundProduct),
        hasAiCache: _hasAiCache(foundProduct),
      );

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ProductResultScreen(product: foundProduct),
        ),
      );
      _refreshRecentScans();
    } on Exception catch (e, stackTrace) {
      debugPrint('Product lookup error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (e is PostgrestException) {
        debugPrint('Supabase error: ${e.message}');
      }
      await CrashlyticsService.instance.recordNonFatal(
        e,
        stackTrace,
        reason: 'product_lookup_failed',
        context: {
          'search_type': searchType,
          'barcode_length': barcodeLength,
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Bağlantı kurulamadı ya da ürün bilgileri şu anda alınamadı. İnternetini kontrol edip tekrar dene.';
        _missingBarcode = null;
        _failedBarcode = barcode;
      });
    }
  }

  bool _needsCategoryRefresh(Product product) {
    final source = product.source.trim().toLowerCase();
    final category = product.category?.trim();
    return source == 'openfoodfacts' &&
        (category == null || category.isEmpty || category == 'Belirsiz');
  }

  String _analyticsProductSource(Product product, String fallbackSource) {
    final normalizedSource = product.source.trim().toLowerCase();
    if (normalizedSource == 'user_submission') {
      return 'user_submission';
    }
    if (fallbackSource == 'openfoodfacts_function') {
      return 'openfoodfacts_function';
    }
    return normalizedSource.isEmpty ? 'unknown' : 'products_cache';
  }

  String _analyticsCategory(String? category) {
    final trimmed = category?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'unknown';
    }
    return trimmed.length <= 100 ? trimmed : trimmed.substring(0, 100);
  }

  String _scoreBandFromProduct(Product product) {
    final score = const LabelWiseScoreEngine().calculate(product).score;
    if (score == null) return 'unknown';
    if (score <= 24) return '0_24';
    if (score <= 44) return '25_44';
    if (score <= 59) return '45_59';
    if (score <= 69) return '60_69';
    if (score <= 79) return '70_79';
    if (score <= 89) return '80_89';
    return '90_100';
  }

  bool _hasAiCache(Product product) {
    final summary = product.aiSummary?.trim();
    final risk = product.aiRiskLevel?.trim();
    return summary != null &&
        summary.isNotEmpty &&
        risk != null &&
        risk.isNotEmpty;
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              20,
              AppSpacing.pagePadding,
              32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.hero),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.softSurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.barcode_reader,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionSpacing),
                        Text(
                          'Barkod Tara',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.smallSpacing),
                        Text(
                          'Ürünün barkodunu kamerayla okut veya numarasını elle gir.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionSpacing),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          decoration: BoxDecoration(
                            color: AppColors.softSurface,
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.center_focus_strong_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Kamerayla hızlı başlangıç',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryText,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.itemSpacing),
                              Text(
                                'Barkodu bilmiyorsanız kamerayla hızlıca tarayabilirsiniz.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.45,
                                  color: AppColors.mutedText,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sectionSpacing),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: FilledButton.icon(
                                  onPressed: _isLoading ? null : _scanBarcode,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.button,
                                      ),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  icon: const Icon(Icons.barcode_reader),
                                  label: const Text('Barkod Tara'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacingLarge),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Barkod Numarası Gir',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.smallSpacing),
                        Text(
                          'Barkod numarasını yazarak ürünü hızlıca arayabilirsiniz.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionSpacing),
                        TextField(
                          controller: _barcodeController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            labelText: 'Barkod numarası',
                            hintText: 'Örn. 8690504030012',
                            prefixIcon: const Icon(Icons.numbers_rounded),
                            filled: true,
                            fillColor: AppColors.softSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadii.button,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadii.button,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadii.button,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onSubmitted: (_) =>
                              _isLoading ? null : _searchProduct(),
                        ),
                        const SizedBox(height: AppSpacing.itemSpacing),
                        SizedBox(
                          height: 58,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _searchProduct,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
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
                            child: const Text('Ürünü Ara'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: AppSpacing.itemSpacing),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.softSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Ürün aranıyor...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_missingBarcode case final barcode?) ...[
                    const SizedBox(height: AppSpacing.itemSpacing),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.softSurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bu ürünü henüz tanımıyoruz',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Barkod veritabanımızda bulunamadı. Ürünü incelemeye göndererek LabelWise’ın Türkiye ürün veritabanının gelişmesine yardımcı olabilirsin.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: () => _openSubmission(barcode),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.button,
                                  ),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Ürünü İncelemeye Gönder'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _isLoading ? null : _scanBarcode,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Tekrar Tara'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_errorMessage case final message?) ...[
                    const SizedBox(height: AppSpacing.itemSpacing),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7F4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF5D4CF)),
                      ),
                      child: Column(
                        children: [
                          if (_failedBarcode case final barcode?) ...[
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF9DDD8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFA84435),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ürün yüklenemedi',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF6E3028),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bu ürünü şu anda otomatik olarak bulamadık. İsterseniz bilgilerini göndererek incelemeye alabiliriz.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                color: const Color(0xFF81382E),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () => _openSubmission(barcode),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF81382E),
                                  side: const BorderSide(
                                    color: Color(0xFFD9A69E),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.button,
                                    ),
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('İncelemeye Gönder'),
                              ),
                            ),
                          ] else
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFA84435),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.4,
                                      color: const Color(0xFF81382E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sectionSpacingLarge),
                  RecentScansSection(
                    recentScans: _recentScans,
                    onTap: _openRecentScan,
                    onClear: _clearRecentScans,
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
