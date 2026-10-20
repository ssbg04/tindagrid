import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../database/app_database.dart';

class SyncEngine {
  final AppDatabase db;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  final Connectivity _connectivity;
  final String baseUrl;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;
  bool _isSyncing = false;

  SyncEngine({
    required this.db,
    http.Client? client,
    FlutterSecureStorage? storage,
    Connectivity? connectivity,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage(),
        _connectivity = connectivity ?? Connectivity(),
        baseUrl = baseUrl ?? ApiConstants.defaultBaseUrl;

  static const _keyAccessToken = 'tg_access_token';
  static const _keyLastSyncTimestamp = 'tg_last_sync_timestamp';
  static const _keyLastSyncDisplay = 'tg_last_sync_display';

  /// Start automatic background worker that syncs when internet connects and periodically
  void startAutoWorker({required void Function() onTriggerSync}) {
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
      if (isConnected) {
        onTriggerSync();
      }
    });

    // Run periodic sync check every 5 minutes
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      onTriggerSync();
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
  }

  /// Check whether the device currently has active internet connectivity
  Future<bool> checkIsOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
    } catch (_) {
      return false;
    }
  }

  /// Get the last successfully synced display timestamp
  Future<DateTime?> getLastSyncedAt() async {
    final raw = await _storage.read(key: _keyLastSyncDisplay);
    if (raw != null) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  /// Main Delta Synchronization Engine
  /// 1. Pushes local mutations to Neon cloud (with Last-Write-Wins and additive idempotency)
  /// 2. Pulls remote deltas since lastSyncTimestamp and updates local SQLite
  Future<bool> syncNow({String? storeId}) async {
    if (_isSyncing) return false;
    _isSyncing = true;

    try {
      final token = await _storage.read(key: _keyAccessToken);
      if (token == null) {
        // Unauthenticated / local offline mode
        return false;
      }

      // Step 1: Push pending local changes to cloud
      final pending = await db.getPendingSyncQueue(limit: 100);
      if (pending.isNotEmpty) {
        final mutations = pending.map((item) {
          dynamic payloadData;
          try {
            payloadData = jsonDecode(item.payload);
          } catch (_) {
            payloadData = {'raw': item.payload};
          }

          return {
            'id': item.id,
            'entityTable': item.entityTable,
            'entityId': item.entityId,
            'operation': item.operation,
            'payload': payloadData,
            'clientTimestamp': item.createdAt.toIso8601String(),
          };
        }).toList();

        final pushResponse = await _client.post(
          Uri.parse('$baseUrl/sync/push'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'storeId': storeId,
            'mutations': mutations,
          }),
        );

        if (pushResponse.statusCode >= 200 && pushResponse.statusCode < 300) {
          final pushData = jsonDecode(pushResponse.body) as Map<String, dynamic>;
          final syncedIds = (pushData['syncedIds'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          await db.markSyncSuccessBatch(syncedIds);
        } else {
          debugPrint('Sync Push Warning: ${pushResponse.statusCode} - ${pushResponse.body}');
        }
      }

      // Step 2: Pull remote deltas from cloud
      final lastSyncTime = await _storage.read(key: _keyLastSyncTimestamp);
      final queryParams = <String, String>{};
      if (storeId != null) queryParams['storeId'] = storeId;
      if (lastSyncTime != null) queryParams['since'] = lastSyncTime;

      final pullUri = Uri.parse('$baseUrl/sync/pull').replace(queryParameters: queryParams);
      final pullResponse = await _client.get(
        pullUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (pullResponse.statusCode >= 200 && pullResponse.statusCode < 300) {
        final pullData = jsonDecode(pullResponse.body) as Map<String, dynamic>;

        // Apply remote deltas with conflict resolution
        if (pullData['products'] != null) {
          await db.applyRemoteProducts(pullData['products'] as List<dynamic>);
        }
        if (pullData['sales'] != null) {
          await db.applyRemoteSales(pullData['sales'] as List<dynamic>);
        }
        if (pullData['debts'] != null) {
          await db.applyRemoteDebts(pullData['debts'] as List<dynamic>);
        }
        if (pullData['gcash'] != null) {
          await db.applyRemoteGcash(pullData['gcash'] as List<dynamic>);
        }

        // Save server timestamp for incremental delta tracking
        final serverTime = pullData['serverTimestamp'] as String?;
        if (serverTime != null) {
          await _storage.write(key: _keyLastSyncTimestamp, value: serverTime);
        }

        final nowIso = DateTime.now().toIso8601String();
        await _storage.write(key: _keyLastSyncDisplay, value: nowIso);
        return true;
      } else {
        debugPrint('Sync Pull Warning: ${pullResponse.statusCode} - ${pullResponse.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Sync Exception: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Cloud Disaster Recovery: Rehydrate entire store catalog, debts, and sales
  /// from Neon PostgreSQL on new device login
  Future<Map<String, dynamic>> restoreFromCloud({String? storeId}) async {
    final token = await _storage.read(key: _keyAccessToken);
    if (token == null) {
      throw Exception('Kailangan munang mag-login para mag-restore mula sa cloud.');
    }

    final queryParams = <String, String>{};
    if (storeId != null) queryParams['storeId'] = storeId;

    final restoreUri = Uri.parse('$baseUrl/sync/restore').replace(queryParameters: queryParams);
    final response = await _client.get(
      restoreUri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      await db.restoreCloudSnapshot(
        remoteProducts: (data['products'] as List<dynamic>?) ?? [],
        remoteDebts: (data['debts'] as List<dynamic>?) ?? [],
        remoteSales: (data['sales'] as List<dynamic>?) ?? [],
        remoteGcash: (data['gcash'] as List<dynamic>?) ?? [],
      );

      final serverTime = data['serverTimestamp'] as String?;
      if (serverTime != null) {
        await _storage.write(key: _keyLastSyncTimestamp, value: serverTime);
      }

      final nowIso = DateTime.now().toIso8601String();
      await _storage.write(key: _keyLastSyncDisplay, value: nowIso);

      return data['counts'] as Map<String, dynamic>? ?? {};
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Nabigo ang cloud disaster recovery');
    }
  }
}
