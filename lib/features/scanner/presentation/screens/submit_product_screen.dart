import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labelwise/core/analytics/analytics_service.dart';
import 'package:labelwise/core/crashlytics/crashlytics_service.dart';
import 'package:labelwise/core/theme/app_tokens.dart';
import 'package:labelwise/features/products/services/product_category_mapper.dart';
import 'package:labelwise/features/scanner/data/submitted_product_repository.dart';

class SubmitProductScreen extends StatefulWidget {
  const SubmitProductScreen({super.key, required this.initialBarcode});

  final String initialBarcode;

  @override
  State<SubmitProductScreen> createState() => _SubmitProductScreenState();
}

class _SubmitProductScreenState extends State<SubmitProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _energyController = TextEditingController();
  final _fatController = TextEditingController();
  final _saturatedFatController = TextEditingController();
  final _sugarsController = TextEditingController();
  final _fiberController = TextEditingController();
  final _proteinController = TextEditingController();
  final _saltController = TextEditingController();
  final SubmittedProductRepository _repository = SubmittedProductRepository();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _barcodeController;
  SubmissionPhoto? _frontPhoto;
  SubmissionPhoto? _nutritionPhoto;
  SubmissionPhoto? _ingredientsPhoto;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _errorMessage;
  String _selectedCategory = 'Belirsiz';

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.initialBarcode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CrashlyticsService.instance.setCurrentScreen('submit_product');
      CrashlyticsService.instance.setCurrentFlow('product_submission');
      AnalyticsService.instance.logProductSubmissionStarted();
    });
  }

  Future<void> _pickPhoto(_PhotoType type) async {
    try {
      final selectedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (selectedImage == null) {
        return;
      }

      final photo = SubmissionPhoto(
        bytes: await selectedImage.readAsBytes(),
        fileExtension: _fileExtension(selectedImage.name),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        switch (type) {
          case _PhotoType.front:
            _frontPhoto = photo;
          case _PhotoType.nutrition:
            _nutritionPhoto = photo;
          case _PhotoType.ingredients:
            _ingredientsPhoto = photo;
        }
        _errorMessage = null;
      });
    } on Exception catch (error, stackTrace) {
      debugPrint('Photo selection error: $error');
      debugPrintStack(stackTrace: stackTrace);
      await CrashlyticsService.instance.recordNonFatal(
        error,
        stackTrace,
        reason: 'photo_upload_failed',
        context: const {'error_type': 'image_picker'},
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            'Fotoğraf seçilemedi. İstersen tekrar deneyebilir ya da bu alanı şimdilik boş bırakabilirsin.';
      });
    }
  }

  Future<void> _submit() async {
    debugPrint('SubmitProduct: submit tapped');
    if (!(_formKey.currentState?.validate() ?? false)) {
      debugPrint(
        'SubmitProduct: failed step=validation, error=form validation failed',
      );
      return;
    }

    final energyKcal = _parseNutritionValue(_energyController.text);
    final fat = _parseNutritionValue(_fatController.text);
    final saturatedFat = _parseNutritionValue(_saturatedFatController.text);
    final sugars = _parseNutritionValue(_sugarsController.text);
    final fiber = _parseNutritionValue(_fiberController.text);
    final protein = _parseNutritionValue(_proteinController.text);
    final salt = _parseNutritionValue(_saltController.text);
    debugPrint('SubmitProduct: validation passed');
    debugPrint('SubmitProduct: barcode=${_barcodeController.text.trim()}');
    debugPrint('SubmitProduct: name=${_nameController.text.trim()}');
    debugPrint('SubmitProduct: brand=${_brandController.text.trim()}');
    debugPrint('SubmitProduct: category=$_selectedCategory');
    debugPrint(
      'SubmitProduct: nutrition values='
      '{energyKcal: $energyKcal, fat: $fat, saturatedFat: $saturatedFat, '
      'sugars: $sugars, fiber: $fiber, protein: $protein, salt: $salt}',
    );
    debugPrint('SubmitProduct: front image selected=${_frontPhoto != null}');
    debugPrint(
      'SubmitProduct: nutrition image selected=${_nutritionPhoto != null}',
    );
    debugPrint(
      'SubmitProduct: ingredients image selected=${_ingredientsPhoto != null}',
    );

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await CrashlyticsService.instance.setCurrentFlow('product_submission');
      await _repository.submitProduct(
        barcode: _barcodeController.text,
        name: _nameController.text,
        brand: _brandController.text,
        ingredientsText: _ingredientsController.text,
        energyKcal: energyKcal,
        fat: fat,
        saturatedFat: saturatedFat,
        sugars: sugars,
        fiber: fiber,
        protein: protein,
        salt: salt,
        category: _selectedCategory,
        frontPhoto: _frontPhoto,
        nutritionPhoto: _nutritionPhoto,
        ingredientsPhoto: _ingredientsPhoto,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
      await AnalyticsService.instance.logProductSubmissionCompleted(
        hasFrontPhoto: _frontPhoto != null,
        hasNutritionPhoto: _nutritionPhoto != null,
        hasIngredientsPhoto: _ingredientsPhoto != null,
        categorySelected: _selectedCategory.trim() != 'Belirsiz',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ürün gönderildi. Ekibimiz bilgileri kontrol ettikten sonra veritabanına ekleyecek.',
          ),
        ),
      );
    } on PhotoUploadException catch (error, stackTrace) {
      debugPrint('SubmitProduct: failed step=image_upload, error=$error');
      debugPrintStack(stackTrace: stackTrace);
      await CrashlyticsService.instance.recordNonFatal(
        error,
        stackTrace,
        reason: 'photo_upload_failed',
        context: const {'error_type': 'image_upload'},
      );

      if (!mounted) {
        return;
      }

      await AnalyticsService.instance.logProductSubmissionFailed(
        failureStep: 'image_upload',
      );
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'Fotoğraflar yüklenemedi. Daha net bir bağlantıyla tekrar deneyebilirsin.';
      });
    } on SubmissionInsertException catch (error, stackTrace) {
      debugPrint('SubmitProduct: failed step=database_insert, error=$error');
      debugPrintStack(stackTrace: stackTrace);
      await CrashlyticsService.instance.recordNonFatal(
        error,
        stackTrace,
        reason: 'product_submission_failed',
        context: const {'error_type': 'database_insert'},
      );

      if (!mounted) return;
      await AnalyticsService.instance.logProductSubmissionFailed(
        failureStep: 'database_insert',
      );
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'Ürün bilgileri şu anda kaydedilemedi. Lütfen biraz sonra tekrar dene.';
      });
    } on Exception catch (error, stackTrace) {
      debugPrint('SubmitProduct: failed step=unexpected, error=$error');
      debugPrintStack(stackTrace: stackTrace);
      await CrashlyticsService.instance.recordNonFatal(
        error,
        stackTrace,
        reason: 'product_submission_failed',
        context: const {'error_type': 'unexpected'},
      );

      if (!mounted) {
        return;
      }

      await AnalyticsService.instance.logProductSubmissionFailed(
        failureStep: 'unexpected',
      );
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'Ürün şu anda gönderilemedi. İnternetini kontrol edip tekrar dene.';
      });
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _ingredientsController.dispose();
    _energyController.dispose();
    _fatController.dispose();
    _saturatedFatController.dispose();
    _sugarsController.dispose();
    _fiberController.dispose();
    _proteinController.dispose();
    _saltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        title: const Text(
          'Ürün Gönder',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              16,
              AppSpacing.pagePadding,
              32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
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
                            color: Color(0x0C000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.softSurface,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.add_box_outlined,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Ürünü İncelemeye Gönder',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bu ürünü birlikte LabelWise veritabanına ekleyelim. Gönderdiğin bilgiler önce incelenir, ardından ürün sayfasında gösterilir.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionSpacing),
                    _FormSection(
                      title: 'Ürün Bilgileri',
                      children: [
                        _SubmissionField(
                          controller: _barcodeController,
                          label: 'Barkod numarası',
                          keyboardType: TextInputType.number,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 16),
                        _SubmissionField(
                          controller: _nameController,
                          label: 'Ürün adı',
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 16),
                        _SubmissionField(
                          controller: _brandController,
                          label: 'Marka',
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Kategori',
                            helperText:
                                'Ürünün hangi gruba ait olduğunu seçebilirsiniz.',
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
                          items: [
                            for (final category
                                in ProductCategoryMapper.categories)
                              DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                          ],
                          onChanged: _isSubmitting || _isSubmitted
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() => _selectedCategory = value);
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FormSection(
                      title: 'Fotoğraflar',
                      helperText:
                          'Fotoğraf eklemek isteğe bağlıdır. Ürünün ön yüzü, beslenme tablosu ve içindekiler fotoğrafı inceleme sürecini hızlandırır.',
                      children: [
                        _PhotoPickerCard(
                          title: 'Ürün Ön Yüzü',
                          subtitle: 'Ambalajın ön tarafını ekleyin.',
                          photo: _frontPhoto,
                          onPick: () => _pickPhoto(_PhotoType.front),
                          enabled: !_isSubmitting && !_isSubmitted,
                        ),
                        const SizedBox(height: 14),
                        _PhotoPickerCard(
                          title: 'Beslenme Tablosu',
                          subtitle:
                              '100 g / 100 ml değerlerinin olduğu tabloyu ekleyin.',
                          photo: _nutritionPhoto,
                          onPick: () => _pickPhoto(_PhotoType.nutrition),
                          enabled: !_isSubmitting && !_isSubmitted,
                        ),
                        const SizedBox(height: 14),
                        _PhotoPickerCard(
                          title: 'İçindekiler',
                          subtitle:
                              'İçindekiler listesini net şekilde ekleyin.',
                          photo: _ingredientsPhoto,
                          onPick: () => _pickPhoto(_PhotoType.ingredients),
                          enabled: !_isSubmitting && !_isSubmitted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FormSection(
                      title: 'Beslenme Değerleri',
                      helperText:
                          'Besin değerlerini 100 g / 100 ml için girin. Ürünün ambalajındaki ‘100 g için’ veya ‘100 ml için’ değerleri kullanın.',
                      children: [
                        _NutritionField(
                          controller: _energyController,
                          label: 'Enerji (kcal)',
                          validator: _nutritionValidator,
                        ),
                        const SizedBox(height: 14),
                        _NutritionField(
                          controller: _fatController,
                          label: 'Yağ (g)',
                          validator: _nutritionValidator,
                        ),
                        const SizedBox(height: 14),
                        _NutritionField(
                          controller: _saturatedFatController,
                          label: 'Doymuş Yağ (g)',
                          validator: _nutritionValidator,
                        ),
                        const SizedBox(height: 14),
                        _NutritionField(
                          controller: _sugarsController,
                          label: 'Şeker (g)',
                          validator: _nutritionValidator,
                        ),
                        const SizedBox(height: 14),
                        _NutritionField(
                          controller: _fiberController,
                          label: 'Lif (g)',
                          validator: _nutritionValidator,
                        ),
                        const SizedBox(height: 14),
                        _NutritionField(
                          controller: _proteinController,
                          label: 'Protein (g)',
                          validator: _nutritionValidator,
                        ),
                        const SizedBox(height: 14),
                        _NutritionField(
                          controller: _saltController,
                          label: 'Tuz (g)',
                          validator: _nutritionValidator,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FormSection(
                      title: 'İçerik Bilgisi',
                      helperText:
                          'İçindekiler alanı isteğe bağlıdır. Dilersen ürünle ilgili kısa bir not da ekleyebilirsin.',
                      children: [
                        _SubmissionField(
                          controller: _ingredientsController,
                          label: 'İçindekiler',
                          maxLines: 5,
                        ),
                      ],
                    ),
                    if (_errorMessage case final message?) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F4),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFF5D4CF)),
                        ),
                        child: Text(
                          message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF81382E),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.softSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'Gönderilen ürünler incelendikten sonra LabelWise veritabanına eklenir.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 58,
                      child: FilledButton(
                        onPressed: _isSubmitting || _isSubmitted
                            ? null
                            : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
                        child: _isSubmitting
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Gönderiliyor...'),
                                ],
                              )
                            : Text(
                                _isSubmitted
                                    ? 'Gönderildi'
                                    : 'İncelemeye Gönder',
                              ),
                      ),
                    ),
                    if (_isSubmitted) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F2E9),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFC8DFD0)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Ürün gönderildi. Ekibimiz bilgileri kontrol ettikten sonra veritabanına ekleyecek.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF175C3B),
                              ),
                            ),
                            if (_hasSelectedPhotos) ...[
                              const SizedBox(height: 7),
                              const Text(
                                'Eklediğin fotoğraflar inceleme sürecini hızlandırmaya yardımcı olacak.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  height: 1.4,
                                  color: Color(0xFF456B55),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunludur.';
    }
    return null;
  }

  String? _nutritionValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parsedValue = _parseNutritionValue(value);
    if (parsedValue == null || !parsedValue.isFinite || parsedValue < 0) {
      return 'Lütfen geçerli bir sayı girin.';
    }
    return null;
  }

  double? _parseNutritionValue(String value) {
    return SubmittedProductRepository.parseNutritionValue(value);
  }

  String _fileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex == -1 ? 'jpg' : fileName.substring(dotIndex + 1);
  }

  bool get _hasSelectedPhotos =>
      _frontPhoto != null ||
      _nutritionPhoto != null ||
      _ingredientsPhoto != null;
}

enum _PhotoType { front, nutrition, ingredients }

class _PhotoPickerCard extends StatelessWidget {
  const _PhotoPickerCard({
    required this.title,
    required this.subtitle,
    required this.photo,
    required this.onPick,
    required this.enabled,
  });

  final String title;
  final String subtitle;
  final SubmissionPhoto? photo;
  final VoidCallback onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selectedPhoto = photo;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedPhoto == null)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fotoğraf ekle',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 150,
                child: Image.memory(
                  selectedPhoto.bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: enabled ? onPick : null,
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: Text(
              selectedPhoto == null ? 'Fotoğraf Seç' : 'Fotoğrafı Değiştir',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.children,
    this.helperText,
  });

  final String title;
  final String? helperText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          if (helperText case final text?) ...[
            const SizedBox(height: 7),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: AppColors.mutedText,
              ),
            ),
          ],
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _NutritionField extends StatelessWidget {
  const _NutritionField({
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return _SubmissionField(
      controller: controller,
      label: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
    );
  }
}

class _SubmissionField extends StatelessWidget {
  const _SubmissionField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: AppColors.softSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
