import 'package:rift/src/relations/relation.dart';

/// Internal index for tracking relations efficiently.
///
/// The [RelationIndex] maintains an in-memory index of all defined relations
/// and their current state. It supports fast lookups of related entries
/// by maintaining reverse-lookup data structures.
///
/// For one-to-one and one-to-many relations, the index tracks the foreign
/// key values stored in target box entries. When a target entry is written,
/// the index is updated to reflect the new foreign key value.
///
/// For many-to-many relations, the index maintains a junction table
/// (sourceKey → Set<targetKey>) that stores the explicit links between
/// entries in the two boxes.
class RelationIndex {
  /// Relation configs per box: boxName → field → RelationConfig
  final Map<String, Map<String, RelationConfig>> _configs = {};

  /// Reverse index for one-to-one and one-to-many:
  /// (boxName, field) → (foreignKeyValue → Set<targetPrimaryKey>)
  final Map<String, Map<String, Map<dynamic, Set<dynamic>>>> _foreignKeyIndex =
      {};

  /// Junction index for many-to-many:
  /// (boxName, field) → (sourceKey → Set<targetKey>)
  final Map<String, Map<String, Map<dynamic, Set<dynamic>>>> _junctionIndex =
      {};

  /// Registers a new relation config.
  void register(String boxName, RelationConfig config) {
    _configs.putIfAbsent(boxName, () => {});
    _configs[boxName]![config.field] = config;

    // Initialize index structures based on relation type
    if (config.type == RelationType.manyToMany) {
      _junctionIndex.putIfAbsent(boxName, () => {});
      _junctionIndex[boxName]!.putIfAbsent(config.field, () => {});
    } else {
      _foreignKeyIndex.putIfAbsent(boxName, () => {});
      _foreignKeyIndex[boxName]!.putIfAbsent(config.field, () => {});
    }

    // Register backlink if specified
    if (config.backlinkField != null) {
      final backlinkConfig = RelationConfig(
        field: config.backlinkField!,
        targetBox: boxName,
        targetField: config.targetField,
        type: config.type == RelationType.oneToMany
            ? RelationType.oneToOne
            : config.type,
        lazyLoad: config.lazyLoad,
        cascadeDelete: false, // Backlinks never cascade
      );

      _configs.putIfAbsent(config.targetBox, () => {});
      _configs[config.targetBox]![config.backlinkField!] = backlinkConfig;

      // Initialize index for backlink
      _foreignKeyIndex.putIfAbsent(config.targetBox, () => {});
      _foreignKeyIndex[config.targetBox]!.putIfAbsent(
        config.backlinkField!,
        () => {},
      );
    }
  }

  /// Unregisters a relation config.
  void unregister(String boxName, String field) {
    final config = _configs[boxName]?.remove(field);

    // Also remove backlink if it exists
    if (config?.backlinkField != null) {
      _configs[config!.targetBox]?.remove(config.backlinkField);
      _foreignKeyIndex[config.targetBox]?.remove(config.backlinkField);
    }

    // Clean up index data
    if (config?.type == RelationType.manyToMany) {
      _junctionIndex[boxName]?.remove(field);
    } else {
      _foreignKeyIndex[boxName]?.remove(field);
    }
  }

  /// Gets the relation config for a given box and field.
  RelationConfig? getConfig(String boxName, String field) {
    return _configs[boxName]?[field];
  }

  /// Gets all relation configs for a given box.
  List<RelationConfig> getConfigsForBox(String boxName) {
    return _configs[boxName]?.values.toList() ?? [];
  }

  /// Looks up related keys for a source key and relation field.
  ///
  /// For one-to-one and one-to-many: looks up by foreign key value
  /// (which equals the source key).
  /// For many-to-many: looks up in the junction index.
  List<dynamic> lookupRelated(String boxName, dynamic sourceKey, String field) {
    final config = getConfig(boxName, field);
    if (config == null) return [];

    if (config.type == RelationType.manyToMany) {
      final junctionMap = _junctionIndex[boxName]?[field];
      if (junctionMap == null) return [];
      return junctionMap[sourceKey]?.toList() ?? [];
    }

    // For one-to-one and one-to-many, the sourceKey IS the foreign key value
    // in the target box. We look up which target entries have this FK value.
    final fkMap = _foreignKeyIndex[boxName]?[field];
    if (fkMap == null) return [];
    return fkMap[sourceKey]?.toList() ?? [];
  }

  /// Adds a junction entry for a many-to-many relation.
  void addJunctionEntry(
    String boxName,
    String field,
    dynamic sourceKey,
    dynamic targetKey,
  ) {
    _junctionIndex[boxName]?[field]?.putIfAbsent(sourceKey, () => {});
    _junctionIndex[boxName]?[field]?[sourceKey]?.add(targetKey);
  }

