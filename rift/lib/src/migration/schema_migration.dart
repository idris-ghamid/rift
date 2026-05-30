import 'package:rift/src/box/box_base_impl.dart';
import 'package:rift/src/migration/schema_version.dart';
import 'package:rift/src/rift_error.dart';

/// A single migration step that transforms data from one schema version
/// to the next.
///
/// Each step specifies a [fromVersion] and [toVersion] (which should
/// differ by exactly 1), along with a [migrate] function that transforms
/// a single entry's data.
///
/// Migration steps are applied in order, so a step that goes from
/// version 1 → 2 will be applied before a step that goes from 2 → 3.
///
/// Usage:
/// ```dart
/// MigrationStep(
///   fromVersion: 1,
///   toVersion: 2,
///   migrate: (data) {
///     // Add 'email' field with default value
///     data['email'] = data['email'] ?? '';
///     return data;
///   },
/// ),
/// ```
class MigrationStep {
  /// The schema version this step migrates from.
  final int fromVersion;

  /// The schema version this step migrates to.
  final int toVersion;

  /// The migration function that transforms data.
  ///
  /// Receives a [Map] representing a single entry's data and returns
  /// the transformed data. The function may modify the map in place
  /// or return a new map.
  final Map<String, dynamic> Function(Map<String, dynamic> data) migrate;

  const MigrationStep({
    required this.fromVersion,
    required this.toVersion,
    required this.migrate,
  });

  @override
  String toString() =>
      'MigrationStep(fromVersion: $fromVersion, toVersion: $toVersion)';
}

/// Schema migration framework for Rift.
///
/// The [Migrator] handles the process of migrating box data from one
/// schema version to another. It reads the current schema version from
/// the box (stored as the special key `__rift_schema_version__`), then
/// applies migration steps in order until the target version is reached.
///
/// Migration is idempotent — if the box is already at the target version,
/// no migrations are applied.
///
/// Usage:
/// ```dart
/// await rift.openBox('users', migrations: [
///   MigrationStep(
///     fromVersion: 1,
///     toVersion: 2,
///     migrate: (data) {
///       data['email'] = data['email'] ?? '';
///       return data;
///     },
///   ),
///   MigrationStep(
///     fromVersion: 2,
///     toVersion: 3,
///     migrate: (data) {
///       data['fullName'] = data.remove('name');
///       return data;
///     },
///   ),
/// ]);
/// ```
class Migrator {
  /// The ordered list of migration steps.
  final List<MigrationStep> steps;

  /// Creates a new migrator with the given steps.
  ///
  /// Steps are automatically sorted by [fromVersion] to ensure
  /// they are applied in the correct order.
  Migrator(this.steps) {
    steps.sort((a, b) => a.fromVersion.compareTo(b.fromVersion));
  }

  /// Performs migration on the given box from [currentVersion] to
  /// [targetVersion].
  ///
  /// The method iterates through the sorted migration steps, applying
  /// each step whose [fromVersion] matches the current version. After
  /// each step, the schema version in the box is updated.
  ///
  /// If [currentVersion] equals [targetVersion], no migration is performed.
  ///
  /// Throws [RiftError] if there is a gap in migration steps (i.e., no
  /// step exists to bridge from one version to the next).
  Future<void> migrate(
    BoxBaseImpl box,
    int currentVersion,
    int targetVersion,
  ) async {
    if (currentVersion == targetVersion) return;

    final direction = targetVersion > currentVersion ? 1 : -1;
    var version = currentVersion;

    while (version != targetVersion) {
      final nextVersion = version + direction;

      // Find the migration step for this transition
      MigrationStep? step;
      if (direction > 0) {
        step = steps
            .where(
              (s) => s.fromVersion == version && s.toVersion == nextVersion,
            )
            .firstOrNull;
      } else {
        // For rollback, look for a step in reverse
        step = steps
            .where(
              (s) => s.toVersion == version && s.fromVersion == nextVersion,
            )
            .firstOrNull;
      }

      if (step == null) {
        throw RiftError(
          'No migration step found from version $version to $nextVersion. '
          'Available steps: ${steps.map((s) => '${s.fromVersion}→${s.toVersion}').join(", ")}',
        );
      }

      // Apply the migration to all entries in the box
      await _applyMigration(box, step, direction > 0);

      version = nextVersion;

      // Update the schema version in the box
      await SchemaVersionTracker().setVersion(box, version);
    }
  }

