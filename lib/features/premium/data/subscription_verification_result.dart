class SubscriptionVerificationResult {
  const SubscriptionVerificationResult({
    required this.success,
    required this.active,
    required this.isPremium,
    required this.productId,
    required this.planCode,
    required this.expiresAt,
    required this.validUntil,
    required this.subscriptionState,
    required this.status,
    required this.message,
  });

  final bool success;
  final bool active;
  final bool isPremium;
  final String? productId;
  final String? planCode;
  final DateTime? expiresAt;
  final DateTime? validUntil;
  final String subscriptionState;
  final String status;
  final String message;

  factory SubscriptionVerificationResult.fromMap(Map<String, dynamic> map) {
    final expiresAt =
        DateTime.tryParse((map['expiresAt'] ?? '').toString()) ??
        DateTime.tryParse((map['validUntil'] ?? '').toString());

    return SubscriptionVerificationResult(
      success: map['success'] == true || map['active'] == true,
      active: map['active'] == true || map['isPremium'] == true,
      isPremium: map['isPremium'] == true || map['active'] == true,
      productId: (map['productId'] as String?)?.trim().isEmpty ?? true
          ? null
          : (map['productId'] as String?)?.trim(),
      planCode: (map['planCode'] as String?)?.trim().isEmpty ?? true
          ? null
          : (map['planCode'] as String?)?.trim(),
      expiresAt: expiresAt,
      validUntil:
          DateTime.tryParse((map['validUntil'] ?? '').toString()) ?? expiresAt,
      subscriptionState: (map['subscriptionState'] ?? 'unknown').toString(),
      status: (map['status'] ?? 'unknown').toString(),
      message: (map['message'] ?? 'Abonelik doğrulanamadı.').toString(),
    );
  }
}
