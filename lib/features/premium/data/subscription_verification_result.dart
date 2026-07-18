class SubscriptionVerificationResult {
  const SubscriptionVerificationResult({
    required this.success,
    required this.isPremium,
    required this.planCode,
    required this.validUntil,
    required this.status,
    required this.message,
  });

  final bool success;
  final bool isPremium;
  final String? planCode;
  final DateTime? validUntil;
  final String status;
  final String message;

  factory SubscriptionVerificationResult.fromMap(Map<String, dynamic> map) {
    return SubscriptionVerificationResult(
      success: map['success'] == true,
      isPremium: map['isPremium'] == true,
      planCode: (map['planCode'] as String?)?.trim().isEmpty ?? true
          ? null
          : (map['planCode'] as String?)?.trim(),
      validUntil: DateTime.tryParse((map['validUntil'] ?? '').toString()),
      status: (map['status'] ?? 'unknown').toString(),
      message: (map['message'] ?? 'Abonelik doğrulanamadı.').toString(),
    );
  }
}
