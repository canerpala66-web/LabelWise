import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.initialBarcode);
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

      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Fotoğraf seçilemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _repository.submitProduct(
        barcode: _barcodeController.text,
        name: _nameController.text,
        brand: _brandController.text,
        ingredientsText: _ingredientsController.text,
        energyKcal: _parseNutritionValue(_energyController.text),
        fat: _parseNutritionValue(_fatController.text),
        saturatedFat: _parseNutritionValue(_saturatedFatController.text),
        sugars: _parseNutritionValue(_sugarsController.text),
        fiber: _parseNutritionValue(_fiberController.text),
        protein: _parseNutritionValue(_proteinController.text),
        salt: _parseNutritionValue(_saltController.text),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün inceleme için gönderildi.')),
      );
    } on PhotoUploadException catch (error, stackTrace) {
      debugPrint('Product photo upload error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Fotoğraflar yüklenemedi. Lütfen tekrar deneyin.';
      });
    } on Exception catch (error, stackTrace) {
      debugPrint('Product submission error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Ürün gönderilemedi. Lütfen tekrar deneyin.';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7F5),
        foregroundColor: const Color(0xFF17211B),
        elevation: 0,
        title: const Text(
          'Ürün Gönder',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F0E7),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.add_box_outlined,
                          color: Color(0xFF175C3B),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Ürünü İncelemeye Gönder',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF17211B),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu ürünün bilgilerini göndererek LabelWise veritabanının gelişmesine yardımcı olabilirsiniz.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.45,
                        color: const Color(0xFF637068),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FormSection(
                      title: 'Temel Bilgiler',
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FormSection(
                      title: 'Ürün Fotoğrafları',
                      helperText:
                          'Fotoğraf eklemek isteğe bağlıdır. Ürünün ön yüzü, beslenme tablosu ve içindekiler fotoğrafı inceleme sürecini hızlandırır.',
                      children: [
                        _PhotoPickerCard(
                          title: 'Ürün Ön Yüzü',
                          subtitle: 'Ambalajın ön tarafını çekin.',
                          photo: _frontPhoto,
                          onPick: () => _pickPhoto(_PhotoType.front),
                          enabled: !_isSubmitting && !_isSubmitted,
                        ),
                        const SizedBox(height: 14),
                        _PhotoPickerCard(
                          title: 'Beslenme Tablosu',
                          subtitle:
                              '100 g / 100 ml değerlerinin olduğu tabloyu çekin.',
                          photo: _nutritionPhoto,
                          onPick: () => _pickPhoto(_PhotoType.nutrition),
                          enabled: !_isSubmitting && !_isSubmitted,
                        ),
                        const SizedBox(height: 14),
                        _PhotoPickerCard(
                          title: 'İçindekiler',
                          subtitle: 'İçindekiler listesini net şekilde çekin.',
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
                          'Varsa ürün ambalajındaki 100 g / 100 ml beslenme değerlerini girebilirsiniz.',
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
                      helperText: 'İçindekiler alanı isteğe bağlıdır.',
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
                          color: const Color(0xFFFFF1EF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF5D4CF)),
                        ),
                        child: Text(
                          message,
                          style: const TextStyle(color: Color(0xFF81382E)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'Gönderilen ürünler kontrol edildikten sonra LabelWise veritabanına eklenir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(height: 1.4, color: Color(0xFF637068)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 58,
                      child: FilledButton(
                        onPressed: _isSubmitting || _isSubmitted
                            ? null
                            : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF175C3B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC8DFD0)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Teşekkürler! Ürün inceleme için gönderildi.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF175C3B),
                              ),
                            ),
                            if (_hasSelectedPhotos) ...[
                              const SizedBox(height: 7),
                              const Text(
                                'Eklediğiniz fotoğraflar inceleme sürecinde kullanılacaktır.',
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
    final normalizedValue = value.trim().replaceAll(',', '.');
    if (normalizedValue.isEmpty) {
      return null;
    }
    return double.tryParse(normalizedValue);
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE5E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedPhoto == null)
            Container(
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2ED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 36,
                color: Color(0xFF537060),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF26342C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: const Color(0xFF637068),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: enabled ? onPick : null,
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: const Text('Fotoğraf Seç'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF175C3B),
              side: const BorderSide(color: Color(0xFFAAC0B2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8E4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F173D2A),
            blurRadius: 24,
            offset: Offset(0, 10),
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
              color: const Color(0xFF17211B),
            ),
          ),
          if (helperText case final text?) ...[
            const SizedBox(height: 7),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: const Color(0xFF637068),
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
        fillColor: const Color(0xFFF7F9F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDDE5E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDDE5E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1B6B46), width: 1.5),
        ),
      ),
    );
  }
}
