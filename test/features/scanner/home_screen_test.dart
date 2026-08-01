import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('displays the scan action', (tester) async {
    SharedPreferences.setMockInitialValues({
      'labelwise_onboarding_completed': true,
    });
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      Supabase.instance.client;
    } on AssertionError {
      await Supabase.initialize(
        url: 'https://example.supabase.co',
        publishableKey: 'test-anon-key',
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: false,
        ),
      );
    }

    await tester.pumpWidget(const LabelWiseApp());
    await tester.pumpAndSettle();

    expect(find.text('Barkod Tara'), findsOneWidget);
  });
}
