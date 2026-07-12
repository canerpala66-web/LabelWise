import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:labelwise/core/theme/app_theme.dart';
import 'package:labelwise/features/admin/presentation/screens/admin_review_screen.dart';
import 'package:labelwise/features/scanner/presentation/screens/home_screen.dart';

class LabelWiseApp extends StatelessWidget {
  const LabelWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LabelWise',
      theme: AppTheme.light(),
      home: const HomeScreen(),
      routes: {
        // Admin panel is debug-only for now.
        // Production admin will move to a separate authenticated admin app.
        if (kDebugMode) '/admin-review': (context) => const AdminReviewScreen(),
      },
    );
  }
}
