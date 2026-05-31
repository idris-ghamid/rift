import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class CrossBoxTxDemoPage extends StatelessWidget {
  const CrossBoxTxDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Cross-Box TX',
      description: 'Atomic transactions across multiple boxes',
      codeExample:
          "final tx = CrossBoxTransaction([box1, box2]);\ntx.put('accounts', 'alice', data);\ntx.put('ledger', 'tx1', record);\nawait tx.commit(); // atomic!",
      runDemo: () async {
        final accountsBox = await Rift.openBox<Map>('accounts');
        final ledgerBox = await Rift.openBox<Map>('ledger');
        await accountsBox.clear();
        await ledgerBox.clear();

        final buf = StringBuffer();
        buf.writeln('=== Cross-Box Transaction Demo ===\n');

        // Initial balances
        await accountsBox.putAll({
          'alice': {'name': 'Alice', 'balance': 1000},
          'bob': {'name': 'Bob', 'balance': 500},
        });
        buf.writeln('Initial state:');
        buf.writeln('  Alice: \$1000, Bob: \$500\n');

        // Transaction: transfer $200 from Alice to Bob
        buf.writeln('--- Transfer \$200: Alice → Bob ---');
        final tx = CrossBoxTransaction([accountsBox, ledgerBox]);

        tx.put('accounts', 'alice', {'name': 'Alice', 'balance': 800});
        tx.put('accounts', 'bob', {'name': 'Bob', 'balance': 700});
        tx.put('ledger', 'tx1', {
          'from': 'alice',
          'to': 'bob',
          'amount': 200,
          'timestamp': DateTime.now().toIso8601String(),
        });

        buf.writeln('  Pending writes: ${tx.pendingWriteCount}');
        buf.writeln('  Pending deletes: ${tx.pendingDeleteCount}');
        buf.writeln('  Boxes: ${tx.boxNames}');

        await tx.commit();
        buf.writeln('\n  Transaction committed!');
        buf.writeln(
            '  isActive: ${tx.isActive}, isCommitted: ${tx.isCommitted}');

        buf.writeln('\n--- After Transaction ---');
        buf.writeln('  Alice: \$${(accountsBox.get('alice'))?['balance']}');
        buf.writeln('  Bob: \$${(accountsBox.get('bob'))?['balance']}');
        buf.writeln('  Ledger: ${ledgerBox.get('tx1')}');

        // Rollback demo
        buf.writeln('\n--- Rollback Demo ---');
        final tx2 = CrossBoxTransaction([accountsBox]);
        tx2.put('accounts', 'alice', {'name': 'Alice', 'balance': 0}); // bad!
        buf.writeln('  Bad update pending, rolling back…');
        await tx2.rollback();
        buf.writeln('  isActive: ${tx2.isActive}');
        buf.writeln(
            '  Alice unchanged: \$${(accountsBox.get('alice'))?['balance']}');

        await accountsBox.close();
        await ledgerBox.close();
        return buf.toString();
      },
    );
  }
}
