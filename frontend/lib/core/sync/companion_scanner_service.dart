import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class CompanionSessionInfo {
  final String sessionId;
  final String pairingCode;
  final String pairUrl;
  final DateTime expiresAt;

  const CompanionSessionInfo({
    required this.sessionId,
    required this.pairingCode,
    required this.pairUrl,
    required this.expiresAt,
  });

  factory CompanionSessionInfo.fromJson(Map<String, dynamic> json) {
    return CompanionSessionInfo(
      sessionId: json['sessionId'] as String,
      pairingCode: json['pairingCode'] as String,
      pairUrl: json['pairUrl'] as String? ?? 'tindagrid://pair-scanner?sessionId=${json['sessionId']}',
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(const Duration(minutes: 30)),
    );
  }
}

class CompanionScanEvent {
  final String id;
  final String barcode;
  final DateTime scannedAt;

  const CompanionScanEvent({
    required this.id,
    required this.barcode,
    required this.scannedAt,
  });

  factory CompanionScanEvent.fromJson(Map<String, dynamic> json) {
    return CompanionScanEvent(
      id: json['id'] as String,
      barcode: json['barcode'] as String,
      scannedAt: json['scannedAt'] != null
          ? DateTime.parse(json['scannedAt'] as String)
          : DateTime.now(),
    );
  }
}

class CompanionScannerService {
  final String baseUrl;
  final http.Client _client;

  // Local fallback storage for demo / offline companion emulation
  static final Map<String, List<CompanionScanEvent>> _localEmulatedScans = {};

  CompanionScannerService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? ApiConstants.defaultBaseUrl,
        _client = client ?? http.Client();

  /// Create a new session for pairing Web POS with a mobile phone
  Future<CompanionSessionInfo> createSession({String? storeId}) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/sync/companion/session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'storeId': storeId}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CompanionSessionInfo.fromJson(data);
      }
    } catch (e) {
      debugPrint('Companion session network fallback: $e');
    }

    // Offline / Local fallback simulation
    final localId = 'SES-LOCAL-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final code = 'SCAN-${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}';
    _localEmulatedScans[localId] = [];
    _localEmulatedScans[code] = _localEmulatedScans[localId]!;

    return CompanionSessionInfo(
      sessionId: localId,
      pairingCode: code,
      pairUrl: 'tindagrid://pair-scanner?sessionId=$localId&code=$code',
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );
  }

  /// Phone pushes a scanned barcode into the session
  Future<bool> pushScan({
    required String sessionIdOrCode,
    required String barcode,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/sync/companion/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionIdOrCode,
          'barcode': barcode.trim(),
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      debugPrint('Companion push scan fallback: $e');
    }

    // Local in-memory emulation
    final list = _localEmulatedScans[sessionIdOrCode];
    if (list != null) {
      list.add(CompanionScanEvent(
        id: 'scan-${DateTime.now().millisecondsSinceEpoch}',
        barcode: barcode.trim(),
        scannedAt: DateTime.now(),
      ));
      return true;
    }
    return false;
  }

  /// Web POS polls for new scans pushed from the paired phone
  Future<List<CompanionScanEvent>> pollScans({
    required String sessionId,
    String? sinceScanId,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/sync/companion/poll?sessionId=$sessionId');
      if (sinceScanId != null) {
        uri = Uri.parse('$baseUrl/sync/companion/poll?sessionId=$sessionId&sinceScanId=$sinceScanId');
      }

      final response = await _client.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawList = data['newScans'] as List<dynamic>? ?? [];
        return rawList
            .map((item) => CompanionScanEvent.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Companion poll network fallback: $e');
    }

    // Local fallback check
    final list = _localEmulatedScans[sessionId];
    if (list != null && list.isNotEmpty) {
      if (sinceScanId == null) {
        return List.from(list);
      }
      final idx = list.indexWhere((s) => s.id == sinceScanId);
      if (idx != -1) {
        return list.sublist(idx + 1);
      }
      return List.from(list);
    }

    return [];
  }
}
