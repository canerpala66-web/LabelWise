import 'dart:async';

import 'package:flutter/material.dart';
import 'package:labelwise/core/analytics/analytics_service.dart';
import 'package:labelwise/core/crashlytics/crashlytics_service.dart';
import 'package:labelwise/core/theme/app_tokens.dart';
import 'package:labelwise/features/auth/data/auth_repository.dart';
import 'package:labelwise/features/premium/data/billing_repository.dart';
import 'package:labelwise/features/premium/data/entitlement_repository.dart';
import 'package:labelwise/features/premium/data/purchase_coordinator.dart';
import 'package:labelwise/features/premium/data/user_entitlement.dart';
import 'package:labelwise/shared/utils/legal_links.dart';

enum _PremiumPlan { monthly, yearly }

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.sourceScreen});

  final String? sourceScreen;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final BillingRepository _billingRepository = BillingRepository();
  final EntitlementRepository _entitlementRepository = EntitlementRepository();
  late final PurchaseCoordinator _purchaseCoordinator;
  late Future<UserEntitlement?> _entitlementFuture;
  StreamSubscription<PurchaseCoordinatorStatus>? _purchaseStatusSubscription;
  _PremiumPlan _selectedPlan = _PremiumPlan.yearly;
  bool _isStartingPurchase = false;
  bool _isRestoringPurchases = false;
  PurchaseCoordinatorStatus _purchaseStatus = PurchaseCoordinatorStatus.idle;

  @override
  void initState() {
    super.initState();
    _purchaseCoordinator = PurchaseCoordinator(
      billingRepository: _billingRepository,
      entitlementRepository: _entitlementRepository,
    );
    _purchaseCoordinator.startListening();
    _purchaseStatusSubscription = _purchaseCoordinator.statusStream.listen(
      _handlePurchaseStatusChanged,
    );
    _entitlementFuture = _entitlementRepository.getCurrentEntitlement();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CrashlyticsService.instance.setCurrentScreen('premium');
      CrashlyticsService.instance.setCurrentFlow('premium');
      AnalyticsService.instance.logPremiumScreenViewed(
        source: widget.sourceScreen ?? 'unknown',
      );
    });
  }

  @override
  void dispose() {
    _purchaseStatusSubscription?.cancel();
    _purchaseCoordinator.dispose();
    super.dispose();
  }

  String get _selectedProductId {
    return _selectedPlan == _PremiumPlan.yearly
        ? 'labelwise_premium_yearly'
        : 'labelwise_premium_monthly';
  }

  String get _selectedPlanButtonText {
    if (_isStartingPurchase) {
      return 'Satın alma başlatılıyor...';
    }

    if (_isPurchaseBusy) {
      return _purchaseStatusMessage ?? 'Satın alma doğrulanıyor...';
    }

    return _selectedPlan == _PremiumPlan.yearly
        ? 'Yıllık planı seç'
        : 'Aylık planı seç';
  }

  bool get _isPurchaseBusy {
    return _purchaseStatus.state == PurchaseCoordinatorState.pending ||
        _purchaseStatus.state == PurchaseCoordinatorState.verifying ||
        _purchaseStatus.state ==
            PurchaseCoordinatorState.refreshingEntitlement;
  }

  String? get _purchaseStatusMessage {
    switch (_purchaseStatus.state) {
      case PurchaseCoordinatorState.pending:
        return 'Satın alma beklemede...';
      case PurchaseCoordinatorState.verifying:
        return 'Satın alma doğrulanıyor...';
      case PurchaseCoordinatorState.refreshingEntitlement:
        return 'Premium durumu güncelleniyor...';
      case PurchaseCoordinatorState.verificationFailed:
      case PurchaseCoordinatorState.entitlementRefreshFailed:
      case PurchaseCoordinatorState.error:
      case PurchaseCoordinatorState.canceled:
      case PurchaseCoordinatorState.entitlementActive:
        return _purchaseStatus.message;
      case PurchaseCoordinatorState.idle:
      case PurchaseCoordinatorState.purchasedNeedsVerification:
      case PurchaseCoordinatorState.restoredNeedsVerification:
      case PurchaseCoordinatorState.verificationSucceeded:
        return null;
    }
  }

  void _handlePurchaseStatusChanged(PurchaseCoordinatorStatus status) {
    if (!mounted) return;

    setState(() {
      _purchaseStatus = status;
      if (status.state == PurchaseCoordinatorState.entitlementActive) {
        _entitlementFuture = _entitlementRepository.getCurrentEntitlement();
      }
    });

    final messenger = ScaffoldMessenger.of(context);
    final message = status.message;
    final shouldShowMessage =
        message != null &&
        message.isNotEmpty &&
        (status.state == PurchaseCoordinatorState.verificationFailed ||
            status.state ==
                PurchaseCoordinatorState.entitlementRefreshFailed ||
            status.state == PurchaseCoordinatorState.error ||
            status.state == PurchaseCoordinatorState.canceled ||
            status.state == PurchaseCoordinatorState.entitlementActive);

    if (shouldShowMessage) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _handlePremiumCtaTap() async {
    if (_isStartingPurchase || _isPurchaseBusy) return;

    final currentUser = _authRepository.currentUser;

    if (currentUser == null) {
      final result = await Navigator.of(context).pushNamed('/auth');
      if (!mounted) return;

      if (result case final String message when message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

      setState(() {
        _entitlementFuture = _entitlementRepository.getCurrentEntitlement();
      });
      return;
    }

    setState(() {
      _isStartingPurchase = true;
    });

    try {
      await _billingRepository.startSubscriptionPurchase(
        productId: _selectedProductId,
      );
    } on BillingRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isStartingPurchase = false;
        });
      }
    }
  }

  Future<void> _handleRestorePurchasesTap() async {
    if (_isRestoringPurchases) return;

    final currentUser = _authRepository.currentUser;

    if (currentUser == null) {
      final result = await Navigator.of(context).pushNamed('/auth');
      if (!mounted) return;

      if (result case final String message when message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

      setState(() {
        _entitlementFuture = _entitlementRepository.getCurrentEntitlement();
      });
      return;
    }

    setState(() {
      _isRestoringPurchases = true;
    });

    try {
      await _billingRepository.restorePurchases();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Satın alımlar kontrol ediliyor...'),
        ),
      );
    } on BillingRepositoryException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringPurchases = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const benefits = [
      _PremiumBenefit(
        icon: Icons.do_not_disturb_on_outlined,
        title: 'Reklamsız deneyim',
        description: 'Daha sade ve kesintisiz kullanım.',
      ),
      _PremiumBenefit(
        icon: Icons.auto_awesome_mosaic_outlined,
        title: 'Daha sağlıklı alternatifler',
        description: 'Benzer ürünler arasında daha dengeli seçenekleri keşfet.',
      ),
      _PremiumBenefit(
        icon: Icons.auto_awesome_outlined,
        title: 'Daha detaylı AI yorumları',
        description: 'Ürünleri daha kapsamlı ve anlaşılır şekilde değerlendir.',
      ),
      _PremiumBenefit(
        icon: Icons.history_rounded,
        title: 'Daha uzun tarama geçmişi',
        description: 'Eski ürün sonuçlarına daha uzun süre eriş.',
      ),
      _PremiumBenefit(
        icon: Icons.cloud_off_outlined,
        title: 'Offline veritabanı yakında',
        description: 'Bağlantı olmadığında da temel ürün bilgilerine eriş.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('LabelWise Premium'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: FutureBuilder<UserEntitlement?>(
          future: _entitlementFuture,
          builder: (context, snapshot) {
            final entitlement = snapshot.data;
            final premiumActive = entitlement?.hasActivePremium == true;
            final entitlementError = snapshot.hasError
                ? 'Premium durumu yüklenemedi.'
                : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PremiumHeroCard(premiumActive: premiumActive),
                      const SizedBox(height: AppSpacing.sectionSpacingLarge),
                      if (premiumActive) ...[
                        _ActivePremiumCard(
                          entitlement: entitlement!,
                          isRestoringPurchases: _isRestoringPurchases,
                          onRestorePurchases: _handleRestorePurchasesTap,
                        ),
                        const SizedBox(height: AppSpacing.sectionSpacingLarge),
                      ] else ...[
                        Text(
                          'Planını seç',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryText,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Premium özellikler yakında aktif olacak. Şimdilik hangi planı tercih edeceğini seçebilirsin.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                height: 1.5,
                                color: AppColors.mutedText,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sectionSpacing),
                        _PlanCard(
                          title: 'Aylık Premium',
                          price: '69,99 TL / ay',
                          description: 'Esnek kullanım',
                          selected: _selectedPlan == _PremiumPlan.monthly,
                          onTap: () {
                            setState(() {
                              _selectedPlan = _PremiumPlan.monthly;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.itemSpacing),
                        _PlanCard(
                          title: 'Yıllık Premium',
                          price: '299,99 TL / yıl',
                          description: 'Ayda yaklaşık 25 TL',
                          badge: 'En avantajlı',
                          selected: _selectedPlan == _PremiumPlan.yearly,
                          onTap: () {
                            setState(() {
                              _selectedPlan = _PremiumPlan.yearly;
                            });
                          },
                        ),
                        if (entitlementError case final message?) ...[
                          const SizedBox(height: AppSpacing.itemSpacing),
                          Text(
                            message,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.caution,
                                  height: 1.4,
                                ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sectionSpacingLarge),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _isStartingPurchase || _isPurchaseBusy
                                ? null
                                : _handlePremiumCtaTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.button,
                                ),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            child: Text(_selectedPlanButtonText),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.itemSpacing),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isRestoringPurchases || _isPurchaseBusy
                                ? null
                                : _handleRestorePurchasesTap,
                            child: Text(
                              _isRestoringPurchases
                                  ? 'Satın alımlar kontrol ediliyor...'
                                  : 'Satın Alımları Geri Yükle',
                            ),
                          ),
                        ),
                        if (_purchaseStatusMessage case final statusMessage?) ...[
                          const SizedBox(height: AppSpacing.itemSpacing),
                          Center(
                            child: Text(
                              statusMessage,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color:
                                        _purchaseStatus.state ==
                                                    PurchaseCoordinatorState
                                                        .verificationFailed ||
                                                _purchaseStatus.state ==
                                                    PurchaseCoordinatorState
                                                        .entitlementRefreshFailed ||
                                                _purchaseStatus.state ==
                                                    PurchaseCoordinatorState
                                                        .error
                                            ? AppColors.caution
                                            : AppColors.mutedText,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Satın alma akışı hazır olduğunda bu ekrandan güvenle devam edebileceksin.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.mutedText,
                                  height: 1.4,
                                ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionSpacing),
                        const _PremiumLegalDisclosureCard(),
                        const SizedBox(height: AppSpacing.sectionSpacingLarge),
                      ],
                      Text(
                        'Premium ile neler açılacak?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'LabelWise Premium, alışveriş sırasında daha net karşılaştırmalar ve daha uzun süreli takip için hazırlanıyor.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      for (final benefit in benefits) ...[
                        _PremiumBenefitCard(benefit: benefit),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 8),
                      const _ComparisonHighlightCard(),
                      const SizedBox(height: AppSpacing.sectionSpacingLarge),
                      const _PremiumLegalDisclosureCard(),
                      const SizedBox(height: AppSpacing.sectionSpacingLarge),
                      Center(
                        child: Text(
                          'LabelWise tıbbi tavsiye vermez. Ürün analizleri bilgilendirme amaçlıdır.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.mutedText,
                                height: 1.45,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PremiumLegalDisclosureCard extends StatelessWidget {
  const _PremiumLegalDisclosureCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Abonelik ve yasal bilgilendirme',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Premium abonelikler Google Play üzerinden yönetilir. Satın alma, yenileme ve iptal işlemleri Google Play hesap ayarlarından yapılır. Premium erişim yalnızca doğrulanmış abonelik durumuna göre aktifleşir.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _PremiumLegalLinkChip(
                label: 'Abonelik Koşulları',
                url: subscriptionTermsUrl,
              ),
              _PremiumLegalLinkChip(
                label: 'Gizlilik Politikası',
                url: privacyPolicyUrl,
              ),
              _PremiumLegalLinkChip(
                label: 'Kullanım Koşulları',
                url: termsOfUseUrl,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumLegalLinkChip extends StatelessWidget {
  const _PremiumLegalLinkChip({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () => openLegalUrl(context, url),
      avatar: const Icon(
        Icons.open_in_new_rounded,
        size: 16,
        color: AppColors.primary,
      ),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.primaryText,
        fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: AppColors.border),
      backgroundColor: AppColors.softSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
    );
  }
}

class _PremiumHeroCard extends StatelessWidget {
  const _PremiumHeroCard({required this.premiumActive});

  final bool premiumActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173F2D), Color(0xFF0E2E22)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.hero),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24123828),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: Color(0xFFFFD782),
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            premiumActive ? 'Premium aktif' : 'LabelWise Premium',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            premiumActive
                ? 'Premium ayrıcalıkların hesabında görünmeye başladı.'
                : 'Market alışverişinde daha bilinçli seçim yap.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              height: 1.45,
              color: const Color(0xFFDCEBE2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            premiumActive
                ? 'Üyelik durumun doğrulanmış premium kaydına göre gösterilir.'
                : 'Daha uzun geçmiş, ürün karşılaştırma ve gelişmiş analizlerle markette daha iyi kararlar ver.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: const Color(0xFFD4E3DA),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivePremiumCard extends StatelessWidget {
  const _ActivePremiumCard({
    required this.entitlement,
    required this.isRestoringPurchases,
    required this.onRestorePurchases,
  });

  final UserEntitlement entitlement;
  final bool isRestoringPurchases;
  final Future<void> Function() onRestorePurchases;

  @override
  Widget build(BuildContext context) {
    final validUntil = entitlement.validUntil;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: const Color(0xFFE4D5A8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6DE),
              borderRadius: BorderRadius.circular(AppRadii.chip),
            ),
            child: Text(
              entitlement.planLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.itemSpacing),
          Text(
            'Premium aktif',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            validUntil == null
                ? 'Üyeliğin şu anda aktif görünüyor.'
                : 'Geçerlilik: ${_formatDate(validUntil)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              child: const Text('Aboneliği Yönet'),
            ),
          ),
          const SizedBox(height: AppSpacing.itemSpacing),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isRestoringPurchases ? null : onRestorePurchases,
              child: Text(
                isRestoringPurchases
                    ? 'Satın alımlar kontrol ediliyor...'
                    : 'Satın Alımları Geri Yükle',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.description,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? const Color(0xFFC8A96B) : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x12C8A96B),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  if (badge case final text?)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6DE),
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.itemSpacing),
              Text(
                price,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.itemSpacing),
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected
                        ? AppColors.secondaryAccent
                        : AppColors.mutedText,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selected ? 'Seçili plan' : 'Seçmek için dokun',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumBenefitCard extends StatelessWidget {
  const _PremiumBenefitCard({required this.benefit});

  final _PremiumBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      shadowColor: const Color(0x12000000),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.softSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(benefit.icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    benefit.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonHighlightCard extends StatelessWidget {
  const _ComparisonHighlightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD2E1D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadii.chip),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                'Yakında',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ürün Karşılaştırma',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İki ürünü yan yana karşılaştırarak hangisinin daha dengeli bir seçim olduğunu kolayca gör.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBenefit {
  const _PremiumBenefit({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day.$month.$year';
}
