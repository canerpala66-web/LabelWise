import 'dart:async';

import 'package:flutter/material.dart';
import 'package:labelwise/core/theme/app_tokens.dart';
import 'package:labelwise/features/auth/data/auth_repository.dart';
import 'package:labelwise/features/auth/data/auth_user.dart';
import 'package:labelwise/features/premium/data/entitlement_repository.dart';
import 'package:labelwise/features/premium/data/user_entitlement.dart';
import 'package:labelwise/features/profile/data/profile_repository.dart';
import 'package:labelwise/features/profile/data/user_profile.dart';
import 'package:labelwise/features/premium/presentation/screens/premium_screen.dart';
import 'package:labelwise/shared/utils/legal_links.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final EntitlementRepository _entitlementRepository = EntitlementRepository();
  final ProfileRepository _profileRepository = ProfileRepository();

  StreamSubscription<AuthUser?>? _authSubscription;
  AuthUser? _currentUser;
  Future<UserProfile?>? _profileFuture;
  Future<UserEntitlement?>? _entitlementFuture;
  bool _isSigningOut = false;
  bool _isSavingProfile = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[ProfileScreen] init');
    _currentUser = _authRepository.currentUser;
    _reloadForUser(_currentUser, forceReload: true);
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (!mounted) return;
      _reloadForUser(user);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    debugPrint('[ProfileScreen] disposed');
    super.dispose();
  }

  void _reloadForUser(AuthUser? user, {bool forceReload = false}) {
    final userChanged = _currentUser?.id != user?.id;
    debugPrint('[ProfileScreen] current user exists: ${user != null}');

    if (!userChanged && !forceReload) return;

    setState(() {
      _currentUser = user;
      if (user == null) {
        _profileFuture = null;
        _entitlementFuture = null;
      } else {
        debugPrint('[ProfileScreen] load started');
        _profileFuture = _profileRepository.getCurrentProfile();
        _entitlementFuture = _entitlementRepository.getCurrentEntitlement();
      }
    });
  }

  void _reloadCurrentAccountData() {
    _reloadForUser(_authRepository.currentUser, forceReload: true);
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

    _reloadCurrentAccountData();
  }

  Future<void> _openPremiumScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PremiumScreen(sourceScreen: 'profile_screen'),
      ),
    );
    if (!mounted) return;
    _reloadCurrentAccountData();
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
        _profileFuture = null;
        _entitlementFuture = null;
      });
    } on AuthRepositoryException {
      _showSnackBar('Çıkış yapılamadı. Lütfen tekrar dene.');
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  Future<void> _editProfile(UserProfile? currentProfile) async {
    if (_isSavingProfile) return;

    final values = await showDialog<_EditableProfileValues>(
      context: context,
      builder: (context) => _EditProfileDialog(profile: currentProfile),
    );

    if (values == null || !mounted) return;

    setState(() {
      _isSavingProfile = true;
    });

    try {
      await _profileRepository.updateProfile(
        displayName: values.displayName,
        age: values.age,
        gender: values.gender,
        heightCm: values.heightCm,
        weightKg: values.weightKg,
      );
      _reloadCurrentAccountData();
      _showSnackBar('Profil bilgileri güncellendi.');
    } on ProfileRepositoryException catch (error) {
      _showSnackBar(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (_isDeletingAccount) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabını sil'),
        content: const Text(
          'Bu işlem kalıcıdır. Profil bilgilerin ve hesabına bağlı üyelik kayıtların silinir. Google Play aboneliğin varsa yönetimi yine Google Play üzerinden yapılır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.caution,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hesabımı Sil'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      await _profileRepository.deleteCurrentAccount();
      try {
        await _authRepository.signOut();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _currentUser = null;
        _profileFuture = null;
        _entitlementFuture = null;
      });

      _showSnackBar('Hesabın silindi.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ProfileRepositoryException catch (error) {
      _showSnackBar(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bodyContent = _currentUser == null
        ? _LoggedOutProfileView(onAuthTap: _openAuthScreen, theme: theme)
        : FutureBuilder<UserProfile?>(
            future: _profileFuture,
            builder: (context, profileSnapshot) {
              return FutureBuilder<UserEntitlement?>(
                future: _entitlementFuture,
                builder: (context, entitlementSnapshot) {
                  final isLoading =
                      profileSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      entitlementSnapshot.connectionState ==
                          ConnectionState.waiting;

                  if (isLoading) {
                    return const _ProfileLoadingView();
                  }

                  if (profileSnapshot.hasError) {
                    debugPrint('[ProfileScreen] profile load failed');
                  }
                  if (entitlementSnapshot.hasError) {
                    debugPrint('[ProfileScreen] entitlement load failed');
                  }

                  return _LoggedInProfileView(
                    user: _currentUser!,
                    profile: profileSnapshot.data,
                    entitlement: entitlementSnapshot.data,
                    theme: theme,
                    isSigningOut: _isSigningOut,
                    isSavingProfile: _isSavingProfile,
                    isDeletingAccount: _isDeletingAccount,
                    profileErrorMessage: _messageFromProfileError(
                      profileSnapshot.error,
                    ),
                    entitlementErrorMessage: _messageFromEntitlementError(
                      entitlementSnapshot.error,
                    ),
                    onEditProfile: () => _editProfile(profileSnapshot.data),
                    onOpenPremium: _openPremiumScreen,
                    onSignOut: _signOut,
                    onDeleteAccount: _deleteAccount,
                  );
                },
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

  String? _messageFromProfileError(Object? error) {
    if (error == null) return null;
    if (error is ProfileRepositoryException) return error.message;
    return 'Profil bilgileri yüklenemedi.';
  }

  String? _messageFromEntitlementError(Object? error) {
    if (error == null) return null;
    if (error is EntitlementRepositoryException) return error.message;
    return 'Premium durumu yüklenemedi.';
  }
}

class _LoggedOutProfileView extends StatelessWidget {
  const _LoggedOutProfileView({required this.onAuthTap, required this.theme});

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
                icon: Icons.edit_note_rounded,
                text: 'Profil bilgilerini isteğe bağlı olarak ekle',
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
    required this.profile,
    required this.entitlement,
    required this.theme,
    required this.isSigningOut,
    required this.isSavingProfile,
    required this.isDeletingAccount,
    required this.profileErrorMessage,
    required this.entitlementErrorMessage,
    required this.onEditProfile,
    required this.onOpenPremium,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  final AuthUser user;
  final UserProfile? profile;
  final UserEntitlement? entitlement;
  final ThemeData theme;
  final bool isSigningOut;
  final bool isSavingProfile;
  final bool isDeletingAccount;
  final String? profileErrorMessage;
  final String? entitlementErrorMessage;
  final Future<void> Function() onEditProfile;
  final Future<void> Function() onOpenPremium;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final emailText = user.email.isEmpty ? 'Giriş yapılmış hesap' : user.email;
    final hasPremium = entitlement?.hasActivePremium == true;
    final planTitle = hasPremium ? 'Premium aktif' : 'Ücretsiz plan';
    final premiumDescription = hasPremium
        ? entitlement?.validUntil != null
              ? 'Geçerlilik: ${_formatDate(entitlement!.validUntil!)}'
              : '${entitlement?.planLabel ?? 'Premium'} planın şu anda aktif.'
        : 'Premium özellikler şu anda hesabında aktif görünmüyor.';

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
                      profile?.displayName?.trim().isNotEmpty == true
                          ? profile!.displayName!.trim()
                          : 'Profil',
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
                      'Kişisel bilgiler',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: isSavingProfile ? null : onEditProfile,
                    icon: isSavingProfile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      isSavingProfile ? 'Kaydediliyor...' : 'Düzenle',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.itemSpacing),
              _ProfileValueRow(
                label: 'Görünen ad',
                value: profile?.displayName ?? 'Ad eklenmedi',
              ),
              _ProfileValueRow(
                label: 'Yaş',
                value: profile?.age?.toString() ?? 'Eklenmedi',
              ),
              _ProfileValueRow(
                label: 'Cinsiyet',
                value: profile?.gender ?? 'Eklenmedi',
              ),
              _ProfileValueRow(
                label: 'Boy',
                value: profile?.heightCm != null
                    ? '${profile!.heightCm} cm'
                    : 'Eklenmedi',
              ),
              _ProfileValueRow(
                label: 'Kilo',
                value: profile?.weightKg != null
                    ? _formatWeight(profile!.weightKg!)
                    : 'Eklenmedi',
                isLast: true,
              ),
              if (profileErrorMessage case final message?) ...[
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                planTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: AppSpacing.sectionSpacing),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onOpenPremium,
                  child: Text(
                    hasPremium ? 'Premium detayları' : 'Premium’u Gör',
                  ),
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
                'Hesap işlemleri',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hesabını istediğin zaman kapatabilir veya güvenle çıkış yapabilirsin.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                  height: 1.45,
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
                  label: Text(
                    isSigningOut ? 'Çıkış yapılıyor...' : 'Çıkış Yap',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.itemSpacing),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isDeletingAccount ? null : onDeleteAccount,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.caution,
                    side: const BorderSide(color: AppColors.caution),
                  ),
                  icon: isDeletingAccount
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    isDeletingAccount ? 'Hesap siliniyor...' : 'Hesabımı Sil',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        const _LegalLinksCard(),
      ],
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile});

  final UserProfile? profile;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late String? _selectedGender;
  String? _errorMessage;

  static const List<String> _genders = [
    'Kadın',
    'Erkek',
    'Belirtmek istemiyorum',
  ];

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile?.displayName ?? '',
    );
    _ageController = TextEditingController(
      text: widget.profile?.age?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.profile?.heightCm?.toString() ?? '',
    );
    final initialWeight = widget.profile?.weightKg;
    _weightController = TextEditingController(
      text: initialWeight == null
          ? ''
          : initialWeight.toStringAsFixed(
              initialWeight.truncateToDouble() == initialWeight ? 0 : 1,
            ),
    );
    _selectedGender = widget.profile?.gender;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submit() {
    final age = _parseInt(_ageController.text);
    final heightCm = _parseInt(_heightController.text);
    final weightKg = _parseDouble(_weightController.text);

    if (_ageController.text.trim().isNotEmpty && age == null) {
      setState(() {
        _errorMessage = 'Yaş bilgisi sayı olarak girilmeli.';
      });
      return;
    }

    if (_heightController.text.trim().isNotEmpty && heightCm == null) {
      setState(() {
        _errorMessage = 'Boy bilgisi sayı olarak girilmeli.';
      });
      return;
    }

    if (_weightController.text.trim().isNotEmpty && weightKg == null) {
      setState(() {
        _errorMessage = 'Kilo bilgisi sayı olarak girilmeli.';
      });
      return;
    }

    Navigator.of(context).pop(
      _EditableProfileValues(
        displayName: _displayNameController.text.trim(),
        age: age,
        gender: _selectedGender,
        heightCm: heightCm,
        weightKg: weightKg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profil bilgilerini düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _displayNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Görünen ad',
                hintText: 'İsteğe bağlı',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Yaş',
                hintText: 'İsteğe bağlı',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _genders.contains(_selectedGender)
                  ? _selectedGender
                  : null,
              items: _genders
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Cinsiyet',
                hintText: 'İsteğe bağlı',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Boy (cm)',
                hintText: 'İsteğe bağlı',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Kilo (kg)',
                hintText: 'İsteğe bağlı',
              ),
            ),
            if (_errorMessage case final message?) ...[
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.caution),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Kaydet')),
      ],
    );
  }
}

class _EditableProfileValues {
  const _EditableProfileValues({
    required this.displayName,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
  });

  final String displayName;
  final int? age;
  final String? gender;
  final int? heightCm;
  final double? weightKg;
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.primaryText),
          ),
        ),
      ],
    );
  }
}

class _ProfileValueRow extends StatelessWidget {
  const _ProfileValueRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
          const _LegalLinkTile(label: 'Kullanım Koşulları', url: termsOfUseUrl),
          const SizedBox(height: 8),
          const _LegalLinkTile(
            label: 'Sağlık, AI ve Veri Bilgilendirmesi',
            url: disclaimerUrl,
          ),
          const SizedBox(height: 8),
          const _LegalLinkTile(
            label: 'Hesap Silme Bilgisi',
            url: accountDeletionUrl,
          ),
          const SizedBox(height: 8),
          const _LegalLinkTile(label: 'İletişim', url: contactUrl),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppColors.primary,
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

String _formatWeight(double value) {
  if (value == value.truncateToDouble()) {
    return '${value.toStringAsFixed(0)} kg';
  }
  return '${value.toStringAsFixed(1)} kg';
}

int? _parseInt(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return null;
  return int.tryParse(normalized);
}

double? _parseDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}
