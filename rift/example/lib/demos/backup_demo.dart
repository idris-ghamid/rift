import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class BackupDemoPage extends StatelessWidget {
  const BackupDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Backup & Restore',
      description: 'Full and incremental backup with JSON export/import',
      codeExample:
          "final backup = await Rift.backup();\nawait Rift.restore(backup);\nfinal inc =\n    await Rift.backupIncremental(timestamp);",
      runDemo: () async {
        final box = await Rift.openBox<Map>('backup_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Backup & Restore Demo ===\n');

        await box.putAll({
          'user1': {'name': 'Alice', 'role': 'admin'},
          'user2': {'name': 'Bob', 'role': 'user'},
          'user3': {'name': 'Charlie', 'role': 'user'},
        });
        buf.writeln('Original data: ${box.toMap()}\n');

        buf.writeln('--- Full Backup ---');
        final backup = await Rift.backup();
        final backupJson = jsonEncode(backup);
        buf.writeln('  Version: ${backup['version']}');
        buf.writeln('  Type: ${backup['type']}');
        buf.writeln('  Boxes: ${(backup['boxes'] as Map).keys.toList()}');
        buf.writeln('  JSON size: ${backupJson.length} chars');

        await box.clear();
        buf.writeln('\n--- After Clear ---');
        buf.writeln('  Box length: ${box.length}');

        buf.writeln('\n--- Restore from Backup ---');
        final parsed = jsonDecode(backupJson) as Map<String, dynamic>;
        await Rift.restore(parsed);
        buf.writeln('  Box length after restore: ${box.length}');
        buf.writeln('  Data: ${box.toMap()}');

        buf.writeln('\n--- Incremental Backup ---');
        await box.put('user4', {'name': 'Diana', 'role': 'editor'});
        final sinceTs = DateTime.now()
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch;
        final incBackup = await Rift.backupIncremental(sinceTs);
        buf.writeln('  Type: ${incBackup['type']}');
        buf.writeln('  Since: ${incBackup['since']}');

        await box.close();
        return buf.toString();
      },
    );
  }
}
