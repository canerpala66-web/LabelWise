import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:labelwise/features/premium/data/billing_repository.dart';
import 'package:labelwise/features/premium/data/entitlement_repository.dart';
import 'package:labelwise/features/premium/data/subscription_verification_repository.dart';
import 'package:labelwise/features/premium/data/subscription_verification_result.dart';
import 'package:labelwise/features/premium/data/user_entitlement.dart';

enum PurchaseCoordinatorState {
  idle,
  pending,
  purchasedNeedsVerification,
  restoredNeedsVerification,
  verifying,
  refreshingEntitlement,
  verificationSucceeded,
  entitlementActive,
  entitlementRefreshFailed,
  verificationFailed,
  canceled,
  error,
}

class PurchaseCoordinatorStatus {
  const PurchaseCoordinatorStatus({
    required this.state,
    this.message,
    this.verificationResult,
    this.entitlement,
  });

  final PurchaseCoordinatorState state;
  final String? message;
  final SubscriptionVerificationResult? verificationResult;
  final UserEntitlement? entitlement;

  static const idle = PurchaseCoordinatorStatus(
    state: PurchaseCoordinatorState.idle,
  );
}

class PurchaseCoordinator {
  PurchaseCoordinator({
    BillingRepository? billingRepository,
    SubscriptionVerificationRepository? verificationRepository,
    EntitlementRepository? entitlementRepository,
  }) : _billingRepository = billingRepository ?? BillingRepository(),
       _verificationRepository =
           verificationRepository ?? SubscriptionVerificationRepository(),
       _entitlementRepository = entitlementRepository ?? EntitlementRepository();

  final BillingRepository _billingRepository;
  final SubscriptionVerificationRepository _verificationRepository;
  final EntitlementRepository _entitlementRepository;
  final StreamController<PurchaseCoordinatorStatus> _statusController =
      StreamController<PurchaseCoordinatorStatus>.broadcast();

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  PurchaseCoordinatorStatus _latestStatus = PurchaseCoordinatorStatus.idle;

  Stream<PurchaseCoordinatorStatus> get statusStream => _statusController.stream;

  PurchaseCoordinatorStatus get latestStatus => _latestStatus;

  bool get isListening => _purchaseSubscription != null;

  void startListening() {
    if (_purchaseSubscription != null) {
      return;
    }

    _purchaseSubscription = _billingRepository.purchaseUpdatedStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {
        _emitStatus(
          const PurchaseCoordinatorStatus(
            state: PurchaseCoordinatorState.error,
            message: 'Satın alma bilgisi şu anda alınamadı.',
          ),
        );
      },
    );
  }

  Future<void> stopListening() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }

  Future<void> dispose() async {
    await stopListening();
    await _statusController.close();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    if (purchases.isEmpty) return;

    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _emitStatus(
            const PurchaseCoordinatorStatus(
              state: PurchaseCoordinatorState.pending,
              message: 'Satın alma işlemi bekleniyor.',
            ),
          );
          break;
        case PurchaseStatus.purchased:
          unawaited(_handleVerificationRequiredPurchase(
            purchase,
            restored: false,
          ));
          break;
        case PurchaseStatus.restored:
          unawaited(_handleVerificationRequiredPurchase(
            purchase,
            restored: true,
          ));
          break;
        case PurchaseStatus.canceled:
          _emitStatus(
            const PurchaseCoordinatorStatus(
              state: PurchaseCoordinatorState.canceled,
              message: 'Satın alma işlemi iptal edildi.',
            ),
          );
          break;
        case PurchaseStatus.error:
          _emitStatus(
            const PurchaseCoordinatorStatus(
              state: PurchaseCoordinatorState.error,
              message: 'Satın alma işlemi şu anda tamamlanamadı.',
            ),
          );
          break;
      }
    }
  }

  Future<void> _handleVerificationRequiredPurchase(
    PurchaseDetails purchase, {
    required bool restored,
  }) async {
    _emitStatus(
      PurchaseCoordinatorStatus(
        state: restored
            ? PurchaseCoordinatorState.restoredNeedsVerification
            : PurchaseCoordinatorState.purchasedNeedsVerification,
        message: restored
            ? 'Satın alma kaydı alındı. Doğrulama hazırlanıyor.'
            : 'Satın alma alındı. Doğrulama hazırlanıyor.',
      ),
    );

    final productId = purchase.productID.trim();
    final purchaseToken = purchase.verificationData.serverVerificationData.trim();

    if (productId.isEmpty || purchaseToken.isEmpty) {
      _emitStatus(
        const PurchaseCoordinatorStatus(
          state: PurchaseCoordinatorState.verificationFailed,
          message: 'Satın alma doğrulaması için gerekli bilgi alınamadı.',
        ),
      );
      return;
    }

    _emitStatus(
      const PurchaseCoordinatorStatus(
        state: PurchaseCoordinatorState.verifying,
        message: 'Abonelik doğrulaması kontrol ediliyor.',
      ),
    );

    try {
      final result = await _verificationRepository.verifyGooglePlaySubscription(
        productId: productId,
        purchaseToken: purchaseToken,
      );

      if (result.success && result.isPremium) {
        _emitStatus(
          PurchaseCoordinatorStatus(
            state: PurchaseCoordinatorState.refreshingEntitlement,
            message: 'Premium durumu güncelleniyor.',
            verificationResult: result,
          ),
        );

        try {
          final entitlement = await _entitlementRepository.getCurrentEntitlement();
          if (entitlement?.hasActivePremium == true) {
            _emitStatus(
              PurchaseCoordinatorStatus(
                state: PurchaseCoordinatorState.entitlementActive,
                message: result.message,
                verificationResult: result,
                entitlement: entitlement,
              ),
            );
            return;
          }

          _emitStatus(
            PurchaseCoordinatorStatus(
              state: PurchaseCoordinatorState.entitlementRefreshFailed,
              message: 'Abonelik doğrulandı ancak Premium durumu henüz güncellenemedi.',
              verificationResult: result,
              entitlement: entitlement,
            ),
          );
          return;
        } on EntitlementRepositoryException catch (error) {
          _emitStatus(
            PurchaseCoordinatorStatus(
              state: PurchaseCoordinatorState.entitlementRefreshFailed,
              message: error.message,
              verificationResult: result,
            ),
          );
          return;
        } on Object {
          _emitStatus(
            PurchaseCoordinatorStatus(
              state: PurchaseCoordinatorState.entitlementRefreshFailed,
              message: 'Abonelik doğrulandı ancak Premium durumu henüz güncellenemedi.',
              verificationResult: result,
            ),
          );
          return;
        }
      }

      if (result.success) {
        _emitStatus(
          PurchaseCoordinatorStatus(
            state: PurchaseCoordinatorState.verificationFailed,
            message: result.message,
            verificationResult: result,
          ),
        );
        return;
      }

      _emitStatus(
        PurchaseCoordinatorStatus(
          state: PurchaseCoordinatorState.verificationFailed,
          message: result.message,
          verificationResult: result,
        ),
      );
    } on SubscriptionVerificationRepositoryException catch (error) {
      _emitStatus(
        PurchaseCoordinatorStatus(
          state: PurchaseCoordinatorState.verificationFailed,
          message: error.message,
        ),
      );
    } on Object {
      _emitStatus(
        const PurchaseCoordinatorStatus(
          state: PurchaseCoordinatorState.verificationFailed,
          message: 'Abonelik doğrulanamadı.',
        ),
      );
    }
  }

  void _emitStatus(PurchaseCoordinatorStatus status) {
    _latestStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