  /// Removes a junction entry from a many-to-many relation.
  void removeJunctionEntry(
    String boxName,
    String field,
    dynamic sourceKey,
    dynamic targetKey,
  ) {
    _junctionIndex[boxName]?[field]?[sourceKey]?.remove(targetKey);
    // Clean up empty sets
    if (_junctionIndex[boxName]?[field]?[sourceKey]?.isEmpty ?? false) {
      _junctionIndex[boxName]?[field]?.remove(sourceKey);
    }
  }

  /// Updates the index when a value is put into a box.
  ///
  /// This method checks if the value contains any foreign key fields
  /// that participate in relations and updates the index accordingly.
  void updateOnPut(String boxName, dynamic key, dynamic value) {
    // Check if this box is a target of any relation
    for (final sourceBoxName in _configs.keys) {
      for (final config in _configs[sourceBoxName]!.values) {
        if (config.targetBox != boxName) continue;
        if (config.type == RelationType.manyToMany) continue;

        // Extract the foreign key value from the written entry
        final foreignKeyValue = _extractFieldValue(value, config.targetField);
        if (foreignKeyValue == null) continue;

        // Remove old index entries for this key
        _removeFromForeignKeyIndex(sourceBoxName, config.field, key);

        // Add new index entry: foreignKeyValue → targetPrimaryKey
        _foreignKeyIndex[sourceBoxName]?.putIfAbsent(config.field, () => {});
        _foreignKeyIndex[sourceBoxName]?[config.field]?.putIfAbsent(
          foreignKeyValue,
          () => {},
        );
        _foreignKeyIndex[sourceBoxName]?[config.field]?[foreignKeyValue]?.add(
          key,
        );
      }
    }
  }

  /// Updates the index when a value is deleted from a box.
  ///
  /// This method removes all index entries that reference the deleted key.
  void updateOnDelete(String boxName, dynamic key, dynamic oldValue) {
    // Remove from foreign key index
    for (final sourceBoxName in _configs.keys) {
      for (final config in _configs[sourceBoxName]!.values) {
        if (config.targetBox != boxName) continue;
        if (config.type == RelationType.manyToMany) continue;

        // Remove the old foreign key entry
        if (oldValue != null) {
          final foreignKeyValue = _extractFieldValue(
            oldValue,
            config.targetField,
          );
          if (foreignKeyValue != null) {
            _foreignKeyIndex[sourceBoxName]?[config.field]?[foreignKeyValue]
                ?.remove(key);
            // Clean up empty sets
            if (_foreignKeyIndex[sourceBoxName]?[config.field]?[foreignKeyValue]
                    ?.isEmpty ??
                false) {
              _foreignKeyIndex[sourceBoxName]?[config.field]?.remove(
                foreignKeyValue,
              );
            }
          }
        }
      }
    }

    // Remove from junction index (source side)
    _junctionIndex[boxName]?.forEach((field, junctionMap) {
      junctionMap.remove(key);
    });

    // Remove from junction index (target side — scan all source entries)
    for (final sourceBoxName in _configs.keys) {
      for (final config in _configs[sourceBoxName]!.values) {
        if (config.targetBox != boxName) continue;
        if (config.type != RelationType.manyToMany) continue;

        _junctionIndex[sourceBoxName]?[config.field]?.forEach((
          sourceKey,
          targetKeys,
        ) {
          targetKeys.remove(key);
        });
      }
    }
  }

  /// Removes a target key from the foreign key index by scanning all entries.
  void _removeFromForeignKeyIndex(
    String sourceBoxName,
    String field,
    dynamic targetKey,
  ) {
    final fkMap = _foreignKeyIndex[sourceBoxName]?[field];
    if (fkMap == null) return;

    for (final keySet in fkMap.values) {
      keySet.remove(targetKey);
    }

    // Clean up empty sets
    fkMap.removeWhere((_, keySet) => keySet.isEmpty);
  }

  /// Extracts a field value from a stored object.
  ///
  /// Supports Map values and objects with a toJson() method.
  dynamic _extractFieldValue(dynamic value, String field) {
    if (value == null) return null;

    if (value is Map) {
      return value[field];
    }

    // Try toJson() pattern
    try {
      final json = value.toJson() as Map;
      return json[field];
    } catch (_) {
      return null;
    }
  }

  /// Clears all index data.
  void clear() {
    _configs.clear();
    _foreignKeyIndex.clear();
    _junctionIndex.clear();
  }

  /// Clears index data for a specific box.
  void clearForBox(String boxName) {
    _configs.remove(boxName);
    _foreignKeyIndex.remove(boxName);
    _junctionIndex.remove(boxName);
  }
}
