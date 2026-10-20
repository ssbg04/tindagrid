import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindagrid/core/sync/companion_scanner_service.dart';
import 'package:tindagrid/core/utils/barcode_keyboard_listener.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3.2: Barcode & Checkout Fallback Tests', () {
    test('BarcodeKeyboardListener buffers characters and invokes callback on Enter', () async {
      String? scannedBarcode;
      final listener = BarcodeKeyboardListener(
        minBarcodeLength: 3,
        maxInterKeyDelayMs: 300,
        onBarcodeScanned: (code) {
          scannedBarcode = code;
        },
      );

      listener.start();

      // Simulate rapid keystrokes from a USB barcode scanner gun: "480001" + Enter
      final digits = [
        (LogicalKeyboardKey.digit4, '4'),
        (LogicalKeyboardKey.digit8, '8'),
        (LogicalKeyboardKey.digit0, '0'),
        (LogicalKeyboardKey.digit0, '0'),
        (LogicalKeyboardKey.digit0, '0'),
        (LogicalKeyboardKey.digit1, '1'),
      ];

      for (final (key, char) in digits) {
        await simulateKeyDownEvent(key, character: char);
      }

      // Scanner sends Enter key
      await simulateKeyDownEvent(LogicalKeyboardKey.enter);

      listener.stop();

      expect(scannedBarcode, equals('480001'));
    });

    test('CompanionScannerService creates session, pushes scan, and polls relay', () async {
      final service = CompanionScannerService();

      // 1. Create companion pairing session
      final session = await service.createSession();
      expect(session.sessionId, isNotEmpty);
      expect(session.pairingCode, startsWith('SCAN-'));
      expect(session.pairUrl, contains(session.sessionId));

      // 2. Mobile device pushes barcode
      final pushOk = await service.pushScan(
        sessionIdOrCode: session.sessionId,
        barcode: '4800016644819',
      );
      expect(pushOk, isTrue);

      // 3. Web POS polls and receives the scan
      final polledScans = await service.pollScans(sessionId: session.sessionId);
      expect(polledScans.length, equals(1));
      expect(polledScans.first.barcode, equals('4800016644819'));
    });
  });
}
