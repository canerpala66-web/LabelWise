enum ProcessingProfileGrade { a, b, c, unknown }

class ProcessingProfileResult {
  const ProcessingProfileResult({
    required this.grade,
    required this.label,
    required this.description,
    required this.reasons,
  });

  final ProcessingProfileGrade grade;
  final String label;
  final String description;
  final List<String> reasons;

  static const helperText =
      'Bu bilgi genel bilgilendirme amaçlıdır. Ürünün zararlı veya güvenli '
      'olduğunu tek başına göstermez.';
}
