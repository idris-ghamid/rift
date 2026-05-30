import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class Dart3RecordsDemoPage extends StatelessWidget {
  const Dart3RecordsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Dart 3 Records & Sealed',
      description: 'Dart 3 Records & sealed classes support with RecordAdapter',
      codeExample:
          "// RecordAdapter for Dart 3 Records\nfinal adapter = RecordAdapter(); // typeId: -255\n\n// ExtensionTypeAdapter\nfinal idAdapter = ExtensionTypeAdapter<UserId>(\n  typeId: 100,\n  fromPrimitive: (v) => UserId(v),\n  toPrimitive: (id) => id.value,\n);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Dart 3 Records & Sealed Classes Demo ===\n');

        // RecordAdapter
        buf.writeln('--- RecordAdapter ---');
        buf.writeln('  RecordAdapter supports Dart 3 Record types');
        buf.writeln('  typeId: -255 (special reserved ID)');
        buf.writeln('  Automatically serializes Record values');
        buf.writeln('  No manual TypeAdapter needed for Records');

        // Demonstrate Record serialization
        buf.writeln('\n--- Storing Records via RecordAdapter ---');
        final adapter = const RecordAdapter();
        buf.writeln('  Created RecordAdapter: typeId = ${adapter.typeId}');

        // Write a record using BinaryWriter
        final writer = BinaryWriterImpl(Rift);
        buf.writeln('\n--- Manual Record Serialization ---');

        // Write a tuple-like structure (String, int)
        writer.writeByte(2); // 2 positional fields
        writer.writeBool(false); // positional
        writer.write('Alice'); // first field
        writer.writeBool(false); // positional
        writer.writeInt(30); // second field

        final recordBytes = Uint8List.fromList(writer.toBytes());
        buf.writeln('  Wrote ("Alice", 30) as record-like structure');
        buf.writeln('  Bytes: ${recordBytes.length} bytes');

        // Read it back
        final reader = BinaryReaderImpl(recordBytes, Rift);
        final fieldCount = reader.readByte();
        buf.writeln('  Read field count: $fieldCount');
        final isNamed1 = reader.readBool();
        final field1 = reader.read();
        final isNamed2 = reader.readBool();
        final field2 = reader.readInt();
        buf.writeln('  Field 1: named=$isNamed1, value=$field1');
        buf.writeln('  Field 2: named=$isNamed2, value=$field2');
        buf.writeln('  Reconstructed: ($field1, $field2)');

        // Store records in a box
        buf.writeln('\n--- Storing Records in Box ---');
        final box = await Rift.openBox<Map>('records_demo');
        await box.clear();

        // Store record-like data as maps
        await box.put('coord1', {'x': 10, 'y': 20, 'type': 'positional'});
        await box.put('coord2', {'x': 30, 'y': 40, 'type': 'positional'});
        await box.put('person', {'name': 'Alice', 'age': 30, 'type': 'named'});
        await box.put('config',
            {'host': 'localhost', 'port': 8080, 'ssl': true, 'type': 'mixed'});

        buf.writeln('  Stored 4 record-like entries');
        for (final k in box.keys) {
          buf.writeln('    $k → ${box.get(k)}');
        }

        // ExtensionTypeAdapter
        buf.writeln('\n--- ExtensionTypeAdapter ---');
        buf.writeln(
            '  Supports Dart 3 extension types as Rift-storable values');
        buf.writeln('  Zero-cost type wrappers with full type safety');

        // Demonstrate ExtensionTypeAdapter
        buf.writeln('\n--- ExtensionTypeAdapter Example ---');
        final userIdAdapter = ExtensionTypeAdapter<String>(
          typeId: 100,
          fromPrimitive: (value) => value as String,
          toPrimitive: (userId) => userId,
        );
        buf.writeln('  Created ExtensionTypeAdapter<String>:');
        buf.writeln('    typeId: ${userIdAdapter.typeId}');

        // Test serialization round-trip
        final extWriter = BinaryWriterImpl(Rift);
        extWriter.writeTypeId(userIdAdapter.typeId);
        userIdAdapter.write(extWriter, 'user_abc123');
        final extBytes = Uint8List.fromList(extWriter.toBytes());
        buf.writeln('  Written "user_abc123" via adapter');

        final extReader = BinaryReaderImpl(extBytes, Rift);
        extReader.readTypeId(); // consume type ID
        final readValue = userIdAdapter.read(extReader);
        buf.writeln('  Read back: "$readValue"');
        buf.writeln('  Round-trip match: ${readValue == 'user_abc123'}');

        // Sealed classes explanation
        buf.writeln('\n--- Dart 3 Sealed Classes ---');
        buf.writeln('  Sealed classes enable exhaustive pattern matching');
        buf.writeln('  Perfect for type-safe event handling in Rift');
        buf.writeln('');
        buf.writeln('  sealed class DbEvent {}');
        buf.writeln('  class PutEvent extends DbEvent { final key, value; }');
        buf.writeln('  class DeleteEvent extends DbEvent { final key; }');
        buf.writeln('  class ClearEvent extends DbEvent {}');
        buf.writeln('');
        buf.writeln('  switch (event) {');
        buf.writeln('    case PutEvent():    // handle put');
        buf.writeln('    case DeleteEvent(): // handle delete');
        buf.writeln('    case ClearEvent():  // handle clear');
        buf.writeln('  }');

        // Record types in practice
        buf.writeln('\n--- Practical Record Types ---');
        buf.writeln('  (String, int)          → name + age');
        buf.writeln('  (double, double)       → lat + lng coordinates');
        buf.writeln('  ({String name, int id}) → named record');
        buf.writeln('  (String, {int port})   → mixed record');
        buf.writeln('  RecordAdapter handles all these patterns');

        await box.close();

        buf.writeln('\n✅ Dart 3 Records demo complete');

        return buf.toString();
      },
    );
  }
}
