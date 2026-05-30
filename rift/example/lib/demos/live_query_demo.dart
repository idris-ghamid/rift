import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class LiveQueryDemoPage extends StatelessWidget {
  const LiveQueryDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Live Query',
      description: 'Live queries auto-update when data changes',
      codeExample:
          "LiveQuery(box: box, execute: () => box.query()\n  .where('price', greaterThan: 1).findAll());\nliveQuery.stream.listen((results) => ...);",
      runDemo: () async {
        StreamSubscription? sub;
        LiveQuery? liveQuery;

        final box = await Rift.openBox<Map>('live_query_demo');
        await box.clear();
        await box.putAll({
          'i1': {'label': 'Apple', 'price': 2},
          'i2': {'label': 'Banana', 'price': 1},
          'i3': {'label': 'Cherry', 'price': 5},
        });

        final buf = StringBuffer();
        buf.writeln('=== Live Query Demo ===\n');
        buf.writeln('Initial data: 3 items');

        int updateCount = 0;
        liveQuery = LiveQuery<Map>(
          box: box,
          execute: () => box.query().where('price', greaterThan: 1).findAll(),
          debounceDuration: const Duration(milliseconds: 50),
        );

        sub = liveQuery.stream.listen((results) {
          updateCount++;
          buf.writeln('\n--- Live Query Update #$updateCount ---');
          buf.writeln('  Items with price > 1: ${results.length}');
          for (final r in results) {
            buf.writeln('    $r');
          }
        });

        // Trigger a change after a delay
        await Future.delayed(const Duration(milliseconds: 200));
        await box.put('i4', {'label': 'Date', 'price': 3});

        await Future.delayed(const Duration(milliseconds: 200));
        await box.put('i2', {'label': 'Banana', 'price': 4});

        await Future.delayed(const Duration(milliseconds: 300));
        buf.writeln('\n--- Demo Complete ---');
        buf.writeln(
            'Live query auto-updated $updateCount times as data changed');

        await sub.cancel();
        liveQuery.dispose();

        return buf.toString();
      },
    );
  }
}
