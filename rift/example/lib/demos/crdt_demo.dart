import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class CrdtDemoPage extends StatelessWidget {
  const CrdtDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'CRDT',
      description: 'Conflict-free replicated data types for distributed sync',
      codeExample:
          "final counter = GCounter('nodeA')..increment(5);\nfinal merged = counter.merge(otherCounter);\nfinal doc = CRDTDocument('phone')..put('key', 'value');",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== CRDT Demo ===\n');

        // G-Counter
        buf.writeln('--- G-Counter (Grow-only) ---');
        final c1 = GCounter('nodeA')
          ..increment(5)
          ..increment(3);
        final c2 = GCounter('nodeB')
          ..increment(2)
          ..increment(4);
        buf.writeln('  nodeA: ${c1.value} (increments: 5+3)');
        buf.writeln('  nodeB: ${c2.value} (increments: 2+4)');
        final merged = c1.merge(c2);
        buf.writeln('  Merged: ${merged.value}');

        // PN-Counter
        buf.writeln('\n--- PN-Counter (Positive-Negative) ---');
        final pn = PNCounter('nodeA');
        pn.increment(10);
        pn.decrement(3);
        buf.writeln('  Value: ${pn.value} (10-3)');
        final pn2 = PNCounter('nodeB')
          ..increment(5)
          ..decrement(1);
        final pnMerged = pn.merge(pn2);
        buf.writeln('  Merged with nodeB: ${pnMerged.value}');

        // G-Set
        buf.writeln('\n--- G-Set (Grow-only Set) ---');
        final gs1 = GSet<String>()
          ..add('apple')
          ..add('banana');
        final gs2 = GSet<String>()
          ..add('banana')
          ..add('cherry');
        final gsMerged = gs1.merge(gs2);
        buf.writeln('  Set1: ${gs1.value}');
        buf.writeln('  Set2: ${gs2.value}');
        buf.writeln('  Merged: ${gsMerged.value}');

        // OR-Set
        buf.writeln('\n--- OR-Set (Observed-Remove) ---');
        final ors = ORSet<String>('nodeA');
        ors.add('x');
        ors.add('y');
        buf.writeln('  After add x,y: ${ors.value}');
        ors.remove('x');
        buf.writeln('  After remove x: ${ors.value}');
        final ors2 = ORSet<String>('nodeB')
          ..add('x')
          ..add('z');
        final orsMerged = ors.merge(ors2);
        buf.writeln(
            '  Merged with {x,z}: ${orsMerged.value} (add wins over remove)');

        // LWW-Register
        buf.writeln('\n--- LWW-Register (Last-Writer-Wins) ---');
        final lww1 = LWWRegister<String>('v1', 'nodeA');
        final lww2 = LWWRegister<String>('v2', 'nodeB');
        final lwwMerged = lww1.merge(lww2);
        buf.writeln('  nodeA: "${lww1.value}", nodeB: "${lww2.value}"');
        buf.writeln('  Winner: "${lwwMerged.value}" (later timestamp wins)');

        // LWW-Map
        buf.writeln('\n--- LWW-Map ---');
        final lm = LWWMap<String, dynamic>('nodeA');
        lm.put('name', 'Alice');
        lm.put('age', 30);
        buf.writeln('  Map: ${lm.value}');

        // CRDT Document
        buf.writeln('\n--- CRDT Document ---');
        final doc1 = CRDTDocument('phone')
          ..put('name', 'Alice')
          ..put('city', 'Cairo');
        final doc2 = CRDTDocument('laptop')
          ..put('name', 'Bob')
          ..put('city', 'Riyadh');
        final docMerged = doc1.merge(doc2);
        buf.writeln(
            '  Phone doc: name=${doc1.get('name')}, city=${doc1.get('city')}');
        buf.writeln(
            '  Laptop doc: name=${doc2.get('name')}, city=${doc2.get('city')}');
        buf.writeln('  Vector clocks: ${docMerged.vectorClock}');
        buf.writeln('  Entries: ${docMerged.length}');

        return buf.toString();
      },
    );
  }
}
