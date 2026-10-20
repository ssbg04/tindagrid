import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'sync_engine.dart';
import 'sync_models.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(databaseProvider);
  final engine = SyncEngine(db: db);
  ref.onDispose(() => engine.dispose());
  return engine;
});

class SyncNotifier extends Notifier<SyncState> {
  StreamSubscription<int>? _pendingCountSub;

  @override
  SyncState build() {
    _init();
    return const SyncState(isSyncing: false);
  }

  SyncEngine get _engine => ref.read(syncEngineProvider);
  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> _init() async {
    // Watch real-time pending sync queue count from local SQLite
    _pendingCountSub?.cancel();
    _pendingCountSub = _db.watchPendingSyncCount().listen((count) {
      state = state.copyWith(pendingCount: count);
    });

    final lastSyncedAt = await _engine.getLastSyncedAt();
    final isOnline = await _engine.checkIsOnline();

    state = state.copyWith(
      lastSyncedAt: lastSyncedAt,
      isOnline: isOnline,
    );

    // Register background connectivity listener
    _engine.startAutoWorker(
      onTriggerSync: () {
        syncNow(isSilent: true);
      },
    );
  }

  /// Trigger manual or background synchronization
  Future<bool> syncNow({bool isSilent = false}) async {
    if (state.isSyncing) return false;

    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      final isOnline = await _engine.checkIsOnline();
      state = state.copyWith(isOnline: isOnline);

      if (!isOnline) {
        state = state.copyWith(
          isSyncing: false,
          lastError: 'Walang koneksyon sa internet. Naka-queue ang iyong mga benta offline.',
        );
        return false;
      }

      final success = await _engine.syncNow();
      final now = DateTime.now();

      state = state.copyWith(
        isSyncing: false,
        lastSyncedAt: success ? now : state.lastSyncedAt,
        lastError: null,
      );
      return success;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
      if (!isSilent) rethrow;
      return false;
    }
  }

  /// Trigger Cloud Disaster Recovery (rehydrate full store snapshot)
  Future<Map<String, dynamic>> restoreFromCloud() async {
    state = state.copyWith(isRestoring: true, lastError: null);

    try {
      final counts = await _engine.restoreFromCloud();
      final now = DateTime.now();

      state = state.copyWith(
        isRestoring: false,
        lastSyncedAt: now,
        lastError: null,
      );
      return counts;
    } catch (e) {
      state = state.copyWith(
        isRestoring: false,
        lastError: e.toString(),
      );
      rethrow;
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
