import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindagrid/core/catalog/catalog_client.dart';
import 'package:tindagrid/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3.3: Crowdsourced Barcode Catalog & Quick-Add Tests', () {
    test('CatalogClient resolves master Philippine sari-sari barcodes offline', () async {
      final client = CatalogClient();

      // 1. Known master barcode: Lucky Me! Instant Pancit Canton Original
      final result = await client.lookupBarcode('4800016644819');
      expect(result.found, isTrue);
      expect(result.name, contains('Lucky Me! Instant Pancit Canton'));
      expect(result.category, equals('Noodles'));
      expect(result.defaultPrice, equals(18.0));

      // 2. Known master barcode: Bear Brand Fortified Powdered Milk
      final bearBrand = await client.lookupBarcode('4800888137358');
      expect(bearBrand.found, isTrue);
      expect(bearBrand.name, contains('Bear Brand'));
      expect(bearBrand.defaultPrice, equals(15.0));

      // 3. Unknown barcode
      final unknown = await client.lookupBarcode('9999999999999');
      expect(unknown.found, isFalse);
      expect(unknown.barcode, equals('9999999999999'));
    });

    test('Quick-Add saves new product to SQLite and allows immediate POS lookup', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => db.close());

      const testBarcode = '4800047820014'; // Safeguard Pure White Bar Soap 60g

      await db.saveProduct(
        const ProductsCompanion(
          id: Value('prod-safeguard'),
          barcode: Value(testBarcode),
          name: Value('Safeguard Pure White 60g'),
          category: Value('Personal Care'),
          costPrice: Value(20.0),
          sellingPrice: Value(25.0),
          currentStock: Value(12.0),
          isTingi: Value(false),
        ),
      );

      final lookup = await db.getProductByBarcode(testBarcode);
      expect(lookup, isNotNull);
      expect(lookup!.name, equals('Safeguard Pure White 60g'));
      expect(lookup.sellingPrice, equals(25.0));
      expect(lookup.currentStock, equals(12.0));

      // Verify mutation was also queued for background delta sync
      final syncQueueItems = await db.select(db.syncQueue).get();
      expect(syncQueueItems.length, equals(1));
      expect(syncQueueItems.first.entityTable, equals('products'));
      expect(syncQueueItems.first.operation, equals('UPSERT'));
    });
  });
}
