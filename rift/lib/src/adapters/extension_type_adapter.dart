import 'package:rift/src/binary/binary_reader.dart';
import 'package:rift/src/binary/binary_writer.dart';
import 'package:rift/src/registry/type_adapter.dart';

/// Support for Dart 3 extension types as Rift-storable values.
/// Extension types provide zero-cost type wrappers with full type safety.
///
/// Dart 3 extension types allow creating new types that wrap existing
/// primitives without runtime overhead. This adapter enables storing
/// extension type values in Rift boxes by serializing their underlying
/// primitive representation.
///
/// Usage:
/// ```dart
/// // Define an extension type
/// extension type UserId(String value) {}
///
/// // Create an adapter for it
/// final userIdAdapter = ExtensionTypeAdapter<UserId>(
///   typeId: 100,
///   fromPrimitive: (value) => UserId(value as String),
///   toPrimitive: (userId) => userId.value,
/// );
///
/// // Register the adapter
/// Rift.registerAdapter(userIdAdapter);
///
/// // Now you can store and retrieve UserId values
/// await box.put('current_user', UserId('abc123'));
/// final userId = box.get('current_user') as UserId;
/// ```
class ExtensionTypeAdapter<T> extends TypeAdapter<T> {
  @override
  final int typeId;

  /// Function that constructs an extension type from its primitive value.
  ///
  /// This is called during deserialization to wrap the primitive back
  /// into the extension type.
  final T Function(dynamic) fromPrimitive;

  /// Function that extracts the primitive value from an extension type.
  ///
  /// This is called during serialization to unwrap the extension type
  /// into its underlying primitive representation.
  final dynamic Function(T) toPrimitive;

  /// Create an [ExtensionTypeAdapter] with the given [typeId],
  /// [fromPrimitive], and [toPrimitive] functions.
  ExtensionTypeAdapter({
    required this.typeId,
    required this.fromPrimitive,
    required this.toPrimitive,
  });

  @override
  T read(BinaryReader reader) {
    return fromPrimitive(reader.read());
  }

  @override
  void write(BinaryWriter writer, T obj) {
    writer.write(toPrimitive(obj));
  }
}
