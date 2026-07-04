import 'package:flutter_test/flutter_test.dart';
import 'package:labelwise/app/app.dart';

void main() {
  testWidgets('displays the scan action', (tester) async {
    await tester.pumpWidget(const LabelWiseApp());

    expect(find.text('Barkod Taramaya Başla'), findsOneWidget);
  });
}
