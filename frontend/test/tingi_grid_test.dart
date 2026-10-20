import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindagrid/features/pos/tingi_visual_grid.dart';

void main() {
  testWidgets('TingiVisualGrid renders unbarcoded goods and handles +1, +5, +10 multipliers', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? addedName;
    double? addedPrice;
    int? addedQty;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TingiVisualGrid(
                isTaglish: true,
                onAddTingi: (name, price, qty) {
                  addedName = name;
                  addedPrice = price;
                  addedQty = qty;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify default tingi buttons are visible
    expect(find.text('Itlog (Fresh)'), findsOneWidget);
    expect(find.text('Yelo (Tube Ice)'), findsOneWidget);
    expect(find.text('Kopiko 78'), findsOneWidget);
    expect(find.text('+ Tingi'), findsOneWidget);

    // 2. Default multiplier is 1x: tap Itlog
    await tester.tap(find.text('Itlog (Fresh)'));
    await tester.pumpAndSettle();

    expect(addedName, equals('Itlog (Fresh)'));
    expect(addedPrice, equals(10.0));
    expect(addedQty, equals(1));

    // 3. Tap +5 multiplier
    await tester.tap(find.text('+5'));
    await tester.pumpAndSettle();

    // Tap Yelo with +5 active
    await tester.tap(find.text('Yelo (Tube Ice)'));
    await tester.pumpAndSettle();

    expect(addedName, equals('Yelo (Tube Ice)'));
    expect(addedPrice, equals(5.0));
    expect(addedQty, equals(5));

    // 4. Tap +10 multiplier
    await tester.tap(find.text('+10'));
    await tester.pumpAndSettle();

    // Tap Kopiko 78 with +10 active
    await tester.tap(find.text('Kopiko 78'));
    await tester.pumpAndSettle();

    expect(addedName, equals('Kopiko 78'));
    expect(addedPrice, equals(14.0));
    expect(addedQty, equals(10));
  });
}
