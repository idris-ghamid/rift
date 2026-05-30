import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class TimeTravelDemoPage extends StatelessWidget {
  const TimeTravelDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Time Travel',
      description: 'Time travel / undo via event sourcing',
      codeExample:
          "final tt = TimeTravel('myBox');\ntt.record(TimeTravelEventType.put, key, oldValue, newValue);\nfinal state = tt.reconstructAt(version);",
      runDemo: () async {
        final box = await Rift.openBox<Map>('tt_demo');
        await box.clear();
        final tt = TimeTravel('tt_demo');
        final buf = StringBuffer();
        buf.writeln('=== Time Travel Demo ===\n');

        // v0: initial state
        await tt.snapshotBox(box);
        buf.writeln('v0: Snapshot of empty box');

        // v1: add user1
        await box.put('user1', {'name': 'Alice', 'age': 30});
        tt.record(TimeTravelEventType.put, 'user1', null, box.get('user1'));
        buf.writeln('v1: PUT user1 → ${box.get('user1')}');

        // v2: add user2
        await box.put('user2', {'name': 'Bob', 'age': 25});
        tt.record(TimeTravelEventType.put, 'user2', null, box.get('user2'));
        buf.writeln('v2: PUT user2 → ${box.get('user2')}');

        // v3: modify user1
        final oldUser1 = box.get('user1');
        await box.put('user1', {'name': 'Alice', 'age': 31});
        tt.record(TimeTravelEventType.put, 'user1', oldUser1, box.get('user1'));
        buf.writeln('v3: PUT user1 (age 30→31)');

        // v4: delete user2
        tt.record(TimeTravelEventType.delete, 'user2', box.get('user2'), null);
        await box.delete('user2');
        buf.writeln('v4: DELETE user2');

        buf.writeln('\nCurrent box: ${box.toMap()}');
        buf.writeln('Events recorded: ${tt.eventCount}');
        buf.writeln('Snapshots: ${tt.snapshotCount}');

        // Reconstruct at different versions
        buf.writeln('\n--- Reconstruct at v1 ---');
        final v1 = tt.reconstructAt(1);
        buf.writeln('  State: $v1');

        buf.writeln('\n--- Reconstruct at v2 ---');
        final v2 = tt.reconstructAt(2);
        buf.writeln('  State: $v2');

        buf.writeln('\n--- Reconstruct at v3 ---');
        final v3 = tt.reconstructAt(3);
        buf.writeln('  State: $v3');

        buf.writeln('\n--- Event History ---');
        for (final event in tt.history) {
          buf.writeln('  ${event.toJson()}');
        }

        await box.close();
        return buf.toString();
      },
    );
  }
}
