import 'package:rift/src/relations/lazy_relation.dart';
import 'package:rift/src/relations/relation_index.dart';

/// The type of relation between two boxes.
enum RelationType {
  /// One-to-one relation: each entry in the source box maps to exactly
  /// one entry in the target box.
  oneToOne,

  /// One-to-many relation: each entry in the source box maps to multiple
  /// entries in the target box.
  oneToMany,

  /// Many-to-many relation: entries in both boxes can map to multiple
  /// entries in the other box.
  manyToMany,
}

/// Configuration for a relation between two boxes.
///
/// Defines how entries in one box relate to entries in another box.
/// Relations can be lazy-loaded (only fetched when accessed) and
/// can cascade deletes from parent to child entries.
class RelationConfig {
  /// The field name on the source box that identifies this relation.
  ///
  /// For example, if a User box has a 'posts' relation to a Posts box,
  /// the field would be 'posts'.
  final String field;

  /// The name of the target box that this relation points to.
  final String targetBox;

  /// The field on the target box that holds the foreign key.
  ///
  /// For one-to-many: the field in the target box that references
  /// the primary key of the source box.
  /// For one-to-one: same as one-to-many but with a unique constraint.
  /// For many-to-many: not used (uses a junction table pattern).
  final String targetField;

  /// The type of relation (one-to-one, one-to-many, many-to-many).
  final RelationType type;

  /// Whether to lazy-load the related data.
  ///
  /// When true (default), related data is only fetched from the target box
  /// when explicitly accessed via [RelationManager.getRelated].
  /// When false, related data is eagerly loaded with the parent entry.
  final bool lazyLoad;

  /// Whether to cascade deletes to related entries.
  ///
  /// When true, deleting a parent entry will also delete all related
  /// entries in the target box. When false (default), only the parent
  /// entry is deleted and related entries become orphans.
  final bool cascadeDelete;

  /// Optional backlink field name.
  ///
  /// If provided, creates a reverse relation from the target box
  /// back to the source box. For example, if User has many Posts,
  /// the backlink 'author' on Posts would point back to the User.
  final String? backlinkField;

  const RelationConfig({
    required this.field,
    required this.targetBox,
    required this.targetField,
    this.type = RelationType.oneToMany,
    this.lazyLoad = true,
    this.cascadeDelete = false,
    this.backlinkField,
  });

  @override
  String toString() =>
      'RelationConfig(field: $field, targetBox: $targetBox, '
      'targetField: $targetField, type: $type, '
      'lazyLoad: $lazyLoad, cascadeDelete: $cascadeDelete)';
}

/// Manages relations between Rift boxes.
///
/// The [RelationManager] allows you to define and query relations between
/// different boxes. It supports one-to-one, one-to-many, and many-to-many
/// relations with optional lazy loading and cascade delete.
///
/// Usage:
/// ```dart
/// // One-to-many: User has many Posts
/// box.createRelation(
///   RelationConfig(
///     field: 'posts',
///     targetBox: 'posts',
///     targetField: 'authorId',
///     type: RelationType.oneToMany,
///     lazyLoad: true,
///   ),
/// );
///
/// // Access related data
/// final posts = await box.getRelated('user1', 'posts');
///
/// // Backlink: Post belongs to User
/// final author = await box.getRelated('post1', 'author');
/// ```
class RelationManager {
  /// Internal index for tracking relations efficiently.
  final RelationIndex _relationIndex = RelationIndex();

  /// Gets the internal relation index (for cleanup operations).
  RelationIndex get relationIndex => _relationIndex;

  /// Cache of lazy relation proxies per (boxName, field).
  final Map<String, Map<String, LazyRelation>> _lazyRelationCache = {};

  /// Creates a new relation on the given box.
  ///
  /// [boxName] is the source box where the relation is defined.
  /// [config] describes the relation to create.
  void createRelation(String boxName, RelationConfig config) {
    _relationIndex.register(boxName, config);

    if (config.lazyLoad) {
      _lazyRelationCache.putIfAbsent(boxName, () => {});
      _lazyRelationCache[boxName]![config.field] = LazyRelation(
        boxName: boxName,
        config: config,
        relationIndex: _relationIndex,
      );
    }
  }

  /// Removes a relation from the given box.
  ///
  /// [boxName] is the source box.
  /// [field] is the relation field to remove.
  void removeRelation(String boxName, String field) {
    _relationIndex.unregister(boxName, field);
    _lazyRelationCache[boxName]?.remove(field);
  }

