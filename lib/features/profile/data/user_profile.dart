class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      displayName: (map['display_name'] as String?)?.trim().isEmpty ?? true
          ? null
          : (map['display_name'] as String?)?.trim(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse((map['updated_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
