import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class SnapshotDemoPage extends StatelessWidget {
  const SnapshotDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Snapshot Isolation',
      description: 'MVCC snapshot isolation for consistent reads',
      codeExample:
          "final isolation = SnapshotIsolation();\nfinal snap = await isolation.createSnapshot(box);\nfinal diff = SnapshotDiff.between(snap1, snap2);",
      runDemo: () async {
        final box = await Rift.openBox<Map>('snapshot_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Snapshot Isolation Demo ===\n');

        final isolation = SnapshotIsolation();

        // Initial data
        await box.put('user1', {'name': 'Idris', 'age': 25});
        await box.put('user2', {'name': 'Ahmed', 'age': 30});

        // Take snapshot v1
        buf.writeln('--- Snapshot v1 ---');
        final snap1 = await isolation.createSnapshot(box);
        buf.writeln('  ${snap1}');
        buf.writeln('  user1: ${snap1.get('user1')}');
        buf.writeln('  user2: ${snap1.get('user2')}');
        buf.writeln('  Entries: ${snap1.length}');

        // Modify data
        buf.writeln('\n--- Modify Data ---');
        await box.put('user1', {'name': 'Idris', 'age': 26});
        await box.put('user3', {'name': 'Sara', 'age': 22});
        await box.delete('user2');
        buf.writeln('  Updated user1 age to 26');
        buf.writeln('  Added user3');
        buf.writeln('  Deleted user2');

        // Snapshot v1 is unchanged
        buf.writeln('\n--- Snapshot v1 Still Unchanged ---');
        buf.writeln('  user1: ${snap1.get('user1')}');
        buf.writeln('  user2: ${snap1.get('user2')}');
        buf.writeln('  user3: ${snap1.get('user3')} (null = not in snapshot)');

        // Take snapshot v2
        buf.writeln('\n--- Snapshot v2 ---');
        final snap2 = await isolation.createSnapshot(box);
        buf.writeln('  ${snap2}');
        buf.writeln('  user1: ${snap2.get('user1')}');
        buf.writeln('  user3: ${snap2.get('user3')}');

        // Diff between v1 and v2
        buf.writeln('\n--- SnapshotDiff v1 → v2 ---');
        final diff = SnapshotDiff.between(snap1, snap2);
        buf.writeln(
            '  Added: ${diff.addedCount}, Modified: ${diff.modifiedCount}, Removed: ${diff.removedCount}');
        for (final change in diff.changes) {
          buf.writeln(
              '  ${change.type}: ${change.key} ${change.oldValue} → ${change.newValue}');
        }

        // Use isolation.diff()
        buf.writeln('\n--- Via Isolation.diff() ---');
        final diff2 = isolation.diff('snapshot_demo', 1, 2);
        if (diff2 != null) {
          buf.writeln('  Identical: ${diff2.isIdentical}');
          buf.writeln('  Total changes: ${diff2.changes.length}');
        }

        buf.writeln('\n--- Snapshot Count ---');
        buf.writeln(
            '  Snapshots stored: ${isolation.snapshotCount('snapshot_demo')}');

        await box.close();
        return buf.toString();
      },
    );
  }
}