  /// Applies a single migration step to all entries in the box.
  ///
  /// For forward migrations, the step's [migrate] function is called.
  /// For backward migrations (rollback), we also call the same migrate
  /// function — it is the developer's responsibility to ensure the
  /// migration function is reversible if rollbacks are needed.
  Future<void> _applyMigration(
    BoxBaseImpl box,
    MigrationStep step,
    bool isForward,
  ) async {
    // Iterate through all keys in the box
    final keys = box.keys.toList();

    for (final key in keys) {
      // Skip internal keys
      if (key is String && key.startsWith('__rift_')) continue;

      // Get the current value
      final frame = box.keystore.get(key);
      if (frame == null) continue;

      var value = frame.value;

      // Only migrate Map values (structured data)
      if (value is Map<String, dynamic>) {
        try {
          final migratedData = step.migrate(Map<String, dynamic>.from(value));

          // Write back the migrated data
          await box.put(key, migratedData as dynamic);
        } catch (e) {
          throw RiftError(
            'Migration failed for key "$key" in box "${box.name}" '
            'during step ${step.fromVersion}→${step.toVersion}: $e',
          );
        }
      } else if (value is Map) {
        // Handle Map<dynamic, dynamic> by converting
        try {
          final data = Map<String, dynamic>.from(value);
          final migratedData = step.migrate(data);

          // Write back the migrated data
          await box.put(key, migratedData as dynamic);
        } catch (e) {
          throw RiftError(
            'Migration failed for key "$key" in box "${box.name}" '
            'during step ${step.fromVersion}→${step.toVersion}: $e',
          );
        }
      }
      // Non-Map values are skipped during migration
    }
  }

  /// Checks if migration is needed for the given box.
  ///
  /// Returns true if the current schema version of the box differs
  /// from the [targetVersion].
  Future<bool> needsMigration(BoxBaseImpl box, int targetVersion) async {
    final currentVersion = await SchemaVersionTracker().getVersion(box);
    return currentVersion != targetVersion;
  }

  /// Gets the highest version that can be reached with the registered
  /// migration steps.
  int get maxReachableVersion {
    if (steps.isEmpty) return 0;
    return steps.map((s) => s.toVersion).reduce((a, b) => a > b ? a : b);
  }

  /// Gets the lowest version that can be reached with the registered
  /// migration steps.
  int get minReachableVersion {
    if (steps.isEmpty) return 0;
    return steps.map((s) => s.fromVersion).reduce((a, b) => a < b ? a : b);
  }

  /// Validates that the migration steps form a continuous chain
  /// from [startVersion] to [endVersion].
  ///
  /// Returns a list of missing version transitions. If the list is
  /// empty, the chain is complete.
  List<String> validateChain(int startVersion, int endVersion) {
    final missing = <String>[];
    var version = startVersion;
    final direction = endVersion > startVersion ? 1 : -1;

    while (version != endVersion) {
      final nextVersion = version + direction;

      bool found;
      if (direction > 0) {
        found = steps.any(
          (s) => s.fromVersion == version && s.toVersion == nextVersion,
        );
      } else {
        found = steps.any(
          (s) => s.toVersion == version && s.fromVersion == nextVersion,
        );
      }

      if (!found) {
        missing.add('$version → $nextVersion');
      }

      version = nextVersion;
    }

    return missing;
  }
}
