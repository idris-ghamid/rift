import 'dart:collection';

import 'package:meta/meta.dart';

/// A composite index spanning multiple fields.
///
/// Composite indexes allow efficient queries that filter on multiple fields
/// simultaneously. The index key is formed by concatenating the field values
/// in the order they are defined.
///
/// Example:
/// ```dart
/// // Index on (city, age) allows efficient queries like:
/// // WHERE city = 'Cairo' AND age > 18
/// final index = CompositeIndex(fields: ['city', 'age']);
/// ```
@immutable
class CompositeIndex {
  /// The fields this composite index covers, in order.
  final List<String> fields;

  /// Internal map from composite key → set of primary keys.
  final Map<String, Set<dynamic>> _index = HashMap<String, Set<dynamic>>();

  /// Create a composite index on the given [fields].
  CompositeIndex({required this.fields});

  /// Build a composite key from a map of field → value.
  ///
  /// Values are separated by a null-character separator to avoid collisions.
  /// Null values are represented as a special sentinel.
  String _buildKey(Map<String, dynamic> fieldValues) {
    final parts = <String>[];
    for (final field in fields) {
      final value = fieldValues[field];
      if (value == null) {
        parts.add('\x00NULL');
      } else {
        parts.add(value.toString());
      }
    }
    return parts.join('\x00SEP');
  }

  /// Insert a primary key into this index.
  ///
  /// [fieldValues] must contain values for all [fields].
  void insert(Map<String, dynamic> fieldValues, dynamic primaryKey) {
    final key = _buildKey(fieldValues);
    _index.putIfAbsent(key, () => <dynamic>{});
    _index[key]!.add(primaryKey);
  }

  /// Remove a primary key from this index.
  ///
  /// [fieldValues] must contain values for all [fields].
  bool remove(Map<String, dynamic> fieldValues, dynamic primaryKey) {
    final key = _buildKey(fieldValues);
    final set = _index[key];
    if (set != null) {
      final removed = set.remove(primaryKey);
      if (set.isEmpty) {
        _index.remove(key);
      }
      return removed;
    }
    return false;
  }

  /// Query this composite index for exact matches on all fields.
  ///
  /// [fieldValues] must contain values for all [fields].
  List<dynamic> queryExact(Map<String, dynamic> fieldValues) {
    final key = _buildKey(fieldValues);
    return _index[key]?.toList() ?? [];
  }

  /// Query this composite index with partial field matching.
  ///
  /// Only the first [prefixLength] fields are used for matching.
  /// This allows queries like: WHERE city = 'Cairo'
  /// on a (city, age) composite index.
  ///
  /// [fieldValues] must contain at least [prefixLength] values.
  List<dynamic> queryPrefix(
    Map<String, dynamic> fieldValues, {
    int? prefixLength,
  }) {
    final effectiveLength = prefixLength ?? fieldValues.length;
    final result = <dynamic>[];

    // Build a prefix key from the first `effectiveLength` fields
    final prefixParts = <String>[];
    for (var i = 0; i < effectiveLength && i < fields.length; i++) {
      final field = fields[i];
      final value = fieldValues[field];
      if (value == null) {
        prefixParts.add('\x00NULL');
      } else {
        prefixParts.add(value.toString());
      }
    }
    final prefix = prefixParts.join('\x00SEP');

    for (final entry in _index.entries) {
      if (entry.key.startsWith(prefix)) {
        // Ensure we're not matching partial last component
        final fullKey = entry.key;
        if (fullKey.length == prefix.length ||
            fullKey.startsWith('$prefix\x00SEP')) {
          result.addAll(entry.value);
        }
      }
    }

    return result;
  }

  /// Get all primary keys in this index.
  List<dynamic> allKeys() {
    final result = <dynamic>[];
    for (final set in _index.values) {
      result.addAll(set);
    }
    return result;
  }

  /// Clear all entries from this index.
  void clear() {
    _index.clear();
  }

  /// The number of distinct composite keys in this index.
  int get size => _index.length;

  @override
  String toString() => 'CompositeIndex(fields: $fields, size: $size)';
}
