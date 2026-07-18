import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:labelwise/features/premium/data/billing_repository.dart';

enum PurchaseCoordinatorState {
  idle,
  pending,
  purchased,
  restored,
  canceled,
  error,
}

class PurchaseCoordinatorStatus {
  const PurchaseCoordinatorStatus({
    required this.state,
    this.message,
  });

  final PurchaseCoordinatorState state;
  final String? message;

  static const idle = PurchaseCoordinatorStatus(
    state: PurchaseCoordinatorState.idle,
  );
}

class PurchaseCoordinator {
  PurchaseCoordinator({BillingRepository? billingRepository})
    : _billingRepository = billingRepository ?? BillingRepository();

  final BillingRepository _billingRepository;
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
          _emitStatus(
            const PurchaseCoordinatorStatus(
              state: PurchaseCoordinatorState.purchased,
              message: 'Satın alma alındı. Doğrulama daha sonra eklenecek.',
            ),
          );
          break;
        case PurchaseStatus.restored:
          _emitStatus(
            const PurchaseCoordinatorStatus(
              state: PurchaseCoordinatorState.restored,
              message: 'Satın alma kaydı alındı. Doğrulama daha sonra eklenecek.',
            ),
          );
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

  void _emitStatus(PurchaseCoordinatorStatus status) {
    _latestStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
