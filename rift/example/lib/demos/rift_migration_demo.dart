import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class RiftMigrationDemoPage extends StatelessWidget {
  const RiftMigrationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'rift Migration',
      description: 'Migration helper from rift/rift_ce to Rift',
      codeExample:
          "// Migrate all rift boxes to Rift\nfinal report = await HiveMigrationHelper.migrateAll(rift: Rift);\nprint('Migrated \${report.successfulMigrations} boxes');",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== rift Migration Helper Demo ===\n');

        buf.writeln('HiveMigrationHelper migrates data from rift/rift_ce');
        buf.writeln('binary files to Rift format automatically.\n');

        // Check for rift boxes
        buf.writeln('--- Step 1: Check for rift Boxes ---');
        final riftBoxes = HiveMigrationHelper.listHiveBoxes();
        buf.writeln('  HiveMigrationHelper.listHiveBoxes()');
        buf.writeln('  Found ${riftBoxes.length} rift box(es)');
        if (riftBoxes.isNotEmpty) {
          for (final name in riftBoxes) {
            buf.writeln('    - $name');
          }
        } else {
          buf.writeln(
              '  (No .rift files in current directory — expected in demo)');
        }
        buf.writeln('');

        // Check specific box
        buf.writeln('--- Step 2: Check If Specific Box Exists ---');
        final settingsExists = HiveMigrationHelper.hiveBoxExists('settings');
        buf.writeln('  hiveBoxExists("settings"): $settingsExists');
        final usersExists = HiveMigrationHelper.hiveBoxExists('users');
        buf.writeln('  hiveBoxExists("users"): $usersExists');
        buf.writeln('');

        // Migration code examples
        buf.writeln('--- Step 3: Migration API ---\n');

        buf.writeln('Migrate ALL rift boxes at once:');
        buf.writeln('');
        buf.writeln('  final report = await HiveMigrationHelper.migrateAll(');
        buf.writeln('    rift: Rift,');
        buf.writeln('    riftPath: \'/path/to/rift/data\',');
        buf.writeln('    riftPath: \'/path/to/rift/data\',');
        buf.writeln('  );');
        buf.writeln('');
        buf.writeln(
            '  print(\'Migrated \${report.successfulMigrations} boxes\');');
        buf.writeln('');

        buf.writeln('Migrate a SINGLE box:');
        buf.writeln('');
        buf.writeln('  final result = await HiveMigrationHelper.migrateBox(');
        buf.writeln('    \'settings\',');
        buf.writeln('    rift: Rift,');
        buf.writeln('    riftPath: \'/path/to/rift/data\',');
        buf.writeln('  );');
        buf.writeln('');
        buf.writeln('  if (result.success) {');
        buf.writeln(
            '    print(\'Migrated \${result.entriesMigrated} entries\');');
        buf.writeln('  } else {');
        buf.writeln('    print(\'Error: \${result.error}\');');
        buf.writeln('  }');
        buf.writeln('');

        // Simulate migration report
        buf.writeln('--- Step 4: MigrationReport Structure ---\n');
        final sampleReport = MigrationReport(
          totalBoxes: 3,
          successfulMigrations: 2,
          failedMigrations: 1,
          results: [
            BoxMigrationResult(
                boxName: 'settings', success: true, entriesMigrated: 15),
            BoxMigrationResult(
                boxName: 'users', success: true, entriesMigrated: 250),
            BoxMigrationResult(
              boxName: 'cache',
              success: false,
              entriesMigrated: 0,
              error: 'rift box not found: cache',
            ),
          ],
          elapsed: const Duration(milliseconds: 342),
        );

        buf.writeln('  Sample MigrationReport:');
        buf.writeln('    totalBoxes: ${sampleReport.totalBoxes}');
        buf.writeln(
            '    successfulMigrations: ${sampleReport.successfulMigrations}');
        buf.writeln('    failedMigrations: ${sampleReport.failedMigrations}');
        buf.writeln('    elapsed: ${sampleReport.elapsed.inMilliseconds}ms');
        buf.writeln('');
        buf.writeln('  Results:');
        for (final r in sampleReport.results) {
          if (r.success) {
            buf.writeln(
                '    ✅ ${r.boxName}: ${r.entriesMigrated} entries migrated');
          } else {
            buf.writeln('    ❌ ${r.boxName}: ${r.error}');
          }
        }
        buf.writeln('');

        // boxMigrationResult
        buf.writeln('--- Step 5: boxMigrationResult Structure ---\n');
        buf.writeln('  boxMigrationResult {');
        buf.writeln('    boxName: String');
        buf.writeln('    success: bool');
        buf.writeln('    entriesMigrated: int');
        buf.writeln('    error: String? (null on success)');
        buf.writeln('  }');
        buf.writeln('');

        // Migration workflow
        buf.writeln('--- Step 6: Complete Migration Workflow ---\n');

        buf.writeln('  1. Install Rift:');
        buf.writeln('     dart pub add rift');
        buf.writeln('');
        buf.writeln('  2. Replace rift imports:');
        buf.writeln('     - import \'package:rift/rift.dart\';');
        buf.writeln('     + import \'package:rift/rift.dart\';');
        buf.writeln('');
        buf.writeln('  3. Replace rift constant with Rift:');
        buf.writeln('     - final box = await rift.openBox(\'myBox\');');
        buf.writeln('     + final box = await Rift.openBox(\'myBox\');');
        buf.writeln('');
        buf.writeln('  4. Run migration:');
        buf.writeln(
            '     final report = await HiveMigrationHelper.migrateAll(');
        buf.writeln('       rift: Rift,');
        buf.writeln('     );');
        buf.writeln('');
        buf.writeln('  5. Verify migration results');
        buf.writeln('  6. Remove rift dependency from pubspec.yaml');
        buf.writeln('');

        // rift binary format
        buf.writeln('--- Step 7: How Migration Works Internally ---\n');
        buf.writeln('  rift files have this binary format:');
        buf.writeln('  ┌─────────────────────────────────┐');
        buf.writeln('  │ Header: "rift" + version byte    │');
        buf.writeln('  ├─────────────────────────────────┤');
        buf.writeln('  │ Frame: key_len + key + val_len   │');
        buf.writeln('  │        + value + CRC32           │');
        buf.writeln('  ├─────────────────────────────────┤');
        buf.writeln('  │ Frame: ...                       │');
        buf.writeln('  └─────────────────────────────────┘');
        buf.writeln('');
        buf.writeln('  HiveMigrationHelper:');
        buf.writeln('  1. Reads .rift files');
        buf.writeln('  2. Parses the binary format (header + frames)');
        buf.writeln('  3. Extracts key-value pairs');
        buf.writeln('  4. Writes them into Rift boxes');
        buf.writeln('');

        buf.writeln('--- API Summary ---');
        buf.writeln(
            '  ✅ HiveMigrationHelper.migrateAll(rift:, riftPath:, riftPath:)');
        buf.writeln(
            '  ✅ HiveMigrationHelper.migrateBox(name, rift:, riftPath:, riftPath:)');
        buf.writeln('  ✅ HiveMigrationHelper.riftBoxExists(name, path:)');
        buf.writeln('  ✅ HiveMigrationHelper.listriftBoxes(path:)');
        buf.writeln(
            '  ✅ MigrationReport — total, success, failed, elapsed, results');
        buf.writeln(
            '  ✅ boxMigrationResult — boxName, success, entriesMigrated, error');

        return buf.toString();
      },
    );
  }
}



