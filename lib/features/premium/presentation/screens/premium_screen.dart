import 'package:flutter/material.dart';
import 'package:labelwise/core/analytics/analytics_service.dart';
import 'package:labelwise/core/crashlytics/crashlytics_service.dart';
import 'package:labelwise/core/theme/app_tokens.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.sourceScreen});

  final String? sourceScreen;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CrashlyticsService.instance.setCurrentScreen('premium');
      CrashlyticsService.instance.setCurrentFlow('premium');
      AnalyticsService.instance.logPremiumScreenViewed(
        source: widget.sourceScreen ?? 'unknown',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const benefits = [
      _PremiumBenefit(
        icon: Icons.auto_awesome_mosaic_outlined,
        title: 'Daha sağlıklı alternatifleri gör',
        description: 'Benzer ürünler arasında daha dengeli seçenekleri keşfet.',
      ),
      _PremiumBenefit(
        icon: Icons.history_rounded,
        title: 'Daha uzun tarama geçmişi',
        description: 'Son 5 üründen fazlasına eriş.',
      ),
      _PremiumBenefit(
        icon: Icons.keyboard_alt_rounded,
        title: 'Manuel barkod arama',
        description: 'Barkodu kamerayla okutamadığında numarayı elle gir.',
      ),
      _PremiumBenefit(
        icon: Icons.compare_arrows_rounded,
        title: '2 ürünü karşılaştır',
        description: 'İki ürünü yan yana görerek daha bilinçli seçim yap.',
      ),
      _PremiumBenefit(
        icon: Icons.do_not_disturb_on_outlined,
        title: 'Reklamsız deneyim',
        description: 'Daha sade ve kesintisiz kullanım.',
      ),
      _PremiumBenefit(
        icon: Icons.auto_awesome_outlined,
        title: 'Gelişmiş yapay zekâ yorumları',
        description: 'Ürünleri daha detaylı ve anlaşılır şekilde değerlendir.',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PremiumHeroCard(),
                  const SizedBox(height: AppSpacing.sectionSpacingLarge),
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
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: const Color(0xFFB7CEC0),
                        disabledForegroundColor: const Color(0xFF355445),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.button),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      child: const Text('Yakında Aktif Olacak'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Premium hazır olduğunda buradan aktif edilebilecek.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacingLarge),
                  Center(
                    child: Text(
                      'LabelWise tıbbi tavsiye vermez. Ürün analizleri bilgilendirme amaçlıdır.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumHeroCard extends StatelessWidget {
  const _PremiumHeroCard();

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
            'LabelWise Premium',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Market alışverişinde daha bilinçli seçim yap.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              height: 1.45,
              color: const Color(0xFFDCEBE2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Daha uzun geçmiş, ürün karşılaştırma ve gelişmiş analizlerle markette daha iyi kararlar ver.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: const Color(0xFFD4E3DA),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planlanan fiyat',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFDCEBE2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '69,99 TL / ay',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Premium özellikler yakında aktif olacak.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFDCEBE2),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İki ürünü yan yana karşılaştırarak hangisinin daha dengeli bir seçim olduğunu kolayca gör.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.45,
              color: const Color(0xFF5A675F),
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