  /// Gets related data for a specific key and relation field.
  ///
  /// [boxName] is the source box name.
  /// [key] is the primary key of the source entry.
  /// [field] is the relation field name (as defined in [RelationConfig.field]).
  ///
  /// Returns a list of related entries (even for one-to-one relations,
  /// for consistency). Returns an empty list if no relations are found.
  Future<List<dynamic>> getRelated(
    String boxName,
    dynamic key,
    String field,
  ) async {
    final config = _relationIndex.getConfig(boxName, field);
    if (config == null) {
      throw ArgumentError(
        'No relation "$field" defined on box "$boxName". '
        'Call createRelation() first.',
      );
    }

    if (config.lazyLoad && _lazyRelationCache[boxName]?[field] != null) {
      return await _lazyRelationCache[boxName]![field]!.load(key);
    }

    // Non-lazy: use the index directly
    return _relationIndex.lookupRelated(boxName, key, field);
  }

  /// Sets related data for a many-to-many relation.
  ///
  /// For many-to-many relations, this adds the link between the source
  /// and target entries in the junction index.
  Future<void> setRelated(
    String boxName,
    dynamic sourceKey,
    String field,
    List<dynamic> targetKeys,
  ) async {
    final config = _relationIndex.getConfig(boxName, field);
    if (config == null) {
      throw ArgumentError(
        'No relation "$field" defined on box "$boxName". '
        'Call createRelation() first.',
      );
    }

    if (config.type != RelationType.manyToMany) {
      throw ArgumentError(
        'setRelated() is only supported for many-to-many relations. '
        'For ${config.type}, write the foreign key directly to the target box.',
      );
    }

    for (final targetKey in targetKeys) {
      _relationIndex.addJunctionEntry(boxName, field, sourceKey, targetKey);
    }
  }

  /// Removes related data for a many-to-many relation.
  Future<void> removeRelated(
    String boxName,
    dynamic sourceKey,
    String field,
    List<dynamic> targetKeys,
  ) async {
    final config = _relationIndex.getConfig(boxName, field);
    if (config == null) {
      throw ArgumentError('No relation "$field" defined on box "$boxName".');
    }

    if (config.type != RelationType.manyToMany) {
      throw ArgumentError(
        'removeRelated() is only supported for many-to-many relations.',
      );
    }

    for (final targetKey in targetKeys) {
      _relationIndex.removeJunctionEntry(boxName, field, sourceKey, targetKey);
    }
  }

  /// Handles cascade delete for all relations on a box.
  ///
  /// When a key is deleted from [boxName], this method checks all
  /// relations with [RelationConfig.cascadeDelete] set to true and
  /// returns the list of keys that should also be deleted from
  /// their respective target boxes.
  ///
  /// Returns a map of targetBoxName → list of keys to delete.
  Map<String, List<dynamic>> cascadeDelete(String boxName, dynamic deletedKey) {
    final result = <String, List<dynamic>>{};
    final configs = _relationIndex.getConfigsForBox(boxName);

    for (final config in configs) {
      if (!config.cascadeDelete) continue;

      final relatedKeys = _relationIndex.lookupRelated(
        boxName,
        deletedKey,
        config.field,
      );

      if (relatedKeys.isNotEmpty) {
        result.putIfAbsent(config.targetBox, () => []);
        result[config.targetBox]!.addAll(relatedKeys);
      }
    }

    return result;
  }

  /// Updates the relation index when a value is written to a box.
  ///
  /// This should be called after a put/add operation to keep the
  /// relation index in sync.
  void onPut(String boxName, dynamic key, dynamic value) {
    _relationIndex.updateOnPut(boxName, key, value);
  }

  /// Updates the relation index when a value is deleted from a box.
  ///
  /// This should be called after a delete operation to keep the
  /// relation index in sync.
  void onDelete(String boxName, dynamic key, dynamic oldValue) {
    _relationIndex.updateOnDelete(boxName, key, oldValue);
  }

  /// Gets all relation configs for a given box.
  List<RelationConfig> getRelations(String boxName) {
    return _relationIndex.getConfigsForBox(boxName);
  }

  /// Checks if a relation exists for the given box and field.
  bool hasRelation(String boxName, String field) {
    return _relationIndex.getConfig(boxName, field) != null;
  }

  /// Gets the lazy relation proxy for a given box and field.
  ///
  /// Returns null if the relation doesn't exist or is not lazy-loaded.
  LazyRelation? getLazyRelation(String boxName, String field) {
    return _lazyRelationCache[boxName]?[field];
  }

  /// Clears all relation index data for a specific box.
  ///
  /// Called when a box is closed to free memory.
  void clearRelationIndexForBox(String boxName) {
    _relationIndex.clearForBox(boxName);
    _lazyRelationCache.remove(boxName);
  }
}
