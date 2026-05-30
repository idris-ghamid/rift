import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class SyncDemoPage extends StatelessWidget {
  const SyncDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Sync Layer',
      description: 'Sync layer with in-memory backend',
      codeExample:
          "final sync = RiftSync();\nsync.configure(InMemorySyncBackend(), SyncConfig(...));\nsync.registerBox('box', box);\nawait sync.startSync();",
      runDemo: () async {
        final box = await Rift.openBox<Map>('sync_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Sync Layer Demo ===\n');

        // Setup sync with in-memory backend
        final backend = InMemorySyncBackend();
        final sync = RiftSync();
        sync.setNodeId('device_1');
        sync.configure(
            backend,
            SyncConfig(
              endpoint: 'memory://local',
              syncInterval: const Duration(seconds: 30),
            ));

        // Register box for sync
        sync.registerBox('sync_demo', box);

        buf.writeln('Configured RiftSync with InMemorySyncBackend');
        buf.writeln('Node: device_1\n');

        // Add data
        await box.put('item1', {'name': 'Local Item 1'});
        await box.put('item2', {'name': 'Local Item 2'});
        buf.writeln('Added 2 local items');

        // Start sync
        buf.writeln('\n--- Start Sync ---');
        await sync.startSync();
        await Future.delayed(const Duration(milliseconds: 100));
        buf.writeln('  Status: ${sync.status}');

        // Force sync to push changes
        buf.writeln('\n--- Force Sync ---');
        final result = await sync.forceSync();
        buf.writeln('  Success: ${result.success}');
        buf.writeln('  Pushed: ${result.pushedCount}');

        // Backend changes
        buf.writeln('\n--- Backend Stored Changes ---');
        buf.writeln('  Changes: ${backend.allChanges.length}');
        for (final c in backend.allChanges) {
          buf.writeln('    ${c.boxName}/${c.key}: ${c.type} = ${c.value}');
        }

        // Pull changes
        buf.writeln('\n--- Pull Remote Changes ---');
        await backend.pushChanges([
          SyncChange(
            boxName: 'sync_demo',
            key: 'remote1',
            type: ChangeType.create,
            value: {'name': 'Remote Item'},
            timestamp: DateTime.now(),
            nodeId: 'device_2',
          )
        ]);
        final pullResult = await sync.forceSync();
        buf.writeln('  Remote item in box: ${box.get('remote1')}');

        // Change tracker
        buf.writeln('\n--- Change Tracker ---');
        buf.writeln(
            '  Pending changes: ${sync.changeTracker.totalChangeCount}');

        await sync.stopSync();
        backend.dispose();
        sync.dispose();

        buf.writeln('\n✅ Sync demo complete');

        await box.close();
        return buf.toString();
      },
    );
  }
}
