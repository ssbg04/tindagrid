class SyncState {
  final bool isSyncing;
  final bool isRestoring;
  final DateTime? lastSyncedAt;
  final int pendingCount;
  final String? lastError;
  final bool isOnline;

  const SyncState({
    this.isSyncing = false,
    this.isRestoring = false,
    this.lastSyncedAt,
    this.pendingCount = 0,
    this.lastError,
    this.isOnline = true,
  });

  SyncState copyWith({
    bool? isSyncing,
    bool? isRestoring,
    DateTime? lastSyncedAt,
    int? pendingCount,
    String? lastError,
    bool? isOnline,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      isRestoring: isRestoring ?? this.isRestoring,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingCount: pendingCount ?? this.pendingCount,
      lastError: lastError,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
