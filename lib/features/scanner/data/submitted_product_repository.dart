import 'package:flutter/foundation.dart';
import 'package:labelwise/features/admin/models/submitted_product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubmissionPhoto {
  const SubmissionPhoto({required this.bytes, required this.fileExtension});

  final Uint8List bytes;
  final String fileExtension;
}

class PhotoUploadException implements Exception {
  const PhotoUploadException(this.cause);

  final Object cause;

  @override
  String toString() => 'Photo upload failed: $cause';
}

class SubmittedProductRepository {
  SubmittedProductRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _submissionFields =
      'id, barcode, name, brand, ingredients_text, energy_kcal, fat, '
      'saturated_fat, sugars, fiber, protein, salt, front_image_path, '
      'nutrition_image_path, ingredients_image_path, status, source, '
      'created_at, reviewed_at, review_note, category';
  static const _submissionFieldsWithoutCategory =
      'id, barcode, name, brand, ingredients_text, energy_kcal, fat, '
      'saturated_fat, sugars, fiber, protein, salt, front_image_path, '
      'nutrition_image_path, ingredients_image_path, status, source, '
      'created_at, reviewed_at, review_note';

  Future<void> submitProduct({
    required String barcode,
    required String name,
    String? brand,
    String? ingredientsText,
    double? energyKcal,
    double? fat,
    double? saturatedFat,
    double? sugars,
    double? fiber,
    double? protein,
    double? salt,
    String? category,
    SubmissionPhoto? frontPhoto,
    SubmissionPhoto? nutritionPhoto,
    SubmissionPhoto? ingredientsPhoto,
  }) async {
    final trimmedBarcode = barcode.trim();
    final trimmedName = name.trim();

    if (trimmedBarcode.isEmpty) {
      throw ArgumentError.value(barcode, 'barcode', 'Cannot be empty');
    }
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Cannot be empty');
    }

    final timestamp = DateTime.now().toUtc();
    final folderPath =
        'submitted-products/${_safePathSegment(trimmedBarcode)}/'
        '${timestamp.microsecondsSinceEpoch}';
    final uploadedPaths = <String>[];

    String? frontImagePath;
    String? nutritionImagePath;
    String? ingredientsImagePath;

    try {
      frontImagePath = await _uploadPhoto(
        photo: frontPhoto,
        pathWithoutExtension: '$folderPath/front',
        uploadedPaths: uploadedPaths,
      );
      nutritionImagePath = await _uploadPhoto(
        photo: nutritionPhoto,
        pathWithoutExtension: '$folderPath/nutrition',
        uploadedPaths: uploadedPaths,
      );
      ingredientsImagePath = await _uploadPhoto(
        photo: ingredientsPhoto,
        pathWithoutExtension: '$folderPath/ingredients',
        uploadedPaths: uploadedPaths,
      );
    } on Object catch (error) {
      await _removeUploadedPhotos(uploadedPaths);
      throw PhotoUploadException(error);
    }

