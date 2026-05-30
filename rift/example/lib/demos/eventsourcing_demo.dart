import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class EventsourcingDemoPage extends StatelessWidget {
  const EventsourcingDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Event Sourcing',
      description: 'Append-only event store with projections and replay',
      codeExample:
          "final store = EventStore('orders');\nawait store.append('order_1', Event(type: 'created', data: {...}));\nfinal state = await store.project('order_1', projection);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Event Sourcing Demo ===\n');

        final eventStore = EventStore<Map<String, dynamic>>('orders');

        // Append events
        buf.writeln('--- Append Events ---');
        await eventStore.append('order_1',
            Event(type: 'created', data: {'item': 'Book', 'qty': 2}));
        await eventStore.append('order_1',
            Event(type: 'item_added', data: {'item': 'Pen', 'qty': 5}));
        await eventStore.append(
            'order_1', Event(type: 'item_removed', data: {'item': 'Book'}));
        await eventStore.append('order_1',
            Event(type: 'quantity_changed', data: {'item': 'Pen', 'qty': 10}));
        buf.writeln('  Appended 4 events to order_1');

        // Event history
        buf.writeln('\n--- Event History ---');
        final events = eventStore.getEvents('order_1');
        for (final e in events) {
          buf.writeln('  v${e.version} ${e.type}: ${e.data}');
        }

        // Projection
        buf.writeln('\n--- Project Current State ---');
        final projection = MapProjection({
          'created': (state, event) {
            return {
              'items': {event.data['item']: event.data['qty']}
            };
          },
          'item_added': (state, event) {
            final items = Map<String, dynamic>.from(state['items'] ?? {});
            items[event.data['item']] = event.data['qty'];
            return {'items': items};
          },
          'item_removed': (state, event) {
            final items = Map<String, dynamic>.from(state['items'] ?? {});
            items.remove(event.data['item']);
            return {'items': items};
          },
          'quantity_changed': (state, event) {
            final items = Map<String, dynamic>.from(state['items'] ?? {});
            items[event.data['item']] = event.data['qty'];
            return {'items': items};
          },
        });
        final state = await eventStore.project('order_1', projection);
        buf.writeln('  Current state: $state');

        // Replay events up to version
        buf.writeln('\n--- Replay up to v2 ---');
        final partialState = EventReplay.replayUpTo(events, projection, 2);
        buf.writeln('  State at v2: $partialState');

        // Snapshot
        buf.writeln('\n--- Create Snapshot ---');
        await eventStore.createSnapshot('order_1', projection);
        buf.writeln('  Snapshot created');

        // Event stream
        buf.writeln('\n--- Event Store Stats ---');
        buf.writeln('  Stream count: ${eventStore.streamCount}');
        buf.writeln('  Events in order_1: ${eventStore.eventCount('order_1')}');
        buf.writeln('  Current version: ${eventStore.getVersion('order_1')}');
        buf.writeln('  Stream IDs: ${eventStore.streamIds.toList()}');

        // Events from version
        buf.writeln('\n--- Events from v3 ---');
        final fromV3 = eventStore.getEventsFrom('order_1', 3);
        for (final e in fromV3) {
          buf.writeln('  v${e.version} ${e.type}: ${e.data}');
        }

        eventStore.dispose();
        return buf.toString();
      },
    );
  }
}
