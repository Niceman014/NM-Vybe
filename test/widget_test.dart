import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nm_vybe/app.dart';

void main() {
  testWidgets('NM VYBE settings app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NmVybeApp(),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Check for Updates'), findsOneWidget);
  });
}