import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class CatalogBarcodeResult {
  final bool found;
  final String barcode;
  final String? name;
  final String? category;
  final double? defaultPrice;
  final int? verifiedCount;
  final String? source;

  const CatalogBarcodeResult({
    required this.found,
    required this.barcode,
    this.name,
    this.category,
    this.defaultPrice,
    this.verifiedCount,
    this.source,
  });

  factory CatalogBarcodeResult.fromJson(Map<String, dynamic> json) {
    return CatalogBarcodeResult(
      found: json['found'] as bool? ?? false,
      barcode: json['barcode'] as String? ?? '',
      name: json['name'] as String?,
      category: json['category'] as String?,
      defaultPrice: (json['defaultPrice'] as num?)?.toDouble(),
      verifiedCount: json['verifiedCount'] as int?,
      source: json['source'] as String?,
    );
  }
}

class CatalogClient {
  final String baseUrl;
  final http.Client _client;

  // Built-in offline master Philippine sari-sari barcode database
  static const Map<String, ({String name, String category, double price})> _offlineMasterSeeds = {
    '4800016644819': (name: 'Lucky Me! Instant Pancit Canton Original 80g', category: 'Noodles', price: 18.0),
    '4800016644826': (name: 'Lucky Me! Instant Pancit Canton Extra Hot 80g', category: 'Noodles', price: 18.0),
    '4800016644802': (name: 'Lucky Me! Instant Pancit Canton Kalamansi 80g', category: 'Noodles', price: 18.0),
    '4800016644833': (name: 'Lucky Me! Instant Pancit Canton Sweet & Spicy 80g', category: 'Noodles', price: 18.0),
    '4800016008802': (name: 'Lucky Me! Instant Mami Beef 55g', category: 'Noodles', price: 16.0),
    '4800016008819': (name: 'Lucky Me! Instant Mami Chicken 55g', category: 'Noodles', price: 16.0),
    '4800888137358': (name: 'Bear Brand Fortified Powdered Milk Drink 33g', category: 'Dairy', price: 15.0),
    '4800024555816': (name: 'Kopiko Blanca 3-in-1 Coffee Twin Pack 52g', category: 'Beverage', price: 14.0),
    '4800024555823': (name: 'Kopiko Brown 3-in-1 Coffee 30g', category: 'Beverage', price: 14.0),
    '4800024555830': (name: 'Kopiko Black 3-in-1 Coffee 30g', category: 'Beverage', price: 14.0),
    '4800016670016': (name: 'Nissin Cup Noodles Seafood 40g', category: 'Noodles', price: 25.0),
    '4800092110017': (name: 'Coca-Cola Mismo 300ml', category: 'Beverage', price: 20.0),
    '4800092110024': (name: 'Royal Tru-Orange Mismo 300ml', category: 'Beverage', price: 20.0),
    '4800092110031': (name: 'Sprite Mismo 300ml', category: 'Beverage', price: 20.0),
    '4800011110012': (name: 'San Miguel Pale Pilsen 330ml Can', category: 'Alcohol', price: 48.0),
    '4800011110029': (name: 'Red Horse Beer 500ml Can', category: 'Alcohol', price: 55.0),
    '4800110021008': (name: 'Datu Puti White Vinegar 100ml Sachet', category: 'Condiments', price: 6.0),
    '4800110022005': (name: 'Silver Swan Soy Sauce 100ml Sachet', category: 'Condiments', price: 6.0),
    '4800047820014': (name: 'Safeguard Pure White Bar Soap 60g', category: 'Personal Care', price: 25.0),
    '4800047820021': (name: 'Palmolive Intensive Moisture Shampoo 15ml', category: 'Personal Care', price: 7.0),
  };

  CatalogClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? ApiConstants.defaultBaseUrl,
        _client = client ?? http.Client();

  /// Lookup barcode from master crowdsourced database with offline fallback
  Future<CatalogBarcodeResult> lookupBarcode(String barcode) async {
    final clean = barcode.trim();

    // 1. Try remote NestJS catalog API
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/catalog/barcode/$clean'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['found'] == true) {
          return CatalogBarcodeResult.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Remote catalog lookup fallback: $e');
    }

    // 2. Check offline master Philippine catalog seeds
    final seed = _offlineMasterSeeds[clean];
    if (seed != null) {
      return CatalogBarcodeResult(
        found: true,
        barcode: clean,
        name: seed.name,
        category: seed.category,
        defaultPrice: seed.price,
        verifiedCount: 150,
        source: 'local_master_seed',
      );
    }

    return CatalogBarcodeResult(
      found: false,
      barcode: clean,
    );
  }

  /// Crowdsource: upload/contribute newly created product barcode to global registry
  Future<bool> contributeBarcode({
    required String barcode,
    required String name,
    String? category,
    double? defaultPrice,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/catalog/barcode/contribute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'barcode': barcode.trim(),
          'name': name.trim(),
          'category': category ?? 'General',
          'defaultPrice': defaultPrice ?? 0.0,
        }),
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Barcode crowdsource contribution error: $e');
      return false;
    }
  }
}
