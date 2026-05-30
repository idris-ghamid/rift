import 'dart:async';

/// Event log and audit trail for Rift.
/// Records all modifications with timestamps for compliance and debugging.
class AuditLog {
  final List<AuditEntry> _entries = [];
  final StreamController<AuditEntry> _controller = StreamController.broadcast();
  final int _maxEntries;

  /// Stream of audit entries (real-time).
  Stream<AuditEntry> get stream => _controller.stream;

  /// Create an audit log with a maximum number of entries (default 10000).
  AuditLog({int maxEntries = 10000}) : _maxEntries = maxEntries;

  /// Log an operation.
  void log(
    AuditAction action,
    String boxName, {
    String? key,
    dynamic oldValue,
    dynamic newValue,
  }) {
    final entry = AuditEntry(
      id: _entries.length,
      timestamp: DateTime.now(),
      action: action,
      boxName: boxName,
      key: key,
      oldValue: oldValue,
      newValue: newValue,
    );
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
    _controller.add(entry);
  }

  /// Get all entries, optionally filtered.
  List<AuditEntry> getEntries({
    String? boxName,
    AuditAction? action,
    DateTime? since,
    DateTime? until,
  }) {
    return _entries.where((e) {
      if (boxName != null && e.boxName != boxName) return false;
      if (action != null && e.action != action) return false;
      if (since != null && e.timestamp.isBefore(since)) return false;
      if (until != null && e.timestamp.isAfter(until)) return false;
      return true;
    }).toList();
  }

  /// Get entries for a specific key.
  List<AuditEntry> getEntriesForKey(String boxName, String key) {
    return _entries.where((e) => e.boxName == boxName && e.key == key).toList();
  }

  /// Get the latest entry, optionally filtered.
  AuditEntry? getLatest({String? boxName, AuditAction? action}) {
    for (int i = _entries.length - 1; i >= 0; i--) {
      final entry = _entries[i];
      if (boxName != null && entry.boxName != boxName) continue;
      if (action != null && entry.action != action) continue;
      return entry;
    }
    return null;
  }

  /// Export audit log as JSON-serializable list.
  List<Map<String, dynamic>> exportJson() =>
      _entries.map((e) => e.toJson()).toList();

  /// Export audit log filtered by box name.
  List<Map<String, dynamic>> exportJsonForBox(String boxName) {
    return _entries
        .where((e) => e.boxName == boxName)
        .map((e) => e.toJson())
        .toList();
  }

  /// Clear the audit log.
  void clear() {
    _entries.clear();
  }

  /// Number of entries in the audit log.
  int get length => _entries.length;

  /// Whether the audit log is empty.
  bool get isEmpty => _entries.isEmpty;

  /// Dispose the audit log.
  void dispose() {
    _controller.close();
  }
}

/// Audit action types.
enum AuditAction {
  /// A new key-value pair was created.
  create,

  /// A value was read.
  read,

  /// An existing key-value pair was updated.
  update,

  /// A key-value pair was deleted.
  delete,

  /// The box was cleared.
  clear,
}

/// A single audit log entry.
class AuditEntry {
  /// Auto-incrementing entry ID.
  final int id;

  /// When this entry was recorded.
  final DateTime timestamp;

  /// The action that was performed.
  final AuditAction action;

  /// The name of the box.
  final String boxName;

  /// The key that was affected.
  final String? key;

  /// The value before the action.
  final dynamic oldValue;

  /// The value after the action.
  final dynamic newValue;

  /// Create an audit entry.
  AuditEntry({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.boxName,
    this.key,
    this.oldValue,
    this.newValue,
  });

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'ts': timestamp.toIso8601String(),
    'action': action.name,
    'box': boxName,
    'key': key,
    'old': oldValue?.toString(),
    'new': newValue?.toString(),
  };

  @override
  String toString() =>
      'AuditEntry(#$id, $action, box: $boxName, key: $key, $timestamp)';
}
