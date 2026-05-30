import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class ReplicationDemoPage extends StatelessWidget {
  const ReplicationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Replication',
      description: 'Master-slave and peer-to-peer replication',
      codeExample:
          "final mgr = ReplicationManager(localNodeId: 'master', mode: ReplicationMode.masterSlave);\nmgr.addReplica(ReplicaNode(id: 'slave', role: ReplicaRole.slave));\nawait mgr.start();",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Replication Demo ===\n');

        // Create replication manager (master-slave)
        final manager = ReplicationManager(
          localNodeId: 'master_1',
          mode: ReplicationMode.masterSlave,
          conflictStrategy: ConflictResolutionStrategy.lastWriteWins,
          syncInterval: const Duration(seconds: 10),
        );

        // Add replica nodes
        manager.addReplica(ReplicaNode(
          id: 'slave_1',
          role: ReplicaRole.slave,
          endpoint: 'https://replica1.example.com',
        ));
        manager.addReplica(ReplicaNode(
          id: 'slave_2',
          role: ReplicaRole.slave,
          endpoint: 'https://replica2.example.com',
        ));

        buf.writeln('--- Topology ---');
        buf.writeln('  Mode: ${manager.mode.name}');
        buf.writeln('  Local: ${manager.localNodeId}');
        buf.writeln(
            '  Replicas: ${manager.replicas.map((r) => r.id).toList()}');

        // Start replication
        buf.writeln('\n--- Start Replication ---');
        manager.start();
        buf.writeln('  Running: ${manager.isRunning}');

        // Record changes
        buf.writeln('\n--- Record Changes ---');
        manager.recordChange(
            'user_1', {'name': 'Idris'}, ReplicationEventType.upsert);
        manager.recordChange(
            'user_2', {'name': 'Ahmed'}, ReplicationEventType.upsert);
        manager.recordChange('user_1', null, ReplicationEventType.delete);
        buf.writeln('  Pending changes: ${manager.pendingChangeCount}');

        // Listen for events
        final events = <ReplicationEvent>[];
        manager.events.listen((event) => events.add(event));

        // Force sync
        buf.writeln('\n--- Force Sync ---');
        manager.forceSync();
        buf.writeln('  Events emitted: ${events.length}');
        for (final event in events) {
          buf.writeln('    ${event.type.name} from ${event.sourceNodeId}');
        }

        // Replica status
        buf.writeln('\n--- Replica Status ---');
        for (final replica in manager.replicas) {
          buf.writeln(
              '  ${replica.id}: ${replica.status.name}, lastReplicated: ${replica.lastReplicatedAt}');
        }

        // Conflict resolution
        buf.writeln('\n--- Conflict Resolution ---');
        final conflict = ReplicationConflict(
          key: 'user_1',
          localValue: {'name': 'Idris (local)'},
          remoteValue: {'name': 'Ahmed (remote)'},
          localTimestamp: DateTime.now().subtract(const Duration(seconds: 5)),
          remoteTimestamp: DateTime.now(),
          sourceNodeId: 'slave_1',
        );
        final resolved = manager.resolveConflict(conflict);
        buf.writeln('  Strategy: ${manager.conflictStrategy.name}');
        buf.writeln('  Local: ${conflict.localValue}');
        buf.writeln('  Remote: ${conflict.remoteValue}');
        buf.writeln('  Resolved: $resolved');

        // P2P mode demo
        buf.writeln('\n--- P2P Mode ---');
        final p2p = ReplicationManager(
          localNodeId: 'peer_1',
          mode: ReplicationMode.peerToPeer,
          conflictStrategy: ConflictResolutionStrategy.localWins,
        );
        p2p.addReplica(ReplicaNode(id: 'peer_2', role: ReplicaRole.peer));
        buf.writeln('  Mode: ${p2p.mode.name}');
        buf.writeln('  Conflict: ${p2p.conflictStrategy.name}');

        manager.dispose();
        p2p.dispose();

        return buf.toString();
      },
    );
  }
}
