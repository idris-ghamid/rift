import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class CodecDemoPage extends StatelessWidget {
  const CodecDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Codec Mode',
      description: 'No-codegen codec mode for serialization',
      codeExample:
          "// Store maps directly (no codegen needed)\nawait box.put('key', {'name': 'Alice', 'age': 30});\n\n// BinaryWriter / BinaryReader for custom serialization",
      runDemo: () async {
        final box = await Rift.openBox<Map>('codec_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Codec Mode (No Codegen) Demo ===\n');

        buf.writeln('Rift supports a no-codegen mode where you can store');
        buf.writeln(
            'Map<String, dynamic> directly without generated adapters.\n');

        // Store maps directly
        await box.putAll({
          'p1': {
            'name': 'Widget',
            'price': 25.99,
            'tags': ['tool', 'handy']
          },
          'p2': {'name': 'Gadget', 'price': 99.99, 'inStock': true},
          'p3': {
            'name': 'Doohickey',
            'price': 4.50,
            'metadata': {'color': 'red'}
          },
        });
        buf.writeln('--- Stored Maps Directly ---');
        for (final k in box.keys) {
          buf.writeln('  $k => ${box.get(k)}');
        }

        // Binary writer/reader for custom serialization
        buf.writeln('\n--- Binary Writer/Reader ---');
        final writer = BinaryWriterImpl(Rift);
        writer.writeByte(1);
        writer.writeInt(42);
        writer.writeString('Hello Rift');
        writer.writeDouble(3.14);
        final bytes = Uint8List.fromList(writer.toBytes());
        buf.writeln(
            '  Written: byte=1, int=42, string="Hello Rift", double=3.14');
        buf.writeln('  Total bytes: ${bytes.length}');

        final reader = BinaryReaderImpl(bytes, Rift);
        final byte = reader.readByte();
        final intVal = reader.readInt();
        final strVal = reader.readString();
        final dblVal = reader.readDouble();
        buf.writeln(
            '  Read back: byte=$byte, int=$intVal, string="$strVal", double=${dblVal.toStringAsFixed(2)}');

        // Type registry
        buf.writeln('\n--- Type Registry ---');
        buf.writeln(
            '  Registered adapters: ${Rift.isAdapterRegistered(0)} (default)');
        buf.writeln('  Use Rift.registerAdapter() for custom types');
        buf.writeln('  RecordAdapter for Dart 3 records');

        // Record adapter
        buf.writeln('\n--- Dart 3 Records ---');
        buf.writeln('  RecordAdapter supports tuple serialization');
        buf.writeln('  Example: ("Alice", 30) → serialized pair');

        await box.close();
        return buf.toString();
      },
    );
  }
}
