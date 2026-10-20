import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindagrid/main.dart';

void main() {
  testWidgets('TindaGrid navigation, flat theme, and bilingual test', (WidgetTester tester) async {
    // Provide a standard phone screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: TindaGridApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Brand name and default Taglish state on POS
    expect(find.text('TindaGrid'), findsOneWidget);
    expect(find.text('Ligtas (Offline)'), findsOneWidget);

    // 2. Verify Android Navigation Bar destinations are present in Taglish
    expect(find.text('POS'), findsOneWidget);
    expect(find.text('Paninda'), findsOneWidget);
    expect(find.text('Utang'), findsOneWidget);
    expect(find.text('GCash'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // 3. Test 1-Tap Theme Toggle in AppBar
    final themeToggleIcon = find.byIcon(Icons.light_mode_outlined);
    final darkToggleIcon = find.byIcon(Icons.dark_mode_outlined);
    expect(themeToggleIcon.evaluate().isNotEmpty || darkToggleIcon.evaluate().isNotEmpty, isTrue);

    if (themeToggleIcon.evaluate().isNotEmpty) {
      await tester.tap(themeToggleIcon);
    } else {
      await tester.tap(darkToggleIcon);
    }
    await tester.pumpAndSettle();

    // 4. Test 1-Tap Language Toggle in AppBar (Taglish -> English)
    final langToggle = find.text('Taglish');
    expect(langToggle, findsOneWidget);
    await tester.tap(langToggle);
    await tester.pumpAndSettle();

    // Verify UI switched to English
    expect(find.text('Safe (Offline)'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Debts'), findsOneWidget);

    // 5. Test Navigation Bar Switch to Settings Screen
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Settings screen should be visible with English labels & Theme controls
    expect(find.text('Store Settings'), findsOneWidget);
    expect(find.text('Display Theme'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Display Language'), findsOneWidget);
    expect(find.text('Cloud Backup & Sync'), findsOneWidget);

    // Test Theme selection on Settings screen
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    // 6. Test Switching back to Taglish via Settings button
    await tester.tap(find.text('Taglish'));
    await tester.pumpAndSettle();

    // Settings screen should update to Taglish labels
    expect(find.text('Pag-aayos ng Tindahan'), findsOneWidget);
    expect(find.text('Tema (Anyo ng Screen)'), findsOneWidget);
    expect(find.text('Piliin ang Wika'), findsOneWidget);
    expect(find.text('Paninda'), findsOneWidget);
    expect(find.text('Utang'), findsOneWidget);

    // 7. Navigate back to POS
    await tester.tap(find.text('POS'));
    await tester.pumpAndSettle();

    expect(find.text('Ligtas (Offline)'), findsOneWidget);
    expect(find.text('MABILISANG TINGI (Walang Barcode — Pindutin Agad):'), findsOneWidget);
  });
}
