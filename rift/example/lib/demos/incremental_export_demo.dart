import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class IncrementalExportDemoPage extends StatelessWidget {
  const IncrementalExportDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Incremental Export',
      description: 'Incremental export — export only changes since last export',
      codeExample:
          "final exporter = IncrementalExporter();\nexporter.recordPut('key');\nexporter.recordDelete('old');\nfinal export = await exporter.export(box);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Incremental Export Demo ===\n');

        buf.writeln(
            'IncrementalExporter exports only changes since the last export.');
        buf.writeln('This is efficient for sync, backup, and data transfer.\n');

        // Create exporter
        buf.writeln('--- Step 1: Create Exporter ---');
        final exporter = IncrementalExporter();
        buf.writeln('  IncrementalExporter created');
        buf.writeln('  currentVersion: ${exporter.currentVersion}');
        buf.writeln('  lastExportVersion: ${exporter.lastExportVersion}');
        buf.writeln('');

        // Open a box
        buf.writeln('--- Step 2: Create Box with Data ---');
        final box = await Rift.openBox<Map>('inc_export_demo');
        await box.clear();

        // Add initial data and record puts
        buf.writeln('--- Step 3: Add Data & Record Puts ---');
        await box.put('user1', {'name': 'Alice', 'age': 30});
        exporter.recordPut('user1');
        buf.writeln(
            '  put user1, recordPut("user1") → version ${exporter.currentVersion}');

        await box.put('user2', {'name': 'Bob', 'age': 25});
        exporter.recordPut('user2');
        buf.writeln(
            '  put user2, recordPut("user2") → version ${exporter.currentVersion}');

        await box.put('user3', {'name': 'Charlie', 'age': 35});
        exporter.recordPut('user3');
        buf.writeln(
            '  put user3, recordPut("user3") → version ${exporter.currentVersion}');
        buf.writeln('');

        // First export
        buf.writeln('--- Step 4: First Export (All Data) ---');
        final export1 = await exporter.export(box);
        buf.writeln('  Export result:');
        buf.writeln('    fromVersion: ${export1.fromVersion}');
        buf.writeln('    toVersion: ${export1.toVersion}');
        buf.writeln('    upserts: ${export1.upserts.length} entries');
        for (final entry in export1.upserts.entries) {
          buf.writeln('      ${entry.key} => ${entry.value}');
        }
        buf.writeln('    deletes: ${export1.deletes}');
        buf.writeln('    changeCount: ${export1.changeCount}');
        buf.writeln('    isEmpty: ${export1.isEmpty}');
        buf.writeln('    JSON: ${export1.toJson()}');
        buf.writeln('');

        // Make more changes
        buf.writeln('--- Step 5: Make Changes After First Export ---');
        await box.put('user1', {'name': 'Alice', 'age': 31, 'updated': true});
        exporter.recordPut('user1');
        buf.writeln('  Updated user1 → version ${exporter.currentVersion}');

        await box.delete('user2');
        exporter.recordDelete('user2');
        buf.writeln('  Deleted user2 → version ${exporter.currentVersion}');

        await box.put('user4', {'name': 'Diana', 'age': 28});
        exporter.recordPut('user4');
        buf.writeln('  Added user4 → version ${exporter.currentVersion}');
        buf.writeln('');

        // Second export (incremental)
        buf.writeln('--- Step 6: Second Export (Incremental) ---');
        final export2 = await exporter.export(box);
        buf.writeln('  Incremental export result:');
        buf.writeln('    fromVersion: ${export2.fromVersion}');
        buf.writeln('    toVersion: ${export2.toVersion}');
        buf.writeln('    upserts: ${export2.upserts.length} entries');
        for (final entry in export2.upserts.entries) {
          buf.writeln('      ${entry.key} => ${entry.value}');
        }
        buf.writeln('    deletes: ${export2.deletes}');
        buf.writeln('    changeCount: ${export2.changeCount}');
        buf.writeln('');

        // Third export (no changes)
        buf.writeln('--- Step 7: Third Export (No Changes) ---');
        final export3 = await exporter.export(box);
        buf.writeln('  No changes since last export:');
        buf.writeln('    upserts: ${export3.upserts.length}');
        buf.writeln('    deletes: ${export3.deletes.length}');
        buf.writeln('    isEmpty: ${export3.isEmpty}');
        buf.writeln('');

        // Version tracking summary
        buf.writeln('--- Version Tracking Summary ---');
        buf.writeln('  currentVersion: ${exporter.currentVersion}');
        buf.writeln('  lastExportVersion: ${exporter.lastExportVersion}');
        buf.writeln('');

        // Import into another box
        buf.writeln('--- Step 8: Import into Another Box ---');
        final targetBox = await Rift.openBox<Map>('inc_import_demo');
        await targetBox.clear();
        final targetExporter = IncrementalExporter();
        await targetExporter.import(targetBox, export2);
        buf.writeln('  Imported incremental export into target box');
        buf.writeln('  Target box length: ${targetBox.length}');
        for (final k in targetBox.keys) {
          buf.writeln('    $k => ${targetBox.get(k)}');
        }
        buf.writeln('');

        // Reset
        buf.writeln('--- Step 9: Reset Exporter ---');
        exporter.reset();
        buf.writeln('  exporter.reset() called');
        buf.writeln('  currentVersion: ${exporter.currentVersion}');
        buf.writeln('  lastExportVersion: ${exporter.lastExportVersion}');

        buf.writeln('\n--- API Summary ---');
        buf.writeln('  ✅ recordPut(key) — track an upsert');
        buf.writeln('  ✅ recordDelete(key) — track a deletion');
        buf.writeln('  ✅ export(box) → IncrementalExport');
        buf.writeln('  ✅ import(box, IncrementalExport)');
        buf.writeln('  ✅ reset() — clear all tracking state');
        buf.writeln('  ✅ IncrementalExport.toJson() / fromJson()');

        await box.close();
        await targetBox.close();
        return buf.toString();
      },
    );
  }
}
