import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class CdcDemoPage extends StatelessWidget {
  const CdcDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'CDC',
      description: 'Change Data Capture for sync and integration',
      codeExample:
          "final cdc = CDCManager();\ncdc.recordChange(CDCEventType.insert, 'orders', 'o1', null, data);\ncdc.subscribe(boxNames: ['orders']).listen(...);",
      runDemo: () async {
        final cdc = CDCManager();
        StreamSubscription? sub;

        final buf = StringBuffer();
        buf.writeln('=== CDC (Change Data Capture) Demo ===\n');

        final events = <CDCEvent>[];
        sub = cdc.subscribe(boxNames: ['orders']).listen((event) {
          events.add(event);
        });

        // Record changes
        cdc.recordChange(CDCEventType.insert, 'orders', 'order1', null,
            {'item': 'Widget', 'qty': 5});
        cdc.recordChange(CDCEventType.insert, 'orders', 'order2', null,
            {'item': 'Gadget', 'qty': 3});
        cdc.recordChange(CDCEventType.update, 'orders', 'order1',
            {'item': 'Widget', 'qty': 5}, {'item': 'Widget', 'qty': 10});
        cdc.recordChange(CDCEventType.delete, 'orders', 'order2',
            {'item': 'Gadget', 'qty': 3}, null);
        cdc.recordChange(CDCEventType.insert, 'users', 'user1', null,
            {'name': 'Alice'}); // different box

        buf.writeln('Recorded 5 changes (4 in "orders", 1 in "users")\n');

        // Captured events from subscription
        buf.writeln('--- Subscribed Events (orders only) ---');
        for (final e in events) {
          buf.writeln('  ${e.toJson()}');
        }

        // Get changes since sequence 0
        buf.writeln('\n--- All Changes Since Seq 0 ---');
        final allChanges = await cdc.getEvents();
        for (final e in allChanges) {
          buf.writeln('  #${e.sequence} ${e.type} ${e.boxName}/${e.key}');
        }

        // Filtered changes
        buf.writeln('\n--- Filtered: insert events only ---');
        final filtered = await cdc.getEvents(
            filter: CDCFilter(eventTypes: [CDCEventType.insert]));
        for (final e in filtered) {
          buf.writeln('  #${e.sequence} ${e.boxName}/${e.key}');
        }

        buf.writeln('\n--- CDC Stats ---');
        buf.writeln('  Current sequence: ${cdc.currentSequence}');
        buf.writeln('  Event count: ${cdc.eventCount}');

        await sub.cancel();
        cdc.dispose();

        return buf.toString();
      },
    );
  }
}
