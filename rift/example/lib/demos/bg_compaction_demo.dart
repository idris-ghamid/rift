import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class BgCompactionDemoPage extends StatelessWidget {
  const BgCompactionDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Background Compaction',
      description: 'Background compaction without blocking reads',
      codeExample:
          "final compactor = BackgroundCompactor(\n  {'box': myBox}, interval: Duration(minutes: 5));\ncompactor.start();\ncompactor.events.listen((e) => print(e.boxName));",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Background Compaction Demo ===\n');

        buf.writeln('BackgroundCompactor runs compaction on registered boxes');
        buf.writeln('at regular intervals without blocking reads.\n');

        // Open a box and add data
        buf.writeln('--- Step 1: Create Box with Data ---');
        final box = await Rift.openBox<Map>('compact_demo');
        await box.clear();
        for (int i = 0; i < 50; i++) {
          await box.put('key_$i', {'value': i});
        }
        buf.writeln('  Box: ${box.name}, entries: ${box.length}');
        buf.writeln('');

        // Simulate overwrites to create fragmentation
        buf.writeln('--- Step 2: Simulate Fragmentation ---');
        for (int i = 0; i < 30; i++) {
          await box.put('key_$i', {'value': i * 10, 'updated': true});
        }
        for (int i = 10; i < 20; i++) {
          await box.delete('key_$i');
        }
        buf.writeln('  Updated 30 keys, deleted 10 keys');
        buf.writeln('  Current entries: ${box.length}');
        buf.writeln('  → Fragmented data needs compaction');
        buf.writeln('');

        // Create the compactor
        buf.writeln('--- Step 3: Create BackgroundCompactor ---');
        final compactor = BackgroundCompactor(
          {'compact_demo': box},
          interval: const Duration(seconds: 3),
        );
        buf.writeln('  Created compactor with 3-second interval');
        buf.writeln(
            '  Registered boxes: ${compactor.registeredBoxNames.toList()}');
        buf.writeln('  isRunning: ${compactor.isRunning}');
        buf.writeln('');

        // Listen for events
        buf.writeln('--- Step 4: Listen for CompactionEvent ---');
        StreamSubscription<CompactionEvent>? eventSub;
        int eventCount = 0;
        eventSub = compactor.events.listen((event) {
          eventCount++;
          buf.writeln('  📦 CompactionEvent #$eventCount:');
          buf.writeln('     boxName: ${event.boxName}');
          buf.writeln('     duration: ${event.duration.inMilliseconds}ms');
          buf.writeln('     timestamp: ${event.timestamp}');
        });
        buf.writeln('  Subscribed to compaction.events stream');
        buf.writeln('');

        // Start the compactor
        buf.writeln('--- Step 5: Start Compactor ---');
        compactor.start();
        buf.writeln('  compactor.start() called');
        buf.writeln('  isRunning: ${compactor.isRunning}');
        buf.writeln(
            '  Compaction will run every ${compactor.interval.inSeconds}s');
        buf.writeln('');

        // Manual compact
        buf.writeln('--- Step 6: Manual Compact ---');
        await compactor.compactAll();
        buf.writeln('  compactor.compactAll() completed');
        buf.writeln('  compactionCount: ${compactor.compactionCount}');
        buf.writeln('');

        buf.writeln('--- Compactor API Summary ---');
        buf.writeln('  ✅ BackgroundCompactor(boxes, interval:) — create');
        buf.writeln('  ✅ start() / stop() — control auto-compaction');
        buf.writeln('  ✅ compactAll() / compactBox(name) — manual trigger');
        buf.writeln('  ✅ events → Stream<CompactionEvent>');
        buf.writeln('  ✅ registerBox(name, box) / unregisterBox(name)');
        buf.writeln('  ✅ updateInterval(duration) — change frequency');
        buf.writeln('  ✅ dispose() — clean up');

        buf.writeln('\n⏳ Compactor is running — events will appear above…');

        await eventSub.cancel();
        compactor.dispose();

        return buf.toString();
      },
    );
  }
}
