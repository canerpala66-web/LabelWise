import 'package:flutter/material.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const benefits = [
      'Daha sağlıklı alternatifleri gör',
      'Daha uzun tarama geçmişine eriş',
      'Manuel barkod arama',
      '2 ürünü karşılaştır',
      'Reklamsız deneyim',
      'Gelişmiş yapay zekâ yorumları',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('LabelWise Premium'),
        backgroundColor: const Color(0xFFF4F7F5),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF173F2D), Color(0xFF0E2E22)],
                      ),
                      borderRadius: BorderRadius.circular(30),
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
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Market alışverişinde daha bilinçli seçim yap.',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                height: 1.45,
                                color: const Color(0xFFDCEBE2),
                              ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Planlanan fiyat: 69,99 TL / ay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Premium özellikler yakında aktif olacak.',
                                style: TextStyle(
                                  color: Color(0xFFDCEBE2),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final benefit in benefits) ...[
                    _PremiumBenefitCard(text: benefit),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 6),
                  const _ComparisonHighlightCard(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: const Color(0xFFB7CEC0),
                        disabledForegroundColor: const Color(0xFF355445),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      child: const Text('Yakında Aktif Olacak'),
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

class _PremiumBenefitCard extends StatelessWidget {
  const _PremiumBenefitCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: const Color(0x12000000),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F2E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF175C3B),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17211B),
                ),
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
              color: const Color(0xFF175C3B),
              borderRadius: BorderRadius.circular(999),
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
              color: const Color(0xFF17211B),
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
