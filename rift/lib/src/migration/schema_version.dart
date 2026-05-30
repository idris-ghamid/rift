import 'package:rift/src/box/box_base_impl.dart';

/// The special key used to store the schema version in each box.
const String schemaVersionKey = '__rift_schema_version__';

/// Tracks schema version per box.
///
/// The schema version is stored as a special key [schemaVersionKey]
/// inside each box. This allows the migration framework to determine
/// the current version of a box's data and apply the necessary
/// migration steps.
///
/// The version is stored as an integer value under the special key.
/// If no version has been set, the box is assumed to be at version 0
/// (unversioned / initial state).
///
/// Usage:
/// ```dart
/// // Get the current schema version
/// final version = await SchemaVersionTracker.getVersion(box);
///
/// // Set the schema version (typically done by the Migrator)
/// await SchemaVersionTracker.setVersion(box, 3);
///
/// // Initialize version for a new box
/// await SchemaVersionTracker.initializeVersion(box, 1);
/// ```
class SchemaVersionTracker {
  /// Gets the current schema version of the given box.
  ///
  /// Returns 0 if no version has been set (unversioned box).
  Future<int> getVersion(BoxBaseImpl box) async {
    final frame = box.keystore.get(schemaVersionKey);
    if (frame == null) return 0;

    final value = frame.value;
    if (value is int) return value;

    // Handle cases where the value might be stored as a different type
    try {
      return int.parse(value.toString());
    } catch (_) {
      return 0;
    }
  }

  /// Sets the schema version of the given box.
  ///
  /// This stores the version as a special entry in the box's keystore.
  /// The version key is prefixed with `__rift_` to avoid conflicts
  /// with user data.
  Future<void> setVersion(BoxBaseImpl box, int version) async {
    await box.put(schemaVersionKey as dynamic, version as dynamic);
  }

  /// Initializes the schema version for a new box.
  ///
  /// This sets the version only if it hasn't been set before.
  /// Returns the version that was set (either the provided one
  /// or the existing one).
  Future<int> initializeVersion(BoxBaseImpl box, int version) async {
    final currentVersion = await getVersion(box);
    if (currentVersion != 0) return currentVersion;

    await setVersion(box, version);
    return version;
  }

  /// Checks if the box has been versioned (has a schema version set).
  Future<bool> isVersioned(BoxBaseImpl box) async {
    final frame = box.keystore.get(schemaVersionKey);
    return frame != null;
  }

  /// Resets the schema version of the box to 0.
  ///
  /// This removes the version entry from the box. Use with caution,
  /// as this will cause the next migration to start from version 0.
  Future<void> resetVersion(BoxBaseImpl box) async {
    if (box.keystore.containsKey(schemaVersionKey)) {
      await box.delete(schemaVersionKey as dynamic);
    }
  }
}
