import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class MigrationDemoPage extends StatelessWidget {
  const MigrationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Schema Migration',
      description:
          'Schema migration framework for versioned data with upgrade and downgrade paths',
      codeExample:
          "Migrator([\n  MigrationStep(fromVersion: 1, toVersion: 2,\n    migrate: (data) { data['email'] = ''; return data; }),\n]);\nmigrator.validateChain(1, 3);",
      runDemo: () async {
        final box = await Rift.openBox<Map>('migration_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Schema Migration Demo ===\n');

        // Insert V1 data
        await box.putAll({
          'u1': {'name': 'Alice', 'age': 30},
          'u2': {'name': 'Bob', 'age': 25},
        });
        buf.writeln('V1 Data: ${box.toMap()}\n');

        // Define migrations
        final migrator = Migrator([
          MigrationStep(
            fromVersion: 1,
            toVersion: 2,
            migrate: (data) {
              data['email'] = data['email'] ??
                  '${data['name'].toString().toLowerCase()}@example.com';
              return data;
            },
          ),
          MigrationStep(
            fromVersion: 2,
            toVersion: 3,
            migrate: (data) {
              data['fullName'] = data.remove('name');
              return data;
            },
          ),
        ]);

        // Validate chain
        buf.writeln('--- Validate Migration Chain ---');
        final missing = migrator.validateChain(1, 3);
        buf.writeln('  Missing steps: ${missing.isEmpty ? "none" : missing}');

        // Migration info
        buf.writeln('\n--- Migration Info ---');
        buf.writeln('  Max reachable: ${migrator.maxReachableVersion}');
        buf.writeln('  Min reachable: ${migrator.minReachableVersion}');

        // Manual migration simulation
        buf.writeln('\n--- Simulating Migration 1→2 (add email) ---');
        final v1Keys = box.keys.toList();
        for (final k in v1Keys) {
          final val = box.get(k);
          if (val is Map<String, dynamic>) {
            val['email'] ??=
                '${val['name'].toString().toLowerCase()}@example.com';
            await box.put(k, val);
          }
        }
        buf.writeln('After v1→v2:');
        for (final k in box.keys) {
          buf.writeln('  $k => ${box.get(k)}');
        }

        buf.writeln('\n--- Simulating Migration 2→3 (name → fullName) ---');
        final v2Keys = box.keys.toList();
        for (final k in v2Keys) {
          final val = box.get(k);
          if (val is Map<String, dynamic>) {
            val['fullName'] = val.remove('name');
            await box.put(k, val);
          }
        }
        buf.writeln('After v2→v3:');
        for (final k in box.keys) {
          buf.writeln('  $k => ${box.get(k)}');
        }

        // Schema version tracking
        buf.writeln('\n--- Schema Version Tracking ---');
        await box.put('__rift_schema_version__', {'version': 3});
        buf.writeln(
            '  Stored version in box: ${box.get('__rift_schema_version__')}');
        buf.writeln('  SchemaVersionTracker automates this internally');

        await box.close();
        return buf.toString();
      },
    );
  }
}
