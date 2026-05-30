/// Supporting types for the sync layer.
library;

/// A cursor that tracks the position in the sync stream.
class SyncCursor {
  /// The timestamp of the last successful sync.
  final DateTime lastSync;

  /// An optional token for cursor-based pagination.
  final String? token;

  /// Create a sync cursor.
  SyncCursor(this.lastSync, this.token);

  Map<String, dynamic> toJson() => {
    'lastSync': lastSync.toIso8601String(),
    'token': token,
  };

  static SyncCursor fromJson(Map<String, dynamic> json) => SyncCursor(
    DateTime.parse(json['lastSync'] as String),
    json['token'] as String?,
  );
}

/// Types of sync events.
enum SyncEventType {
  /// A sync operation has started.
  syncStarted,

  /// A sync operation has completed.
  syncCompleted,

  /// A conflict was detected during sync.
  conflictDetected,

  /// An error occurred during sync.
  error,

  /// The sync backend is connected.
  connected,

  /// The sync backend is disconnected.
  disconnected,
}
