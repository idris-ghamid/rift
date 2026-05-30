import 'package:flutter/material.dart';
import '../widgets/demo_page.dart';

class WalDemoPage extends StatelessWidget {
  const WalDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'WAL Recovery',
      description: 'Write-Ahead Log ensures crash recovery',
      codeExample:
          "final wal = WALManager(path, enabled: true);\nawait wal.open();\nawait wal.log(wal.createPutEntry('box', 'key', value));\nawait wal.recover();",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== WAL (Write-Ahead Log) Demo ===\n');

        // WAL is internal to Rift. We demonstrate the API.
        buf.writeln('WAL provides crash recovery by logging writes before');
        buf.writeln('they are applied to the main data file.\n');

        buf.writeln('--- WAL Manager API ---');
        buf.writeln('  WALManager(path, enabled: true)');
        buf.writeln('  await wal.open();');
        buf.writeln(
            '  await wal.log(wal.createPutEntry("box", "key", value));');
        buf.writeln('  await wal.checkpoint(); // flush + clear WAL');
        buf.writeln(
            '  final count = await wal.recover(); // replay after crash');

        buf.writeln('\n--- How it works ---');
        buf.writeln('1. Before any write → log to WAL file');
        buf.writeln('2. Apply write to main data');
        buf.writeln('3. After compaction → checkpoint (clear WAL)');
        buf.writeln('4. On crash → recover() replays uncommitted entries');

        buf.writeln('\n--- Entry Types ---');
        buf.writeln('  createPutEntry(boxName, key, value)');
        buf.writeln('  createDeleteEntry(boxName, key)');
        buf.writeln('  createPutAllEntry(boxName, kvPairs)');
        buf.writeln('  createClearEntry(boxName)');

        buf.writeln('\n--- Rift Integration ---');
        buf.writeln('WAL is enabled by default when crashRecovery: true');
        buf.writeln('  Rift.openBox("data", crashRecovery: true);');

        buf.writeln('\n--- WAL File ---');
        buf.writeln('  Written to: <dbPath>/rift.wal');
        buf.writeln('  Supports: logBatch() for atomic multi-entry writes');
        buf.writeln('  purgeBox() to remove entries for a deleted box');

        buf.writeln('\n✅ WAL ensures data integrity even after crashes');

        return buf.toString();
      },
    );
  }
}
