import 'package:flutter/material.dart';
import 'dart:async';
import 'package:labelwise/core/theme/app_tokens.dart';
import 'package:labelwise/features/auth/data/auth_repository.dart';
import 'package:labelwise/features/auth/data/auth_user.dart';
import 'package:labelwise/features/premium/data/entitlement_repository.dart';
import 'package:labelwise/features/premium/data/user_entitlement.dart';
import 'package:labelwise/shared/utils/legal_links.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final EntitlementRepository _entitlementRepository = EntitlementRepository();
  StreamSubscription<AuthUser?>? _authSubscription;
  AuthUser? _currentUser;
  bool _isSigningOut = false;
  String? _entitlementErrorMessage;
  Future<UserEntitlement?>? _entitlementFuture;
  String? _accountErrorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('[ProfileScreen] init');
    _currentUser = _authRepository.currentUser;
    _syncUserState(_currentUser, forceReload: true);
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (!mounted) {
        return;
      }
      _syncUserState(user);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    debugPrint('[ProfileScreen] disposed');
    super.dispose();
  }

  void _syncUserState(AuthUser? user, {bool forceReload = false}) {
    final hasUserChanged = _currentUser?.id != user?.id;
    debugPrint('[ProfileScreen] current user exists: ${user != null}');
    if (!mounted && !forceReload) {
      return;
    }

    if (!hasUserChanged && !forceReload) {
      return;
    }

    setState(() {
      _currentUser = user;
      _accountErrorMessage = null;
      _entitlementErrorMessage = null;
      if (user == null) {
        _entitlementFuture = null;
      } else {
        debugPrint('[ProfileScreen] load started');
        _entitlementFuture = _entitlementRepository.getCurrentEntitlement();
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAuthScreen() async {
    final result = await Navigator.of(context).pushNamed('/auth');
    if (!mounted) return;

    if (result case final String message when message.isNotEmpty) {
      _showSnackBar(message);
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    setState(() {
      _isSigningOut = true;
    });

    try {
      await _authRepository.signOut();
      if (!mounted) return;
      setState(() {
        _currentUser = null;
        _entitlementFuture = null;
        _accountErrorMessage = null;
        _entitlementErrorMessage = null;
      });
    } on AuthRepositoryException {
      if (!mounted) return;
      _showSnackBar('Çıkış yapılamadı. Lütfen tekrar dene.');
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
    final bodyContent = _currentUser == null
        ? _LoggedOutProfileView(
            onAuthTap: _openAuthScreen,
            theme: theme,
          )
        : FutureBuilder<UserEntitlement?>(
            future: _entitlementFuture,
            builder: (context, entitlementSnapshot) {
              if (entitlementSnapshot.connectionState == ConnectionState.waiting) {
                return const _ProfileLoadingView();
              }

              if (entitlementSnapshot.hasError) {
                debugPrint('[ProfileScreen] load failed: Premium durumu yüklenemedi.');
              } else {
                debugPrint('[ProfileScreen] load success');
              }

              final entitlement = entitlementSnapshot.data;
              final entitlementErrorMessage = entitlementSnapshot.hasError
                  ? entitlementSnapshot.error is EntitlementRepositoryException
                      ? (entitlementSnapshot.error as EntitlementRepositoryException)
                          .message
                      : 'Premium durumu yüklenemedi.'
                  : _entitlementErrorMessage;

              return _LoggedInProfileView(
                user: _currentUser!,
                entitlement: entitlement,
                theme: theme,
                isSigningOut: _isSigningOut,
                accountErrorMessage: _accountErrorMessage,
                entitlementErrorMessage: entitlementErrorMessage,
                onSignOut: _signOut,
              );
            },
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        title: const Text('Profil'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              16,
              AppSpacing.pagePadding,
              32,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: bodyContent,
                ),
              ),
            ),
          ),
        ),
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
        const SizedBox(height: AppSpacing.sectionSpacing),
        const _LegalLinksCard(),
      ],
    );
  }
}

class _LoggedInProfileView extends StatelessWidget {
  const _LoggedInProfileView({
    required this.user,
    required this.entitlement,
    required this.theme,
    required this.isSigningOut,
    required this.accountErrorMessage,
    required this.entitlementErrorMessage,
    required this.onSignOut,
  });

  final AuthUser user;
  final UserEntitlement? entitlement;
  final ThemeData theme;
  final bool isSigningOut;
  final String? accountErrorMessage;
  final String? entitlementErrorMessage;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final emailText = user.email.isEmpty ? 'Giriş yapılmış hesap' : user.email;
    final hasPremium = entitlement?.hasActivePremium == true;
    final planTitle = hasPremium ? 'Premium aktif' : 'Ücretsiz plan';
    final premiumChipLabel = hasPremium ? entitlement!.planLabel : 'Premium yakında';
    final premiumDescription = hasPremium
        ? entitlement?.validUntil != null
              ? 'Geçerlilik: ${_formatDate(entitlement!.validUntil!)}'
              : '${entitlement?.planLabel ?? 'Premium'} planın şu anda aktif.'
        : 'Premium özellikler henüz aktif değil.';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hesap durumu',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.itemSpacing),
              Text(
                'Giriş yapılmış',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (accountErrorMessage case final message?) ...[
                const SizedBox(height: AppSpacing.itemSpacing),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.caution,
                    height: 1.4,
                  ),
                ),
              ],
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
                      planTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      premiumDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.45,
                      ),
                    ),
                    if (entitlementErrorMessage case final message?) ...[
                      const SizedBox(height: AppSpacing.smallSpacing),
                      Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.caution,
                          height: 1.4,
                        ),
                      ),
                    ],
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
                  premiumChipLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.itemSpacing),
              Text(
                hasPremium
                    ? 'Premium ayrıcalıkların doğrulanmış üyelik durumuna göre gösterilir.'
                    : 'Aylık ve yıllık paketler yakında aktif olacak.',
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
        const _LegalLinksCard(),
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

class _LegalLinksCard extends StatelessWidget {
  const _LegalLinksCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yasal Bilgiler',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.itemSpacing),
          const _LegalLinkTile(
            label: 'Gizlilik Politikası',
            url: privacyPolicyUrl,
          ),
          const SizedBox(height: 8),
          const _LegalLinkTile(
            label: 'Kullanım Koşulları',
            url: termsOfUseUrl,
          ),
          const SizedBox(height: 8),
          const _LegalLinkTile(
            label: 'Sağlık, AI ve Veri Bilgilendirmesi',
            url: disclaimerUrl,
          ),
          const SizedBox(height: 8),
          const _LegalLinkTile(
            label: 'Hesap Silme Talebi',
            url: accountDeletionUrl,
          ),
          const SizedBox(height: 8),
          const _LegalLinkTile(
            label: 'İletişim',
            url: contactUrl,
          ),
        ],
      ),
    );
  }
}

class _LegalLinkTile extends StatelessWidget {
  const _LegalLinkTile({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openLegalUrl(context, url),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.softSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day.$month.$year';
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _InfoCard(
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: AppSpacing.itemSpacing),
          Text(
            'Profil bilgileri yükleniyor...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
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
