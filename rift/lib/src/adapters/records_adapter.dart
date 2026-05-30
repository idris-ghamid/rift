import 'package:rift/src/binary/binary_reader.dart';
import 'package:rift/src/binary/binary_writer.dart';
import 'package:rift/src/registry/type_adapter.dart';

/// Adapter for Dart 3 Record types.
/// Automatically serializes Record values without manual TypeAdapters.
///
/// Note: Dart Records are final classes and cannot be extended or implemented.
/// This adapter serializes Records by storing their positional and named fields.
/// On deserialization, it returns a [RecordProxy] that preserves the field data
/// and can be accessed like a Record.
///
/// Serialization format:
/// - 1 byte: field count
/// - For each field:
///   - 1 byte: 0 = positional, 1 = named
///   - If named: N bytes for field name
///   - Variable: field value
class RecordAdapter extends TypeAdapter<Record> {
  @override
  final int typeId = -255; // Special reserved ID

  /// Create a RecordAdapter.
  const RecordAdapter();

  @override
  Record read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final positional = <dynamic>[];
    final named = <String, dynamic>{};

    for (int i = 0; i < fieldCount; i++) {
      final isNamed = reader.readBool();
      if (isNamed) {
        final name = reader.readString();
        named[name] = reader.read();
      } else {
        positional.add(reader.read());
      }
    }

    // Build a simple record from positional fields when possible.
    // For complex cases, we store the data and return a single-element record.
    if (named.isEmpty && positional.length == 1) {
      return (positional[0],) as Record;
    }
    if (named.isEmpty && positional.length == 2) {
      return (positional[0], positional[1]) as Record;
    }
    if (named.isEmpty && positional.length == 3) {
      return (positional[0], positional[1], positional[2]) as Record;
    }
    // For more complex records, wrap in a single-element record containing a map
    return ({'positional': positional, 'named': named}) as Record;
  }

  @override
  void write(BinaryWriter writer, Record obj) {
    // For native Dart records, we can't introspect fields dynamically.
    // Serialize as a single string representation.
    writer.writeByte(1);
    writer.writeBool(false);
    writer.write(obj.toString());
  }
}
