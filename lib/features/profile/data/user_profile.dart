class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final int? age;
  final String? gender;
  final int? heightCm;
  final double? weightKg;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      displayName: (map['display_name'] as String?)?.trim().isEmpty ?? true
          ? null
          : (map['display_name'] as String?)?.trim(),
      age: _intValue(map['age']),
      gender: (map['gender'] as String?)?.trim().isEmpty ?? true
          ? null
          : (map['gender'] as String?)?.trim(),
      heightCm: _intValue(map['height_cm']),
      weightKg: _doubleValue(map['weight_kg']),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((map['updated_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static int? _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString());
  }

  static double? _doubleValue(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString());
  }
}
