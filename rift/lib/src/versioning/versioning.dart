/// Data versioning for individual entry history tracking.
///
/// Tracks versions of individual entries with full change history.
/// Supports rollback to any previous version and configurable retention.
///
/// Usage:
/// ```dart
/// final versionManager = VersionManager(retention: 10);
///
/// // Track versions
/// versionManager.recordVersion('users', 'u1', {'name': 'Idris'});
/// versionManager.recordVersion('users', 'u1', {'name': 'Ahmed'});
///
/// // View history
/// final history = versionManager.getHistory('users', 'u1');
/// for (final v in history) {
///   print('v${v.version}: ${v.value} at ${v.timestamp}');
/// }
///
/// // Rollback
/// await versionManager.rollback('users', 'u1', 1);
/// ```
library;

/// Represents a single version of an entry.
class EntryVersion {
  /// The version number (monotonically increasing per entry).
  final int version;

  /// The value at this version.
  final dynamic value;

  /// When this version was created.
  final DateTime timestamp;

  /// Optional description of what changed.
  final String? description;

  /// Creates an [EntryVersion].
  const EntryVersion({
    required this.version,
    required this.value,
    required this.timestamp,
    this.description,
  });

  @override
  String toString() =>
      'EntryVersion(v$version at $timestamp${description != null ? ': $description' : ''})';
}

/// Represents the diff between two entry versions.
class VersionDiff {
  /// The source version.
  final int fromVersion;

  /// The target version.
  final int toVersion;

  /// Fields that were added (not present in from, present in to).
  final Map<String, dynamic> addedFields;

  /// Fields that were removed (present in from, not present in to).
  final Map<String, dynamic> removedFields;

  /// Fields that were modified (present in both, different values).
  final Map<String, dynamic> modifiedFieldsOld;

  /// Fields that were modified (present in both, different values).
  final Map<String, dynamic> modifiedFieldsNew;

  /// Creates a [VersionDiff].
  const VersionDiff({
    required this.fromVersion,
    required this.toVersion,
    this.addedFields = const {},
    this.removedFields = const {},
    this.modifiedFieldsOld = const {},
    this.modifiedFieldsNew = const {},
  });

  /// Whether there are any differences between the versions.
  bool get hasChanges =>
      addedFields.isNotEmpty ||
      removedFields.isNotEmpty ||
      modifiedFieldsOld.isNotEmpty;

  @override
  String toString() =>
      'VersionDiff(v$fromVersion → v$toVersion: +${addedFields.length} '
      '-${removedFields.length} ~${modifiedFieldsOld.length})';
}

/// Manages entry versions per box.
///
/// [VersionManager] maintains a complete version history for individual
/// entries. It supports configurable retention (how many versions to keep),
/// rollback to any previous version, and computing diffs between versions.
class VersionManager {
  /// Version history: boxName → key → list of versions.
  final Map<String, Map<dynamic, List<EntryVersion>>> _history = {};

  /// Version counters: boxName → key → current version.
  final Map<String, Map<dynamic, int>> _versionCounters = {};

  /// Maximum number of versions to retain per entry.
  final int retention;

  /// Callback invoked when a rollback occurs.
  final Future<void> Function(String boxName, dynamic key, dynamic value)?
  onRollback;

  /// Creates a [VersionManager] with optional [retention] limit.
  ///
  /// [retention] specifies how many versions to keep per entry.
  /// Set to 0 for unlimited retention.
  VersionManager({this.retention = 0, this.onRollback});

  /// Records a new version of an entry.
  ///
  /// [boxName] is the name of the box containing the entry.
  /// [key] is the entry key.
  /// [value] is the current value of the entry.
  /// [description] is an optional description of the change.
  ///
  /// Returns the version number assigned to this version.
  int recordVersion(
    String boxName,
    dynamic key,
    dynamic value, {
    String? description,
  }) {
    _history.putIfAbsent(boxName, () => {});
    _history[boxName]!.putIfAbsent(key, () => []);

    _versionCounters.putIfAbsent(boxName, () => {});
    _versionCounters[boxName]!.putIfAbsent(key, () => 0);
    _versionCounters[boxName]![key] = _versionCounters[boxName]![key]! + 1;

    final version = _versionCounters[boxName]![key]!;
    final entry = EntryVersion(
      version: version,
      value: _deepCopy(value),
      timestamp: DateTime.now(),
      description: description,
    );

    _history[boxName]![key]!.add(entry);

    // Apply retention limit
    if (retention > 0 && _history[boxName]![key]!.length > retention) {
      _history[boxName]![key]!.removeAt(0);
    }

    return version;
  }

