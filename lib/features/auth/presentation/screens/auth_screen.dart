import 'package:flutter/material.dart';
import 'package:labelwise/core/theme/app_tokens.dart';
import 'package:labelwise/features/auth/data/auth_repository.dart';
import 'package:labelwise/features/scanner/presentation/screens/home_screen.dart';

enum _AuthMode { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();

  _AuthMode _mode = _AuthMode.signIn;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isSignIn => _mode == _AuthMode.signIn;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignIn) {
        await _authRepository.signInWithEmailPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _authRepository.signUpWithEmailPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        );
      }
    } on AuthRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
      return;
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'İşlem şu anda tamamlanamadı. Lütfen tekrar deneyin.';
      });
      return;
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.signInWithGoogle();

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        );
      }
    } on AuthRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Google ile giriş şu anda tamamlanamadı. Lütfen tekrar deneyin.';
      });
    }
  }

  void _switchMode() {
    if (_isLoading) return;
    setState(() {
      _mode = _isSignIn ? _AuthMode.signUp : _AuthMode.signIn;
      _errorMessage = null;
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'E-posta alanı boş bırakılamaz.';
    }
    final looksValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!looksValid) {
      return 'Geçerli bir e-posta adresi girin.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Şifre alanı boş bırakılamaz.';
    }
    if (password.length < 6) {
      return 'Şifre en az 6 karakter olmalı.';
    }
    return null;
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
        title: Text(_isSignIn ? 'Giriş Yap' : 'Hesap Oluştur'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              16,
              AppSpacing.pagePadding,
              32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      Text(
                        _isSignIn ? 'Hesabına giriş yap' : 'Yeni hesap oluştur',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.smallSpacing),
                      Text(
                        'Premium durumunu yönetmek ve satın alımlarını hesabına bağlamak için giriş yap.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedText,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacingLarge),
                      SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                          label: const Text('Google ile devam et'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'veya',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacingLarge),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          hintText: 'ornek@email.com',
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: AppSpacing.itemSpacing),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Şifre',
                          hintText: 'En az 6 karakter',
                        ),
                        validator: _validatePassword,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (_errorMessage case final message?) ...[
                        const SizedBox(height: AppSpacing.itemSpacing),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7F4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF0D3CB)),
                          ),
                          child: Text(
                            message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.caution,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text('İşleniyor...'),
                                  ],
                                )
                              : Text(_isSignIn ? 'Giriş Yap' : 'Hesap Oluştur'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.itemSpacing),
                      TextButton(
                        onPressed: _isLoading ? null : _switchMode,
                        child: Text(
                          _isSignIn
                              ? 'Hesabın yok mu? Hesap oluştur'
                              : 'Zaten hesabın var mı? Giriş yap',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
