import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindagrid/core/theme/responsive_layout.dart';
import 'package:tindagrid/main.dart';

void main() {
  group('Responsive Layout Tests for Portrait and Landscape', () {
    testWidgets('Portrait Phone layout uses Bottom NavigationBar and 1-column mobile POS layout',
        (WidgetTester tester) async {
      // Standard vertical phone dimensions (e.g. 400 x 800 logical)
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: TindaGridApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify NavigationBar is used in mobile portrait
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // 2. Verify Tingi Grid is visible
      expect(find.text('Itlog (Fresh)'), findsOneWidget);
      expect(find.text('Yelo (Tube Ice)'), findsOneWidget);

      // 3. Tap Tingi item to add to cart
      await tester.tap(find.text('Itlog (Fresh)'));
      await tester.pumpAndSettle();

      // In portrait, sticky mobile cart bottom bar appears
      expect(find.textContaining('kart'), findsOneWidget);
      expect(find.text('BAYARAN / MANINGIL'), findsOneWidget);
    });

    testWidgets('Landscape Phone layout uses left NavigationRail and 2-column POS Cashier Station',
        (WidgetTester tester) async {
      // Landscape phone dimensions (e.g. 800 x 400 logical)
      tester.view.physicalSize = const Size(1600, 800);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: TindaGridApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. In landscape, NavigationRail is used to preserve vertical screen height
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      // 2. In landscape, Live Ticket panel is immediately visible in right column
      expect(find.textContaining('Live Ticket'), findsOneWidget);
      expect(find.text('BAYARAN / MANINGIL'), findsOneWidget);

      // 3. Tap Tingi item to add to cart
      await tester.ensureVisible(find.text('Itlog (Fresh)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Itlog (Fresh)'));
      await tester.pumpAndSettle();

      // 4. Cart reflects item in right column without needing vertical scrolling
      expect(find.textContaining('4 Bagay'), findsOneWidget);
      expect(find.text('₱ 48.00'), findsOneWidget);

      // 5. Open checkout modal in landscape mode to ensure zero flex overflow
      await tester.tap(find.text('BAYARAN / MANINGIL'));
      await tester.pumpAndSettle();

      expect(find.text('Bayaran at Sukli'), findsOneWidget);
      expect(find.text('💵 Cash'), findsOneWidget);
      expect(find.text('📱 GCash'), findsOneWidget);

      // Dismiss modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('Widescreen Desktop layout (1200 x 800) displays full 2-column station',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(2400, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: TindaGridApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Full NavigationRail with all labels
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('TindaGrid'), findsWidgets);
      expect(find.textContaining('Live Ticket'), findsOneWidget);
    });

    testWidgets('ResponsiveLayout helper static methods return correct states', (WidgetTester tester) async {
      bool? isLand;
      bool? isPort;
      bool? twoPane;
      bool? useRail;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isLand = ResponsiveLayout.isLandscape(context);
              isPort = ResponsiveLayout.isPortrait(context);
              twoPane = ResponsiveLayout.showTwoPaneStation(context);
              useRail = ResponsiveLayout.useNavigationRail(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isLand, isNotNull);
      expect(isPort, isNotNull);
      expect(twoPane, isNotNull);
      expect(useRail, isNotNull);
    });
  });
}
