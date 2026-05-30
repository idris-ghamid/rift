import 'package:rift/src/index/secondary_index.dart';
import 'package:rift/src/index/composite_index.dart';
import 'package:meta/meta.dart';

/// Callback type for extracting a field value from a stored object.
///
/// Given a [value] stored in a box and a [field] name, returns the
/// corresponding field value. Returns `null` if the field doesn't exist.
typedef FieldValueExtractor = dynamic Function(dynamic value, String field);

/// Default field value extractor.
///
/// Supports:
/// - Map values: extracts by key
/// - Objects with `toJson()`: extracts from the JSON representation
/// - Objects with matching getter: attempts dynamic access
///
/// For custom objects that don't fit these patterns, register a custom
/// [FieldValueExtractor] via [IndexManager.registerFieldExtractor].
dynamic defaultFieldValueExtractor(dynamic value, String field) {
  if (value == null) return null;

  // Map: direct key access
  if (value is Map) {
    return value[field];
  }

  // Try toJson() pattern
  try {
    if (value.toJson != null) {
      final json = value.toJson() as Map;
      return json[field];
    }
  } catch (_) {
    // Ignore - toJson might not exist or might throw
  }

  // Try getter access via noSuchMethod forwarding
  // This won't work for most Dart classes without mirrors,
  // but we can try common patterns

  return null;
}

/// Manages secondary indexes for Rift boxes.
///
/// The [IndexManager] is a singleton-like registry that holds all indexes
/// for all open boxes. It provides methods to create, drop, and query
/// indexes, as well as update them when data changes.
///
/// Usage:
/// ```dart
/// final indexManager = IndexManager();
///
/// // Create an index
/// await indexManager.createIndex('users', 'age');
///
/// // Query using the index
/// final keys = await indexManager.queryIndex('users', 'age', 25);
///
/// // The index is automatically updated when you call
/// // updateIndex/removeFromIndex after box writes
/// ```
class IndexManager {
  /// Indexes per box per field: boxName → field → SecondaryIndex
  final Map<String, Map<String, SecondaryIndex>> _indexes = {};

  /// Composite indexes per box: boxName → List<CompositeIndex>
  final Map<String, List<CompositeIndex>> _compositeIndexes = {};

  /// Custom field value extractors per box.
  final Map<String, FieldValueExtractor> _fieldExtractors = {};

  /// Create a secondary index on a field of a box.
  ///
  /// If an index already exists for the given [boxName] and [field],
  /// this is a no-op.
  ///
  /// [type] determines the index data structure:
  /// - [IndexType.btree]: Sorted index supporting range queries (default)
  /// - [IndexType.hash]: Hash index for O(1) equality lookups only
  Future<void> createIndex(
    String boxName,
    String field, {
    IndexType type = IndexType.btree,
  }) async {
    _indexes.putIfAbsent(boxName, () => {});
    if (_indexes[boxName]!.containsKey(field)) {
      return; // Already indexed
    }
    _indexes[boxName]![field] = SecondaryIndex(field: field, type: type);
  }

  /// Create a composite index on multiple fields.
  ///
  /// [fields] must have at least 2 elements.
  Future<void> createCompositeIndex(String boxName, List<String> fields) async {
    if (fields.length < 2) {
      throw ArgumentError(
        'Composite indexes require at least 2 fields. '
        'Use createIndex() for single-field indexes.',
      );
    }

    _compositeIndexes.putIfAbsent(boxName, () => []);
    _compositeIndexes[boxName]!.add(CompositeIndex(fields: fields));
  }

  /// Drop (remove) an index.
  ///
  /// Does nothing if the index doesn't exist.
  Future<void> dropIndex(String boxName, String field) async {
    _indexes[boxName]?.remove(field);
  }

  /// Drop all indexes for a box.
  Future<void> dropAllIndexes(String boxName) async {
    _indexes.remove(boxName);
    _compositeIndexes.remove(boxName);
  }

  /// Query a secondary index.
  ///
  /// Returns the primary keys of entries matching the query.
  /// The [op] determines the comparison operator (default: equality).
  ///
  /// Throws if no index exists for [boxName] and [field].
  Future<List<dynamic>> queryIndex(
    String boxName,
    String field,
    dynamic value, {
    IndexOperator op = IndexOperator.eq,
  }) async {
    final fieldIndexes = _indexes[boxName];
    if (fieldIndexes == null) {
      return [];
    }

    final index = fieldIndexes[field];
    if (index == null) {
      return [];
    }

    return index.query(value, op: op);
  }