  /// Gets the version history for an entry.
  ///
  /// Returns a list of [EntryVersion] objects, ordered from
  /// oldest to newest.
  List<EntryVersion> getHistory(String boxName, dynamic key) {
    return List.unmodifiable(_history[boxName]?[key] ?? []);
  }

  /// Gets a specific version of an entry.
  EntryVersion? getVersion(String boxName, dynamic key, int version) {
    final history = _history[boxName]?[key];
    if (history == null) return null;
    for (final v in history) {
      if (v.version == version) return v;
    }
    return null;
  }

  /// Gets the current version number for an entry.
  int? getCurrentVersion(String boxName, dynamic key) {
    return _versionCounters[boxName]?[key];
  }

  /// Gets the latest value for an entry.
  dynamic getLatestValue(String boxName, dynamic key) {
    final history = _history[boxName]?[key];
    if (history == null || history.isEmpty) return null;
    return history.last.value;
  }

  /// Computes the diff between two versions of an entry.
  VersionDiff? diff(
    String boxName,
    dynamic key,
    int fromVersion,
    int toVersion,
  ) {
    final from = getVersion(boxName, key, fromVersion);
    final to = getVersion(boxName, key, toVersion);
    if (from == null || to == null) return null;

    return computeDiff(from.value, to.value, fromVersion, toVersion);
  }

  /// Computes the diff between two values.
  static VersionDiff computeDiff(
    dynamic fromValue,
    dynamic toValue,
    int fromVersion,
    int toVersion,
  ) {
    if (fromValue is! Map || toValue is! Map) {
      return VersionDiff(
        fromVersion: fromVersion,
        toVersion: toVersion,
        modifiedFieldsOld: {'_value': fromValue},
        modifiedFieldsNew: {'_value': toValue},
      );
    }

    final addedFields = <String, dynamic>{};
    final removedFields = <String, dynamic>{};
    final modifiedFieldsOld = <String, dynamic>{};
    final modifiedFieldsNew = <String, dynamic>{};

    final allKeys = <String>{
      ...fromValue.keys.cast<String>(),
      ...toValue.keys.cast<String>(),
    };

    for (final key in allKeys) {
      final inFrom = fromValue.containsKey(key);
      final inTo = toValue.containsKey(key);

      if (!inFrom && inTo) {
        addedFields[key] = toValue[key];
      } else if (inFrom && !inTo) {
        removedFields[key] = fromValue[key];
      } else if (fromValue[key] != toValue[key]) {
        modifiedFieldsOld[key] = fromValue[key];
        modifiedFieldsNew[key] = toValue[key];
      }
    }

    return VersionDiff(
      fromVersion: fromVersion,
      toVersion: toVersion,
      addedFields: addedFields,
      removedFields: removedFields,
      modifiedFieldsOld: modifiedFieldsOld,
      modifiedFieldsNew: modifiedFieldsNew,
    );
  }

  /// Rolls back an entry to a specific version.
  ///
  /// Returns the value at the specified [version], or null if the
  /// version doesn't exist. The [onRollback] callback is invoked
  /// with the restored value so the caller can apply it to the box.
  Future<dynamic> rollback(String boxName, dynamic key, int version) async {
    final entry = getVersion(boxName, key, version);
    if (entry == null) return null;

    if (onRollback != null) {
      await onRollback!(boxName, key, entry.value);
    }

    // Record the rollback as a new version
    recordVersion(
      boxName,
      key,
      entry.value,
      description: 'Rollback to v$version',
    );

    return entry.value;
  }

  /// Deletes the version history for a specific entry.
  void deleteHistory(String boxName, dynamic key) {
    _history[boxName]?.remove(key);
    _versionCounters[boxName]?.remove(key);
  }

  /// Deletes all version history for a box.
  void deleteBoxHistory(String boxName) {
    _history.remove(boxName);
    _versionCounters.remove(boxName);
  }

  /// Clears all version history.
  void clearAll() {
    _history.clear();
    _versionCounters.clear();
  }

  /// The total number of versions tracked across all entries.
  int get totalVersions {
    var count = 0;
    for (final box in _history.values) {
      for (final versions in box.values) {
        count += versions.length;
      }
    }
    return count;
  }

  /// Gets all box names with version history.
  Iterable<String> get boxNames => _history.keys;

  /// Deep copies a value for version storage.
  dynamic _deepCopy(dynamic value) {
    if (value is Map) {
      return Map.fromEntries(
        value.entries.map((e) => MapEntry(e.key, _deepCopy(e.value))),
      );
    } else if (value is List) {
      return value.map(_deepCopy).toList();
    }
    return value;
  }
}
