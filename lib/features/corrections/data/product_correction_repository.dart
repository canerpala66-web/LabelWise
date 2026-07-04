import 'package:flutter/foundation.dart';
import 'package:labelwise/features/corrections/models/product_correction_report.dart';
import 'package:labelwise/features/scanner/data/product.dart';
import 'package:labelwise/features/scanner/data/product_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductCorrectionRepository {
  ProductCorrectionRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      _productRepository = ProductRepository(
        client: client ?? Supabase.instance.client,
      );

  final SupabaseClient _client;
  final ProductRepository _productRepository;

  static const _selection =
      'id, barcode, product_name, brand, reported_issue, '
      'corrected_energy_kcal, corrected_fat, corrected_saturated_fat, '
      'corrected_sugars, corrected_fiber, corrected_protein, corrected_salt, '
      'note, status, source, created_at, reviewed_at, review_note';

  Future<void> submitCorrectionReport({
    required String barcode,
    required String reportedIssue,
    String? productName,
    String? brand,
    double? correctedEnergyKcal,
    double? correctedFat,
    double? correctedSaturatedFat,
    double? correctedSugars,
    double? correctedFiber,
    double? correctedProtein,
    double? correctedSalt,
    String? note,
  }) async {
    final trimmedBarcode = barcode.trim();
    final trimmedIssue = reportedIssue.trim();
    if (trimmedBarcode.isEmpty) {
      throw ArgumentError.value(barcode, 'barcode', 'Cannot be empty');
    }
    if (trimmedIssue.isEmpty) {
      throw ArgumentError.value(
        reportedIssue,
        'reportedIssue',
        'Cannot be empty',
      );
    }

    final payload = <String, dynamic>{
      'barcode': trimmedBarcode,
      'product_name': _optionalText(productName),
      'brand': _optionalText(brand),
      'reported_issue': trimmedIssue,
      'corrected_energy_kcal': correctedEnergyKcal,
      'corrected_fat': correctedFat,
      'corrected_saturated_fat': correctedSaturatedFat,
      'corrected_sugars': correctedSugars,
      'corrected_fiber': correctedFiber,
      'corrected_protein': correctedProtein,
      'corrected_salt': correctedSalt,
      'note': _optionalText(note),
      'status': 'pending',
      'source': 'user_correction',
    };

    try {
      final insertedRow = await _client
          .schema('public')
          .from('product_correction_reports')
          .insert(payload)
          .select('id')
          .single();
      final insertedId = insertedRow['id'];
      if (insertedId == null || insertedId.toString().trim().isEmpty) {
        throw StateError('Correction insert returned no row id.');
      }
      debugPrint(
        'CorrectionReport: repository insert confirmed id=$insertedId',
      );
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        'CorrectionReport: Supabase insert failed '
        'code=${error.code}, message=${error.message}, '
        'details=${error.details}, hint=${error.hint}',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } on Object catch (error, stackTrace) {
      debugPrint('CorrectionReport: repository insert failed error=$error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<ProductCorrectionReport>> fetchCorrectionReports({
    String status = 'pending',
  }) async {
    final normalizedStatus = _normalizedStatus(status);
    debugPrint('CorrectionAdmin: fetching reports status=$normalizedStatus');
    try {
      final query = _client
          .from('product_correction_reports')
          .select(_selection);
      final rows = normalizedStatus == 'pending'
          ? await query
                .or('status.eq.pending,status.is.null')
                .order('created_at', ascending: false)
          : await query
                .eq('status', normalizedStatus)
                .order('created_at', ascending: false);
      final reports = rows
          .map(ProductCorrectionReport.fromJson)
          .toList(growable: false);
      debugPrint('CorrectionAdmin: loaded ${reports.length} reports');
      return reports;
    } on Object catch (error) {
      debugPrint('CorrectionAdmin: failed step=fetch reports, error=$error');
      rethrow;
    }
  }

  Future<ProductCorrectionReport?> fetchCorrectionReportById(String id) async {
    final reportId = id.trim();
    if (reportId.isEmpty) return null;
    debugPrint('CorrectionAdmin: opening report id=$reportId');
    try {
      final row = await _client
          .from('product_correction_reports')
          .select(_selection)
          .eq('id', reportId)
          .maybeSingle();
      return row == null ? null : ProductCorrectionReport.fromJson(row);
    } on Object catch (error) {
      debugPrint('CorrectionAdmin: failed step=fetch report, error=$error');
      rethrow;
    }
  }

  Future<Product?> fetchProductByBarcode(String barcode) async {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty) return null;
    debugPrint('CorrectionAdmin: fetching product barcode=$normalizedBarcode');
    try {
      return await _productRepository.getProductByBarcode(normalizedBarcode);
    } on Object catch (error) {
      debugPrint('CorrectionAdmin: failed step=fetch product, error=$error');
      rethrow;
    }
  }

  Future<void> approveCorrectionReport(String id, {String? reviewNote}) async {
    final reportId = id.trim();
    debugPrint('CorrectionAdmin: approving report id=$reportId');
    final report = await fetchCorrectionReportById(reportId);
    if (report == null) {
      throw StateError('Correction report not found.');
    }
    final barcode = report.barcode.trim();
    if (barcode.isEmpty) {
      throw StateError('Correction report barcode is missing.');
    }

    final product = await fetchProductByBarcode(barcode);
    if (product == null) {
      throw StateError('Product not found for correction report.');
    }

    final updates = <String, dynamic>{
      'source': 'labelwise_corrected',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    for (final entry in report.correctedNutrition.entries) {
      if (entry.value != null) updates[entry.key] = entry.value;
    }

    debugPrint('CorrectionAdmin: updating product barcode=$barcode');
    try {
      final updatedProduct = await _updateProduct(barcode, updates);
      if (updatedProduct == null) {
        throw StateError('Product update did not match a barcode.');
      }
      debugPrint('CorrectionAdmin: product update success');
    } on Object catch (error) {
      debugPrint('CorrectionAdmin: failed step=update product, error=$error');
      rethrow;
    }

    try {
      await _markReportReviewed(
        reportId,
        status: 'approved',
        reviewNote: reviewNote,
      );
      debugPrint('CorrectionAdmin: report marked approved');
    } on Object catch (error) {
      debugPrint('CorrectionAdmin: failed step=mark approved, error=$error');
      rethrow;
    }
  }

  Future<void> rejectCorrectionReport(String id, {String? reviewNote}) async {
    final reportId = id.trim();
    debugPrint('CorrectionAdmin: rejecting report id=$reportId');
    final report = await fetchCorrectionReportById(reportId);
    if (report == null) {
      throw StateError('Correction report not found.');
    }
    try {
      await _markReportReviewed(
        reportId,
        status: 'rejected',
        reviewNote: reviewNote,
      );
    } on Object catch (error) {
      debugPrint('CorrectionAdmin: failed step=mark rejected, error=$error');
      rethrow;
    }
  }

  Future<void> _markReportReviewed(
    String id, {
    required String status,
    String? reviewNote,
  }) async {
    final updatedReport = await _client
        .from('product_correction_reports')
        .update({
          'status': status,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          'review_note': _optionalText(reviewNote),
        })
        .eq('id', id)
        .select('id')
        .maybeSingle();
    if (updatedReport == null) {
      throw StateError('Correction report update did not match an id.');
    }
  }

  Future<Map<String, dynamic>?> _updateProduct(
    String barcode,
    Map<String, dynamic> updates,
  ) async {
    try {
      return await _client
          .from('products')
          .update(updates)
          .eq('barcode', barcode)
          .select('barcode')
          .maybeSingle();
    } on PostgrestException catch (error) {
      if (!_isMissingUpdatedAtColumn(error)) rethrow;
      debugPrint(
        'CorrectionAdmin: products.updated_at unavailable; '
        'continuing without timestamp',
      );
      final fallbackUpdates = Map<String, dynamic>.of(updates)
        ..remove('updated_at');
      return _client
          .from('products')
          .update(fallbackUpdates)
          .eq('barcode', barcode)
          .select('barcode')
          .maybeSingle();
    }
  }

  bool _isMissingUpdatedAtColumn(PostgrestException error) {
    final description = '${error.message} ${error.details} ${error.hint}';
    return description.contains('updated_at');
  }

  String _normalizedStatus(String status) {
    return switch (status.trim().toLowerCase()) {
      'approved' => 'approved',
      'rejected' => 'rejected',
      _ => 'pending',
    };
  }

  String? _optionalText(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
