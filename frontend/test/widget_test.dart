import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindagrid/main.dart';

void main() {
  testWidgets('TindaGrid app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TindaGridApp(),
      ),
    );

    // Verify TindaGrid brand name is present
    expect(find.text('TindaGrid'), findsOneWidget);
    // Verify offline safe badge is present
    expect(find.text('Ligtas (Offline)'), findsOneWidget);
  });
}
