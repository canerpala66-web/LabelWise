import 'package:flutter/material.dart';
import 'package:labelwise/core/theme/app_tokens.dart';
import 'package:labelwise/features/auth/data/auth_repository.dart';
import 'package:labelwise/features/auth/data/auth_user.dart';
import 'package:labelwise/features/profile/data/profile_repository.dart';
import 'package:labelwise/features/profile/data/user_profile.dart';
import 'package:labelwise/features/premium/data/entitlement_repository.dart';
import 'package:labelwise/features/premium/data/user_entitlement.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final ProfileRepository _profileRepository = ProfileRepository();
  final EntitlementRepository _entitlementRepository = EntitlementRepository();
  bool _isSigningOut = false;
  bool _isUpdatingDisplayName = false;
  String? _profileErrorMessage;
  Future<UserProfile?>? _profileFuture;
  String? _entitlementErrorMessage;
  Future<UserEntitlement?>? _entitlementFuture;

  Future<void> _openAuthScreen() async {
    final result = await Navigator.of(context).pushNamed('/auth');
    if (!mounted) return;

    if (result case final String message when message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    _reloadProfile();
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
        _profileFuture = null;
        _entitlementFuture = null;
        _profileErrorMessage = null;
        _entitlementErrorMessage = null;
      });
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

  void _reloadProfile() {
    if (!mounted) return;
    setState(() {
      _profileErrorMessage = null;
      _entitlementErrorMessage = null;
      _profileFuture = _profileRepository.getCurrentProfile();
      _entitlementFuture = _entitlementRepository.getCurrentEntitlement();
    });
  }

  Future<void> _editDisplayName(UserProfile? profile) async {
    final controller = TextEditingController(text: profile?.displayName ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.hero),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Profil adını düzenle',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.smallSpacing),
                  Text(
                    'İstersen burada görünen adını ekleyebilirsin.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: 'Profil adı',
                      hintText: 'Adın',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length > 40) {
                        return 'Profil adı 40 karakterden uzun olamaz.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.itemSpacing),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Vazgeç'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.itemSpacing),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            Navigator.of(context).pop(controller.text.trim());
                          },
                          child: const Text('Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    controller.dispose();

    if (!mounted || result == null || _isUpdatingDisplayName) {
      return;
    }

    setState(() {
      _isUpdatingDisplayName = true;
      _profileErrorMessage = null;
    });

    try {
      await _profileRepository.updateDisplayName(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil adı güncellendi.')),
      );
      _reloadProfile();
    } on ProfileRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _profileErrorMessage = error.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingDisplayName = false;
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
          final profileFuture = user == null
              ? null
              : _profileFuture ?? _profileRepository.getCurrentProfile();
          final entitlementFuture = user == null
              ? null
              : _entitlementFuture ??
                    _entitlementRepository.getCurrentEntitlement();

          if (user != null && !identical(_profileFuture, profileFuture)) {
            _profileFuture = profileFuture;
          }
          if (user != null &&
              !identical(_entitlementFuture, entitlementFuture)) {
            _entitlementFuture = entitlementFuture;
          }

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
                      : FutureBuilder<UserProfile?>(
                          future: profileFuture,
                          builder: (context, profileSnapshot) {
                            if (profileSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const _ProfileLoadingView();
                            }

                            final profile = profileSnapshot.data;
                            final errorMessage = profileSnapshot.hasError
                                ? profileSnapshot.error
                                      is ProfileRepositoryException
                                  ? (profileSnapshot.error
                                          as ProfileRepositoryException)
                                      .message
                                  : 'Profil bilgileri yüklenemedi.'
                                : _profileErrorMessage;

                            return FutureBuilder<UserEntitlement?>(
                              future: entitlementFuture,
                              builder: (context, entitlementSnapshot) {
                                final entitlement = entitlementSnapshot.data;
                                final entitlementErrorMessage =
                                    entitlementSnapshot.hasError
                                    ? entitlementSnapshot.error
                                              is EntitlementRepositoryException
                                          ? (entitlementSnapshot.error
                                                  as EntitlementRepositoryException)
                                              .message
                                          : 'Premium durumu yüklenemedi.'
                                    : _entitlementErrorMessage;

                                return _LoggedInProfileView(
                                  user: user,
                                  profile: profile,
                                  entitlement: entitlement,
                                  theme: theme,
                                  isSigningOut: _isSigningOut,
                                  isUpdatingDisplayName: _isUpdatingDisplayName,
                                  errorMessage: errorMessage,
                                  entitlementErrorMessage:
                                      entitlementErrorMessage,
                                  onEditDisplayName: () =>
                                      _editDisplayName(profile),
                                  onSignOut: _signOut,
                                );
                              },
                            );
                          },
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
    required this.profile,
    required this.entitlement,
    required this.theme,
    required this.isSigningOut,
    required this.isUpdatingDisplayName,
    required this.errorMessage,
    required this.entitlementErrorMessage,
    required this.onEditDisplayName,
    required this.onSignOut,
  });

  final AuthUser user;
  final UserProfile? profile;
  final UserEntitlement? entitlement;
  final ThemeData theme;
  final bool isSigningOut;
  final bool isUpdatingDisplayName;
  final String? errorMessage;
  final String? entitlementErrorMessage;
  final Future<void> Function() onEditDisplayName;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final emailText = profile?.email.isNotEmpty == true
        ? profile!.email
        : (user.email.isEmpty ? 'Giriş yapılmış hesap' : user.email);
    final displayName = profile?.displayName?.trim();
    final displayNameText =
        displayName == null || displayName.isEmpty ? 'Ad eklenmedi' : displayName;
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Görünen ad',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: isUpdatingDisplayName ? null : onEditDisplayName,
                    icon: isUpdatingDisplayName
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      isUpdatingDisplayName ? 'Kaydediliyor...' : 'Düzenle',
                    ),
                  ),
                ],
              ),
              Text(
                displayNameText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (errorMessage case final message?) ...[
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
