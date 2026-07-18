import 'package:flutter/material.dart';
import 'package:labelwise/core/theme/app_tokens.dart';
import 'package:labelwise/features/onboarding/data/onboarding_repository.dart';
import 'package:labelwise/features/scanner/presentation/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingRepository _repository = const OnboardingRepository();

  static const _steps = <_OnboardingStep>[
    _OnboardingStep(
      icon: Icons.qr_code_scanner_rounded,
      title: 'Barkodu okut',
      description: 'Market ürünlerini saniyeler içinde analiz et.',
    ),
    _OnboardingStep(
      icon: Icons.fact_check_outlined,
      title: 'İçeriği anla',
      description:
          'Şeker, tuz, yağ, katkılar ve içerik profilini sade Türkçeyle gör.',
    ),
    _OnboardingStep(
      icon: Icons.auto_graph_rounded,
      title: 'Daha bilinçli seç',
      description:
          'Ürünün günlük kullanım için uygun olup olmadığını ve daha iyi alternatifleri keşfet.',
    ),
  ];

  int _currentIndex = 0;
  bool _isCompleting = false;

  bool get _isLastStep => _currentIndex == _steps.length - 1;

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;
    setState(() {
      _isCompleting = true;
    });

    await _repository.markCompleted();
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _nextStep() async {
    if (_isLastStep) {
      await _completeOnboarding();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LabelWise',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton(
                    onPressed: _isCompleting ? null : _completeOnboarding,
                    child: const Text('Geç'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionSpacingLarge),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return _OnboardingCard(step: step);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentIndex ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentIndex
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacingLarge),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isCompleting ? null : _nextStep,
                  child: Text(_isLastStep ? 'Başla' : 'İleri'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.hero),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.softSurface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(step.icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.sectionSpacingLarge),
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.itemSpacing),
            Text(
              step.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