  /// Update the index after a write (put/add).
  ///
  /// [key] is the primary key of the entry.
  /// [value] is the newly written value.
  ///
  /// This extracts field values from [value] using the registered
  /// field extractor (or [defaultFieldValueExtractor]) and updates
  /// all relevant indexes.
  Future<void> updateIndex(String boxName, dynamic key, dynamic value) async {
    final fieldIndexes = _indexes[boxName];
    if (fieldIndexes == null || fieldIndexes.isEmpty) return;

    final extractor = _fieldExtractors[boxName] ?? defaultFieldValueExtractor;

    for (final index in fieldIndexes.values) {
      final fieldValue = extractor(value, index.field);
      index.insert(fieldValue, key);
    }

    // Update composite indexes
    final composites = _compositeIndexes[boxName];
    if (composites != null) {
      for (final composite in composites) {
        final fieldValues = <String, dynamic>{};
        for (final field in composite.fields) {
          fieldValues[field] = extractor(value, field);
        }
        composite.insert(fieldValues, key);
      }
    }
  }

  /// Remove from the index after a delete.
  ///
  /// [key] is the primary key of the deleted entry.
  /// [value] is the value that was deleted (needed to find index entries).
  Future<void> removeFromIndex(
    String boxName,
    dynamic key,
    dynamic value,
  ) async {
    final fieldIndexes = _indexes[boxName];
    if (fieldIndexes == null || fieldIndexes.isEmpty) return;

    if (value != null) {
      final extractor = _fieldExtractors[boxName] ?? defaultFieldValueExtractor;

      for (final index in fieldIndexes.values) {
        final fieldValue = extractor(value, index.field);
        index.remove(fieldValue, key);
      }

      // Update composite indexes
      final composites = _compositeIndexes[boxName];
      if (composites != null) {
        for (final composite in composites) {
          final fieldValues = <String, dynamic>{};
          for (final field in composite.fields) {
            fieldValues[field] = extractor(value, field);
          }
          composite.remove(fieldValues, key);
        }
      }
    } else {
      // When the old value is unknown (e.g., lazy box), scan all indexes
      await removeFromIndexByPrimaryKey(boxName, key);
    }
  }

  /// Remove a primary key from all indexes without knowing its field value.
  ///
  /// This scans all index entries to find and remove the primary key.
  /// Slower than [removeFromIndex] but necessary when the old value
  /// is unknown (e.g., for lazy boxes).
  Future<void> removeFromIndexByPrimaryKey(String boxName, dynamic key) async {
    final fieldIndexes = _indexes[boxName];
    if (fieldIndexes == null) return;

    for (final index in fieldIndexes.values) {
      index.removeByPrimaryKey(key);
    }

    // Note: composite indexes are harder to clean up without field values.
    // For lazy boxes with composite indexes, consider rebuilding indexes
    // after heavy modifications.
  }

  /// Register a custom field value extractor for a box.
  ///
  /// The [extractor] is called to retrieve field values from stored objects.
  /// This is necessary for custom objects that don't implement Map or toJson().
  void registerFieldExtractor(String boxName, FieldValueExtractor extractor) {
    _fieldExtractors[boxName] = extractor;
  }

  /// Get the field value extractor for a box.
  ///
  /// Returns the custom extractor if one was registered via
  /// [registerFieldExtractor], otherwise returns [defaultFieldValueExtractor].
  FieldValueExtractor getFieldExtractor(String boxName) {
    return _fieldExtractors[boxName] ?? defaultFieldValueExtractor;
  }

  /// Get the secondary index for a box and field, or null if not indexed.
  @visibleForTesting
  SecondaryIndex? getIndex(String boxName, String field) {
    return _indexes[boxName]?[field];
  }

  /// Get all composite indexes for a box.
  @visibleForTesting
  List<CompositeIndex> getCompositeIndexes(String boxName) {
    return _compositeIndexes[boxName] ?? [];
  }

  /// Check if an index exists for a box and field.
  bool hasIndex(String boxName, String field) {
    return _indexes[boxName]?.containsKey(field) ?? false;
  }

  /// Rebuild all indexes for a box from scratch.
  ///
  /// This is useful after bulk loading data or if indexes get out of sync.
  /// [entries] is an iterable of (key, value) pairs.
  Future<void> rebuildIndexes(
    String boxName,
    Iterable<MapEntry<dynamic, dynamic>> entries,
  ) async {
    // Clear existing indexes
    final fieldIndexes = _indexes[boxName];
    if (fieldIndexes != null) {
      for (final index in fieldIndexes.values) {
        index.clear();
      }
    }

    final composites = _compositeIndexes[boxName];
    if (composites != null) {
      for (final composite in composites) {
        composite.clear();
      }
    }

    // Re-populate
    for (final entry in entries) {
      await updateIndex(boxName, entry.key, entry.value);
    }
  }

  /// Clear all indexes (e.g., when a box is closed).
  void clearAll() {
    _indexes.clear();
    _compositeIndexes.clear();
    _fieldExtractors.clear();
  }
}
