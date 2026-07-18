import 'package:flutter/material.dart';
import 'package:labelwise/core/theme/app_tokens.dart';
import 'package:labelwise/features/auth/data/auth_repository.dart';
import 'package:labelwise/features/auth/data/auth_user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRepository _authRepository = AuthRepository();
  bool _isSigningOut = false;

  Future<void> _openAuthScreen() async {
    final result = await Navigator.of(context).pushNamed('/auth');
    if (!mounted) return;

    if (result case final String message when message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      await _authRepository.signOut();
    } on AuthRepositoryException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çıkış yapılamadı. Lütfen tekrar dene.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        title: const Text('Profil'),
      ),
      body: StreamBuilder<AuthUser?>(
        stream: _authRepository.authStateChanges,
        initialData: _authRepository.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  16,
                  AppSpacing.pagePadding,
                  32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: user == null
                      ? _LoggedOutProfileView(
                          onAuthTap: _openAuthScreen,
                          theme: theme,
                        )
                      : _LoggedInProfileView(
                          user: user,
                          theme: theme,
                          isSigningOut: _isSigningOut,
                          onSignOut: _signOut,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoggedOutProfileView extends StatelessWidget {
  const _LoggedOutProfileView({
    required this.onAuthTap,
    required this.theme,
  });

  final Future<void> Function() onAuthTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C5A49), Color(0xFF143B31)],
            ),
            borderRadius: BorderRadius.circular(AppRadii.hero),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              Text(
                'Profil',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.smallSpacing),
              Text(
                'Premium durumunu yönetmek ve satın alımlarını hesabına bağlamak için giriş yap.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hesap avantajları',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.itemSpacing),
              const _BenefitRow(
                icon: Icons.workspace_premium_outlined,
                text: 'Premium durumunu yönet',
              ),
              const SizedBox(height: AppSpacing.itemSpacing),
              const _BenefitRow(
                icon: Icons.restore_rounded,
                text: 'Satın alımlarını geri yükle',
              ),
              const SizedBox(height: AppSpacing.itemSpacing),
              const _BenefitRow(
                icon: Icons.history_rounded,
                text: 'Gelecekte ürün geçmişini koru',
              ),
              const SizedBox(height: AppSpacing.sectionSpacing),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAuthTap,
                  child: const Text('Giriş Yap / Hesap Oluştur'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        _InfoCard(
          child: Text(
            'İstersen hesabın olmadan da ürün taramaya ve sonuçları görmeye devam edebilirsin.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoggedInProfileView extends StatelessWidget {
  const _LoggedInProfileView({
    required this.user,
    required this.theme,
    required this.isSigningOut,
    required this.onSignOut,
  });

  final AuthUser user;
  final ThemeData theme;
  final bool isSigningOut;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final emailText = user.email.isEmpty ? 'Giriş yapılmış hesap' : user.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.itemSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emailText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        _InfoCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.itemSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ücretsiz plan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tüm temel tarama ve ürün inceleme özelliklerini kullanmaya devam edebilirsin.',
                      style: theme.textTheme.bodyMedium?.copyWith(
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
        const SizedBox(height: AppSpacing.sectionSpacing),
        _InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Text(
                  'Premium yakında',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.itemSpacing),
              Text(
                'Aylık ve yıllık paketler yakında aktif olacak.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                  height: 1.5,
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
                  onPressed: null,
                  child: const Text('Satın Alımları Geri Yükle'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: isSigningOut ? null : onSignOut,
            icon: isSigningOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: Text(isSigningOut ? 'Çıkış yapılıyor...' : 'Çıkış Yap'),
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.softSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.itemSpacing),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.primaryText,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
