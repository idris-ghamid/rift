import 'package:rift/rift.dart';

/// Incremental export support for Rift.
/// Exports only changes since the last export for efficient sync/backup.
class IncrementalExporter {
  int _lastExportVersion = 0;
  final Map<String, int> _keyVersions = {}; // key → version when last changed
  int _currentVersion = 0;

  /// Record that a key was put/updated at the current version.
  void recordPut(String key) {
    _currentVersion++;
    _keyVersions[key] = _currentVersion;
  }

  /// Record that a key was deleted at the current version.
  void recordDelete(String key) {
    _currentVersion++;
    _keyVersions.remove(key);
    // Track deletion by marking it in a separate set
    _deletedKeys.add(key);
    _deletedVersions[key] = _currentVersion;
  }

  final Set<String> _deletedKeys = {};
  final Map<String, int> _deletedVersions = {};

  /// Export changes since the last export.
  Future<IncrementalExport> export(Box box) async {
    final upserts = <String, dynamic>{};
    final deletes = <String>[];

    // Find upserts (keys that changed since last export)
    for (final key in box.keys) {
      final keyStr = key.toString();
      final version = _keyVersions[keyStr] ?? 0;
      if (version > _lastExportVersion) {
        upserts[keyStr] = box.get(key);
      }
    }

    // Find deletes
    for (final key in _deletedKeys) {
      final version = _deletedVersions[key] ?? 0;
      if (version > _lastExportVersion) {
        deletes.add(key);
      }
    }

    final fromVersion = _lastExportVersion;
    final toVersion = _currentVersion;
    _lastExportVersion = _currentVersion;

    return IncrementalExport(
      fromVersion: fromVersion,
      toVersion: toVersion,
      exportedAt: DateTime.now(),
      upserts: upserts,
      deletes: deletes,
    );
  }

  /// Import an incremental export into a box.
  Future<void> import(Box box, IncrementalExport data) async {
    // Apply upserts
    if (data.upserts.isNotEmpty) {
      await box.putAll(data.upserts);
    }

    // Apply deletes
    if (data.deletes.isNotEmpty) {
      await box.deleteAll(data.deletes);
    }

    // Update local version tracking
    _currentVersion = max(_currentVersion, data.toVersion);
    _lastExportVersion = max(_lastExportVersion, data.toVersion);
  }

  /// The current version number.
  int get currentVersion => _currentVersion;

  /// The version of the last export.
  int get lastExportVersion => _lastExportVersion;

  /// Reset the exporter state.
  void reset() {
    _lastExportVersion = 0;
    _currentVersion = 0;
    _keyVersions.clear();
    _deletedKeys.clear();
    _deletedVersions.clear();
  }

  /// Returns the max of two integers.
  static int max(int a, int b) => a > b ? a : b;
}

/// Represents an incremental export of changes.
class IncrementalExport {
  /// The starting version of this export.
  final int fromVersion;

  /// The ending version of this export.
  final int toVersion;

  /// When this export was created.
  final DateTime exportedAt;

  /// Keys that were created or updated, mapped to their values.
  final Map<String, dynamic> upserts;

  /// Keys that were deleted.
  final List<String> deletes;

  /// Create an incremental export.
  IncrementalExport({
    required this.fromVersion,
    required this.toVersion,
    required this.exportedAt,
    required this.upserts,
    required this.deletes,
  });

  /// Whether this export contains any changes.
  bool get isEmpty => upserts.isEmpty && deletes.isEmpty;

  /// Number of changes in this export.
  int get changeCount => upserts.length + deletes.length;

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
    'fromVersion': fromVersion,
    'toVersion': toVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'upserts': upserts,
    'deletes': deletes,
  };

  /// Deserialize from JSON.
  static IncrementalExport fromJson(Map<String, dynamic> json) {
    return IncrementalExport(
      fromVersion: json['fromVersion'] as int,
      toVersion: json['toVersion'] as int,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      upserts: Map<String, dynamic>.from(json['upserts'] as Map),
      deletes: List<String>.from(json['deletes'] as List),
    );
  }

  @override
  String toString() =>
      'IncrementalExport(v$fromVersion..v$toVersion, ${upserts.length} upserts, ${deletes.length} deletes)';
}