    try {
      final payload = <String, dynamic>{
        'barcode': trimmedBarcode,
        'name': trimmedName,
        'brand': _optionalValue(brand),
        'ingredients_text': _optionalValue(ingredientsText),
        'energy_kcal': energyKcal,
        'fat': fat,
        'saturated_fat': saturatedFat,
        'sugars': sugars,
        'fiber': fiber,
        'protein': protein,
        'salt': salt,
        'category': _optionalValue(category),
        'front_image_path': frontImagePath,
        'nutrition_image_path': nutritionImagePath,
        'ingredients_image_path': ingredientsImagePath,
        'status': 'pending',
        'source': 'user_submission',
        'created_at': timestamp.toIso8601String(),
      };
      await _insertSubmission(payload);
    } on Object {
      await _removeUploadedPhotos(uploadedPaths);
      rethrow;
    }
  }

  Future<List<SubmittedProduct>> fetchSubmittedProducts({
    String status = 'pending',
  }) async {
    final normalizedStatus = _reviewStatus(status);
    debugPrint('AdminReview: fetching $normalizedStatus submissions');

    try {
      final rows = await _fetchSubmissionRows(normalizedStatus);
      final submissions = rows
          .map(SubmittedProduct.fromJson)
          .toList(growable: false);
      debugPrint('AdminReview: loaded ${submissions.length} submissions');
      return submissions;
    } on Object catch (error) {
      debugPrint('AdminReview: failed step=fetch list, error=$error');
      rethrow;
    }
  }

  Future<SubmittedProduct?> fetchSubmittedProductById(String id) async {
    try {
      final row = await _fetchSubmissionRow(id);
      return row == null ? null : SubmittedProduct.fromJson(row);
    } on Object catch (error) {
      debugPrint('AdminReview: failed step=fetch detail, error=$error');
      rethrow;
    }
  }

  Future<void> approveSubmission(
    String id, {
    String? reviewNote,
    String? category,
  }) async {
    debugPrint('AdminReview: approving submission id=$id');
    final submission = await fetchSubmittedProductById(id);
    if (submission == null) {
      throw StateError('Submitted product not found.');
    }
    if (submission.barcode.isEmpty || submission.name.isEmpty) {
      throw StateError('Submitted product requires barcode and name.');
    }

    final productData = <String, dynamic>{
      'barcode': submission.barcode,
      'name': submission.name,
      'source': 'user_submission',
    };
    _addIfPresent(productData, 'brand', submission.brand);
    _addIfPresent(productData, 'ingredients_text', submission.ingredientsText);
    _addIfPresent(productData, 'energy_kcal', submission.energyKcal);
    _addIfPresent(productData, 'fat', submission.fat);
    _addIfPresent(productData, 'saturated_fat', submission.saturatedFat);
    _addIfPresent(productData, 'sugars', submission.sugars);
    _addIfPresent(productData, 'fiber', submission.fiber);
    _addIfPresent(productData, 'protein', submission.protein);
    _addIfPresent(productData, 'salt', submission.salt);
    _addIfPresent(productData, 'front_image_path', submission.frontImagePath);
    final selectedCategory = _optionalValue(category) ?? submission.category;
    _addIfPresent(productData, 'category', selectedCategory);
    debugPrint('AdminReview: selected category=$selectedCategory');

    try {
      debugPrint(
        'AdminReview: upserting product barcode=${submission.barcode}',
      );
      await _upsertApprovedProduct(productData);
      debugPrint('AdminReview: product upsert success');
    } on Object catch (error) {
      debugPrint('AdminReview: failed step=upsert product, error=$error');
      rethrow;
    }

    try {
      await _saveSubmissionCategory(id, selectedCategory);
      await _markReviewed(id: id, status: 'approved', reviewNote: reviewNote);
      debugPrint('AdminReview: submitted product marked approved');
    } on Object catch (error) {
      debugPrint('AdminReview: failed step=mark approved, error=$error');
      rethrow;
    }
  }

  Future<void> rejectSubmission(String id, {String? reviewNote}) async {
    debugPrint('AdminReview: rejecting submission id=$id');
    try {
      await _markReviewed(id: id, status: 'rejected', reviewNote: reviewNote);
    } on Object catch (error) {
      debugPrint('AdminReview: failed step=mark rejected, error=$error');
      rethrow;
    }
  }

  Future<String?> createPhotoSignedUrl(String? path) async {
    final trimmedPath = path?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      return null;
    }

    debugPrint('AdminPhotoPreview: creating signed URL for path=$trimmedPath');
    try {
      final signedUrl = await _client.storage
          .from('submitted-product-photos')
          .createSignedUrl(trimmedPath, 3600);
      debugPrint('AdminPhotoPreview: signed URL created');
      return signedUrl;
    } on Object catch (error) {
      debugPrint('AdminPhotoPreview: signed URL failed error=$error');
      final description = error.toString().toLowerCase();
      if (description.contains('403') ||
          description.contains('unauthorized') ||
          description.contains('permission') ||
          description.contains('policy') ||
          description.contains('object not found') ||
          description.contains('row-level security')) {
        debugPrint(
          'AdminPhotoPreview: signed URL permission error. '
          'Check storage select policy.',
        );
      }
      return null;
    }
  }

  Future<void> _insertSubmission(Map<String, dynamic> payload) async {
    try {
      await _client.from('submitted_products').insert(payload);
    } on PostgrestException catch (error) {
      if (!_isMissingCategoryColumn(error)) rethrow;
      _logMissingCategorySchema('submitted_products');
      final fallbackPayload = Map<String, dynamic>.of(payload)
        ..remove('category');
      await _client.from('submitted_products').insert(fallbackPayload);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSubmissionRows(String status) async {
    try {
      return await _querySubmissionRows(status, _submissionFields);
    } on PostgrestException catch (error) {
      if (!_isMissingCategoryColumn(error)) rethrow;
      _logMissingCategorySchema('submitted_products');
      return _querySubmissionRows(status, _submissionFieldsWithoutCategory);
    }
  }

  Future<List<Map<String, dynamic>>> _querySubmissionRows(
    String status,
    String fields,
  ) async {
    var query = _client.from('submitted_products').select(fields);
    query = status == 'pending'
        ? query.or('status.eq.pending,status.is.null')
        : query.eq('status', status);
    return query.order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>?> _fetchSubmissionRow(String id) async {
    try {
      return await _client
          .from('submitted_products')
          .select(_submissionFields)
          .eq('id', id)
          .maybeSingle();
    } on PostgrestException catch (error) {
      if (!_isMissingCategoryColumn(error)) rethrow;
      _logMissingCategorySchema('submitted_products');
      return _client
          .from('submitted_products')
          .select(_submissionFieldsWithoutCategory)
          .eq('id', id)
          .maybeSingle();
    }
  }

  Future<void> _upsertApprovedProduct(Map<String, dynamic> data) async {
    try {
      await _client.from('products').upsert(data, onConflict: 'barcode');
    } on PostgrestException catch (error) {
      if (!_isMissingCategoryColumn(error)) rethrow;
      _logMissingCategorySchema('products');
      final fallbackData = Map<String, dynamic>.of(data)..remove('category');
      await _client
          .from('products')
          .upsert(fallbackData, onConflict: 'barcode');
    }
  }

  Future<void> _saveSubmissionCategory(String id, String? category) async {
    if (category == null) return;
    try {
      await _client
          .from('submitted_products')
          .update({'category': category})
          .eq('id', id);
    } on PostgrestException catch (error) {
      if (!_isMissingCategoryColumn(error)) rethrow;
      _logMissingCategorySchema('submitted_products');
    }
  }

  bool _isMissingCategoryColumn(PostgrestException error) {
    final description = '${error.message} ${error.details} ${error.hint}';
    return description.contains('category');
  }

  void _logMissingCategorySchema(String table) {
    debugPrint(
      'Supabase $table table is missing category. Run: '
      'alter table public.$table add column if not exists category text;',
    );
  }

  Future<void> _markReviewed({
    required String id,
    required String status,
    required String? reviewNote,
  }) async {
    await _client
        .from('submitted_products')
        .update({
          'status': _reviewStatus(status),
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          'review_note': _optionalValue(reviewNote),
        })
        .eq('id', id);
  }

  String _reviewStatus(String status) {
    final normalizedStatus = status.trim().toLowerCase();
    if (!const {'pending', 'approved', 'rejected'}.contains(normalizedStatus)) {
      throw ArgumentError.value(status, 'status', 'Unsupported review status');
    }
    return normalizedStatus;
  }

  void _addIfPresent(Map<String, dynamic> data, String key, Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      data[key] = value.trim();
    } else if (value is num) {
      data[key] = value;
    }
  }

  Future<String?> _uploadPhoto({
    required SubmissionPhoto? photo,
    required String pathWithoutExtension,
    required List<String> uploadedPaths,
  }) async {
    if (photo == null) {
      return null;
    }

    final extension = _safeExtension(photo.fileExtension);
    final path = '$pathWithoutExtension.$extension';
    await _client.storage
        .from('submitted-product-photos')
        .uploadBinary(
          path,
          photo.bytes,
          fileOptions: FileOptions(
            contentType: _contentType(extension),
            upsert: false,
          ),
        );
    uploadedPaths.add(path);
    return path;
  }

  Future<void> _removeUploadedPhotos(List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }

    try {
      await _client.storage.from('submitted-product-photos').remove(paths);
    } on Object {
      // Preserve the original upload or database error.
    }
  }

  String _safePathSegment(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  String _safeExtension(String value) {
    final extension = value.toLowerCase().replaceAll('.', '');
    return switch (extension) {
      'jpeg' => 'jpg',
      'jpg' || 'png' || 'webp' || 'heic' || 'heif' => extension,
      _ => 'jpg',
    };
  }

  String _contentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  String? _optionalValue(String? value) {
    final trimmedValue = value?.trim();
    return trimmedValue == null || trimmedValue.isEmpty ? null : trimmedValue;
  }
}
