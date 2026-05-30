import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class TransactionDemoPage extends StatelessWidget {
  const TransactionDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Transactions',
      description: 'ACID transactions with savepoints and rollback',
      codeExample:
          "final tx = txManager.begin();\ntx.put('key', value);\ntx.savepoint('sp1');\ntx.rollbackTo('sp1');\ntxManager.commit(tx);",
      runDemo: () async {
        final box = await Rift.openBox<Map>('tx_demo');
        await box.clear();
        final txManager = TransactionManager();

        final buf = StringBuffer();
        buf.writeln('=== ACID Transactions Demo ===\n');

        // Transaction with commit
        buf.writeln('--- Transaction 1: Commit ---');
        final tx1 = txManager.begin();
        buf.writeln('Started: ${tx1.id}');
        tx1.put('user1', {'name': 'Alice', 'balance': 100});
        tx1.put('user2', {'name': 'Bob', 'balance': 50});
        tx1.savepoint('before_transfer');
        buf.writeln('Created savepoint: before_transfer');
        tx1.put('user1', {'name': 'Alice', 'balance': 70});
        tx1.put('user2', {'name': 'Bob', 'balance': 80});
        buf.writeln(
            'Ops: ${tx1.operationCount}, Savepoints: ${tx1.savepointCount}');
        txManager.commit(tx1);
        await txManager.applyToBox(tx1, box);
        buf.writeln('Committed! isCommitted=${tx1.isCommitted}');

        // Transaction with rollback to savepoint
        buf.writeln('\n--- Transaction 2: Rollback to Savepoint ---');
        final tx2 = txManager.begin();
        tx2.put('user1', {'name': 'Alice', 'balance': 999});
        tx2.savepoint('before_bad_update');
        tx2.put('user1', {'name': 'Alice', 'balance': -500}); // bad!
        buf.writeln('Bad update made, rolling back to savepoint…');
        tx2.rollbackTo('before_bad_update');
        buf.writeln('After rollback: ops=${tx2.operationCount}');
        tx2.put('user1', {'name': 'Alice', 'balance': 70}); // fix
        txManager.commit(tx2);
        await txManager.applyToBox(tx2, box);
        buf.writeln('Fixed and committed!');

        // Transaction with full rollback
        buf.writeln('\n--- Transaction 3: Full Rollback ---');
        final tx3 = txManager.begin();
        tx3.put('user3', {'name': 'Eve', 'balance': 0});
        buf.writeln('Added user3, but rolling back everything…');
        txManager.rollback(tx3);
        buf.writeln('Rolled back! isActive=${tx3.isActive}');

        buf.writeln('\n--- Box contents after all transactions ---');
        for (final k in box.keys) {
          buf.writeln('  $k => ${box.get(k)}');
        }

        buf.writeln('\n--- Transaction Manager Stats ---');
        buf.writeln('  Active: ${txManager.activeCount}');
        buf.writeln(
            '  Committed history: ${txManager.committedHistory.length}');

        await box.close();
        return buf.toString();
      },
    );
  }
}
