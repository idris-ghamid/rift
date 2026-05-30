import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class TestingDemoPage extends StatelessWidget {
  const TestingDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Testing Utilities',
      description:
          'Testing utilities with RiftTestUtil and MockBox for easy testing',
      codeExample:
          "// Create in-memory test box with seed data\nfinal box = await RiftTestUtil.createTestBox('test',\n  seedData: {'key': {'name': 'Alice'}});\n\n// Mock box for unit tests (no disk I/O)\nfinal mock = MockBox<Map>(name: 'mock');\nmock.seed({'key': {'data': 42}});",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Testing Utilities Demo ===\n');

        buf.writeln(
            'Rift provides RiftTestUtil and MockBox for easy testing.\n');

        // CreateTestBox with seed data
        buf.writeln('--- Step 1: Create Test Box with Seed Data ---');
        final testBox = await RiftTestUtil.createTestBox<Map>(
          'test_demo',
          seedData: {
            'user1': {'name': 'Alice', 'age': 30},
            'user2': {'name': 'Bob', 'age': 25},
            'user3': {'name': 'Charlie', 'age': 35},
          },
        );
        buf.writeln('  RiftTestUtil.createTestBox() with 3 seed entries');
        buf.writeln('  box.length = ${testBox.length}');
        for (final k in testBox.keys) {
          buf.writeln('    $k => ${testBox.get(k)}');
        }
        buf.writeln('');

        // Assertions
        buf.writeln('--- Step 2: Assert Box Contents ---');
        try {
          RiftTestUtil.expectBoxContains(testBox, {
            'user1': {'name': 'Alice', 'age': 30},
            'user2': {'name': 'Bob', 'age': 25},
          });
          buf.writeln('  ✅ expectBoxContains() passed — data matches');
        } catch (e) {
          buf.writeln('  ❌ expectBoxContains() failed: $e');
        }

        try {
          RiftTestUtil.expectBoxLength(testBox, 3);
          buf.writeln('  ✅ expectBoxLength(box, 3) passed');
        } catch (e) {
          buf.writeln('  ❌ expectBoxLength() failed: $e');
        }

        try {
          RiftTestUtil.expectBoxHasKey(testBox, 'user1');
          buf.writeln('  ✅ expectBoxHasKey(box, "user1") passed');
        } catch (e) {
          buf.writeln('  ❌ expectBoxHasKey() failed: $e');
        }

        try {
          RiftTestUtil.expectBoxDoesNotHaveKey(testBox, 'user99');
          buf.writeln('  ✅ expectBoxDoesNotHaveKey(box, "user99") passed');
        } catch (e) {
          buf.writeln('  ❌ expectBoxDoesNotHaveKey() failed: $e');
        }
        buf.writeln('');

        // CreateSeededBox
        buf.writeln('--- Step 3: Create Seeded Box with Generator ---');
        final seededBox = await RiftTestUtil.createSeededBox<Map>(
          'seeded_demo',
          5,
          (index) => {'id': index, 'value': 'item_$index'},
        );
        buf.writeln('  Created box with 5 generated entries');
        buf.writeln('  box.length = ${seededBox.length}');
        for (final k in seededBox.keys) {
          buf.writeln('    $k => ${seededBox.get(k)}');
        }
        buf.writeln('');

        // MockBox
        buf.writeln('--- Step 4: MockBox (No Real Database) ---');
        final mockBox = MockBox<Map>(name: 'mock_test');
        buf.writeln('  Created MockBox(name: "mock_test")');
        buf.writeln('  mockBox.isOpen = ${mockBox.isOpen}');
        buf.writeln('  mockBox.path = ${mockBox.path ?? "(no disk path)"}');
        buf.writeln('');

        // Seed mock box
        mockBox.seed({
          'config': {'theme': 'dark', 'lang': 'ar'},
        });
        buf.writeln('  Seeded mock box with config data');
        buf.writeln('  mockBox.get("config") = ${mockBox.get("config")}');
        buf.writeln('');

        // Put and get
        await mockBox.put('token', {'access': 'abc123', 'refresh': 'xyz789'});
        buf.writeln('  Put token into mock box');
        buf.writeln('  mockBox.get("token") = ${mockBox.get("token")}');
        buf.writeln('  mockBox.length = ${mockBox.length}');
        buf.writeln('');

        // Watch on mock box
        buf.writeln('--- Step 5: MockBox Watch Events ---');
        final mockEvents = <BoxEvent>[];
        final sub = mockBox.watch().listen((event) {
          mockEvents.add(event);
        });
        await mockBox.put('session', {'active': true});
        await mockBox.delete('config');
        buf.writeln('  Put "session" and deleted "config"');
        buf.writeln('  Events captured: ${mockEvents.length}');
        for (final e in mockEvents) {
          buf.writeln('    key=${e.key}, deleted=${e.deleted}');
        }
        await sub.cancel();
        buf.writeln('');

        // Clean up
        buf.writeln('--- Step 6: Clean Up ---');
        await RiftTestUtil.cleanUp(['test_demo', 'seeded_demo']);
        buf.writeln('  RiftTestUtil.cleanUp() — deleted test boxes from disk');

        buf.writeln('\n--- Testing API Summary ---');
        buf.writeln('  ✅ RiftTestUtil.createTestBox(name, seedData:)');
        buf.writeln('  ✅ RiftTestUtil.createSeededBox(name, count, generator)');
        buf.writeln('  ✅ RiftTestUtil.expectBoxContains(box, expected)');
        buf.writeln('  ✅ RiftTestUtil.expectBoxLength(box, length)');
        buf.writeln('  ✅ RiftTestUtil.expectBoxHasKey(box, key)');
        buf.writeln('  ✅ RiftTestUtil.expectBoxDoesNotHaveKey(box, key)');
        buf.writeln('  ✅ RiftTestUtil.cleanUp(boxNames)');
        buf.writeln('  ✅ MockBox<E> — full Box<E> interface, no disk I/O');
        buf.writeln('  ✅ MockBox.seed(data) — pre-populate');
        buf.writeln('  ✅ MockBox.watch() — emits BoxEvents');

        await testBox.close();
        await seededBox.close();
        return buf.toString();
      },
    );
  }
}
