class UserEntitlement {
  const UserEntitlement({
    required this.userId,
    required this.isPremium,
    required this.planCode,
    required this.entitlementSource,
    required this.validUntil,
    required this.updatedAt,
  });

  final String userId;
  final bool isPremium;
  final String? planCode;
  final String? entitlementSource;
  final DateTime? validUntil;
  final DateTime updatedAt;

  bool get hasActivePremium {
    if (!isPremium) {
      return false;
    }

    final expiresAt = validUntil;
    if (expiresAt == null) {
      return true;
    }

    return expiresAt.isAfter(DateTime.now());
  }

  String get planLabel {
    switch (planCode?.trim().toLowerCase()) {
      case 'monthly':
        return 'Aylık';
      case 'yearly':
        return 'Yıllık';
      default:
        return 'Ücretsiz';
    }
  }

  factory UserEntitlement.fromMap(Map<String, dynamic> map) {
    return UserEntitlement(
      userId: (map['user_id'] ?? '').toString(),
      isPremium: map['is_premium'] == true,
      planCode: (map['plan_code'] as String?)?.trim().isEmpty ?? true
          ? null
          : (map['plan_code'] as String?)?.trim(),
      entitlementSource:
          (map['entitlement_source'] as String?)?.trim().isEmpty ?? true
          ? null
          : (map['entitlement_source'] as String?)?.trim(),
      validUntil: DateTime.tryParse((map['valid_until'] ?? '').toString()),
      updatedAt: DateTime.tryParse((map['updated_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
