import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class SignalDemoPage extends StatelessWidget {
  const SignalDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Signals',
      description: 'Reactive signals for automatic UI updates',
      codeExample:
          "box.watch().listen((event) { /* react */ });\nLiveQuery(box: box, execute: query).stream.listen(...);",
      runDemo: () async {
        final box = await Rift.openBox<Map>('signal_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Reactive Signals Demo ===\n');

        // Rift's box.watch() provides reactive signals
        buf.writeln('Rift boxes emit signals on every change via box.watch()');
        buf.writeln('This enables reactive UI updates automatically.\n');

        final events = <BoxEvent>[];
        final sub = box.watch().listen((event) {
          events.add(event);
        });

        // Put data → signals fire
        buf.writeln('--- Putting data (signals fire) ---');
        await box.put('counter', {'value': 1});
        await box.put('user', {'name': 'Alice'});
        await Future.delayed(const Duration(milliseconds: 50));
        buf.writeln('  Events captured: ${events.length}');
        for (final e in events) {
          buf.writeln(
              '    key=${e.key}, deleted=${e.deleted}, value=${e.value}');
        }

        // Update → signal fires
        buf.writeln('\n--- Updating data ---');
        await box.put('counter', {'value': 2});
        await Future.delayed(const Duration(milliseconds: 50));
        buf.writeln('  Total events: ${events.length}');

        // Delete → signal fires
        buf.writeln('\n--- Deleting data ---');
        await box.delete('user');
        await Future.delayed(const Duration(milliseconds: 50));
        buf.writeln('  Total events: ${events.length}');

        // Live query as reactive signal
        buf.writeln('\n--- Live Query as Reactive Signal ---');
        final liveQuery = LiveQuery<Map>(
          box: box,
          execute: () => box.query().where('value', greaterThan: 0).findAll(),
        );
        final queryResults = <List<Map>>[];
        liveQuery.stream.listen((results) {
          queryResults.add(results);
        });

        await box.put('counter', {'value': 5});
        await Future.delayed(const Duration(milliseconds: 100));

        buf.writeln('  Live query updates: ${queryResults.length}');

        sub.cancel();
        liveQuery.dispose();

        buf.writeln('\n--- Signal Patterns ---');
        buf.writeln('  ✅ box.watch() → Stream<BoxEvent>');
        buf.writeln('  ✅ LiveQuery → Stream<List<E>>');
        buf.writeln('  ✅ CDC → Stream<CDCEvent>');
        buf.writeln('  ✅ AuditLog → Stream<AuditEntry>');
        buf.writeln('  ✅ Sync → Stream<SyncEvent>');

        await box.close();
        return buf.toString();
      },
    );
  }
}
