import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:labelwise/core/theme/app_theme.dart';
import 'package:labelwise/features/admin/presentation/screens/admin_review_screen.dart';
import 'package:labelwise/features/auth/presentation/screens/auth_screen.dart';
import 'package:labelwise/features/onboarding/data/onboarding_repository.dart';
import 'package:labelwise/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:labelwise/features/profile/presentation/screens/profile_screen.dart';
import 'package:labelwise/features/scanner/presentation/screens/home_screen.dart';

class LabelWiseApp extends StatelessWidget {
  const LabelWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LabelWise',
      theme: AppTheme.light(),
      home: const _AppEntryScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/profile': (context) => const ProfileScreen(),
        // Admin panel is debug-only for now.
        // Production admin will move to a separate authenticated admin app.
        if (kDebugMode) '/admin-review': (context) => const AdminReviewScreen(),
      },
    );
  }
}

class _AppEntryScreen extends StatelessWidget {
  const _AppEntryScreen();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: const OnboardingRepository().isCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final completed = snapshot.data ?? false;
        return completed ? const HomeScreen() : const OnboardingScreen();
      },
    );
  }
}
