import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:tindagrid/core/database/app_database.dart';
import 'package:tindagrid/features/gcash/gcash_receipt_ocr_service.dart';
import 'package:tindagrid/features/gcash/rate_card_pdf_service.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 4: GCash Float Ledger, Fee Scheduler & Rate Card PDF Tests', () {
    test('4.1 Dual-Float Tracking Engine calculates real-time balances and fee profit', () async {
      const baseCash = 5000.0;
      const baseGcash = 10000.0;

      // 1. Initial State
      var stream = db.watchDualFloatBalance(baseCash: baseCash, baseGcash: baseGcash);
      var initial = await stream.first;
      expect(initial.gcashFloat, equals(10000.0));
      expect(initial.cashDrawer, equals(5000.0));
      expect(initial.totalFeesEarned, equals(0.0));

      // 2. Perform Cash-In: Customer deposits ₱500, pays ₱10 fee
      // Cash Drawer gets ₱510. GCash float loses ₱500.
      await db.recordGcash(
        transactionType: 'CASH_IN',
        amount: 500.0,
        feeCharged: 10.0,
        referenceNumber: '1002481029412',
        customerName: 'Maria Santos',
        customerPhone: '09171234567',
      );

      var afterCashIn = await stream.first;
      expect(afterCashIn.gcashFloat, equals(9500.0));
      expect(afterCashIn.cashDrawer, equals(5510.0));
      expect(afterCashIn.totalFeesEarned, equals(10.0));
      expect(afterCashIn.cashInCount, equals(1));

      // 3. Perform Cash-Out: Customer withdraws ₱1,000, pays ₱15 fee
      // GCash float receives ₱1,000. Cash Drawer pays out net ₱985 (₱1000 - ₱15 fee)
      await db.recordGcash(
        transactionType: 'CASH_OUT',
        amount: 1000.0,
        feeCharged: 15.0,
        referenceNumber: '0021984210984',
        customerName: 'Juan Dela Cruz',
        customerPhone: '09189876543',
      );

      var afterCashOut = await stream.first;
      expect(afterCashOut.gcashFloat, equals(10500.0));
      expect(afterCashOut.cashDrawer, equals(4525.0));
      expect(afterCashOut.totalFeesEarned, equals(25.0));
      expect(afterCashOut.cashOutCount, equals(1));

      // 4. Store Payment: Customer pays ₱200 grocery bill via GCash QR
      // GCash float increases by ₱200. Cash drawer untouched.
      await db.recordGcash(
        transactionType: 'STORE_PAYMENT',
        amount: 200.0,
        feeCharged: 0.0,
        referenceNumber: '9921048123901',
      );

      var afterPayment = await stream.first;
      expect(afterPayment.gcashFloat, equals(10700.0));
      expect(afterPayment.cashDrawer, equals(4525.0));
      expect(afterPayment.storePaymentCount, equals(1));
    });

    test('4.1 Anti-Fraud: Reference number duplicate detection catches recycled receipts', () async {
      await db.recordGcash(
        transactionType: 'CASH_IN',
        amount: 300.0,
        feeCharged: 10.0,
        referenceNumber: '1002 9481 02941',
      );

      // Check with exact string
      expect(await db.isReferenceNumberUsed('1002 9481 02941'), isTrue);

      // Check without spaces (sanitized comparison)
      expect(await db.isReferenceNumberUsed('1002948102941'), isTrue);

      // Check non-existing reference number
      expect(await db.isReferenceNumberUsed('9999999999999'), isFalse);
    });

    test('4.2 Customizable Fee Brackets seeds, saves, and calculates tiered rates', () async {
      // 1. Seed defaults
      await db.seedDefaultFeeBrackets();
      final brackets = await db.getFeeBrackets();
      expect(brackets.length, greaterThanOrEqualTo(6));

      // Verify default fee for ₱500 is ₱10.00
      final fee500 = await db.calculateGcashFee(500.0);
      expect(fee500, equals(10.0));

      // Verify default fee for ₱800 is ₱15.00
      final fee800 = await db.calculateGcashFee(800.0);
      expect(fee800, equals(15.0));

      // 2. Add custom bracket: ₱10,001 - ₱20,000 at 2.0%
      await db.saveFeeBracket(
        const GcashFeeConfigCompanion(
          id: drift.Value('bracket-tier-high'),
          minAmount: drift.Value(10001.0),
          maxAmount: drift.Value(20000.0),
          fixedFee: drift.Value(0.0),
          percentageFee: drift.Value(2.0),
        ),
      );

      final fee15000 = await db.calculateGcashFee(15000.0);
      expect(fee15000, equals(300.0)); // 2% of 15,000
    });

    test('4.3 Printable Rate Card PDF generates valid bytes for A4, A5, and Thermal formats', () async {
      await db.seedDefaultFeeBrackets();
      final brackets = await db.getFeeBrackets();

      // Test A4 Sheet PDF
      final a4Bytes = await RateCardPdfService.generateRateCardPdf(
        storeName: 'Aling Nena Tindahan',
        brackets: brackets,
        format: RateCardFormat.a4Sheet,
        gcashNumber: '0917-123-4567',
      );
      expect(a4Bytes, isNotEmpty);
      expect(a4Bytes.length, greaterThan(1000));

      // Test A5 Half Sheet PDF
      final a5Bytes = await RateCardPdfService.generateRateCardPdf(
        storeName: 'Aling Nena Tindahan',
        brackets: brackets,
        format: RateCardFormat.a5HalfSheet,
      );
      expect(a5Bytes, isNotEmpty);

      // Test 80mm POS Thermal Receipt PDF
      final thermalBytes = await RateCardPdfService.generateRateCardPdf(
        storeName: 'Aling Nena Tindahan',
        brackets: brackets,
        format: RateCardFormat.posThermal80mm,
      );
      expect(thermalBytes, isNotEmpty);
    });

    test('4.4 On-Device Receipt OCR parses 13-digit Reference and Amount from raw text', () {
      const smsText =
          'You have received PHP 1,500.00 of GCash from Juan Dela Cruz (09181234567) on 10/20/2026. Ref. No. 1002 481 029412.';

      final result = GcashReceiptOcrService.parseRawText(smsText);
      expect(result.isSuccess, isTrue);
      expect(result.referenceNumber, equals('1002481029412'));
      expect(result.amount, equals(1500.0));

      // Test solid reference format
      const solidRefText = 'Transaction Successful! Amount: P 250.00 Ref No: 0021482910245';
      final solidResult = GcashReceiptOcrService.parseRawText(solidRefText);
      expect(solidResult.isSuccess, isTrue);
      expect(solidResult.referenceNumber, equals('0021482910245'));
      expect(solidResult.amount, equals(250.0));
    });
  });
}
