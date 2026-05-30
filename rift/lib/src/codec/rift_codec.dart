import 'package:rift/src/box/box.dart';
import 'package:rift/src/box/box_base.dart';

/// No-codegen mode for Rift - simple codec-based serialization.
/// Allows using Rift without build_runner/code generation for simple use cases.

/// A codec that serializes/deserializes objects to/from maps.
abstract class RiftCodec<T> {
  /// Deserialize an object from a map representation.
  T fromMap(Map<String, dynamic> map);

  /// Serialize an object to a map representation.
  Map<String, dynamic> toMap(T value);
}

/// Built-in codec for Map<String, dynamic> (passthrough).
///
/// Useful when the data is already in map form and no transformation is needed.
class MapCodec extends RiftCodec<Map<String, dynamic>> {
  /// Create a [MapCodec].
  MapCodec();

  @override
  Map<String, dynamic> fromMap(Map<String, dynamic> map) => map;

  @override
  Map<String, dynamic> toMap(Map<String, dynamic> value) => value;
}

/// Codec for simple objects using field definitions.
///
/// Instead of code generation, you provide a constructor function and a map
/// of field accessors. This allows manual but type-safe serialization without
/// the build_runner overhead.
///
/// Usage:
/// ```dart
/// final codec = ReflectiveCodec<User>(
///   (map) => User(name: map['name'] as String, age: map['age'] as int),
///   {
///     'name': FieldAccessor<User>((u) => u.name),
///     'age': FieldAccessor<User>((u) => u.age),
///   },
/// );
/// ```
class ReflectiveCodec<T> extends RiftCodec<T> {
  /// Constructor function that creates a [T] from a map.
  final T Function(Map<String, dynamic>) constructor;

  /// Map of field names to their accessors.
  final Map<String, FieldAccessor<T>> fields;

  /// Create a [ReflectiveCodec] with a [constructor] and [fields].
  ReflectiveCodec(this.constructor, this.fields);

  @override
  T fromMap(Map<String, dynamic> map) {
    return constructor(map);
  }

  @override
  Map<String, dynamic> toMap(T value) {
    final result = <String, dynamic>{};
    for (final entry in fields.entries) {
      result[entry.key] = entry.value.getter(value);
    }
    return result;
  }
}

/// Accessor for a single field of an object.
///
/// Provides a getter to read the field value and an optional setter to
/// update it. The getter is used during serialization (toMap), while the
/// setter can be used for deserialization with mutable objects.
class FieldAccessor<T> {
  /// Function that extracts the field value from an object.
  final dynamic Function(T) getter;

  /// Optional function that sets the field value on an object.
  final void Function(T, dynamic)? setter;

  /// Create a [FieldAccessor] with a [getter] and optional [setter].
  FieldAccessor(this.getter, {this.setter});
}

/// Registry of codecs for different types.
///
/// Allows registering codecs by type and retrieving them later. This is
/// useful for applications that work with multiple types and need a central
/// place to manage their codecs.
///
/// Usage:
/// ```dart
/// final registry = CodecRegistry();
/// registry.register<User>(userCodec);
/// registry.register<Product>(productCodec);
///
/// final codec = registry.get<User>();
/// final typedBox = registry.createTypedBox<User>(box, codec);
/// ```
class CodecRegistry {
  final Map<Type, RiftCodec> _codecs = {};

  /// Register a codec for type [T].
  void register<T>(RiftCodec<T> codec) {
    _codecs[T] = codec;
  }

  /// Get the registered codec for type [T], or null if not registered.
  RiftCodec<T>? get<T>() => _codecs[T] as RiftCodec<T>?;

  /// Check if a codec is registered for type [T].
  bool has<T>() => _codecs.containsKey(T);

  /// Unregister the codec for type [T].
  void unregister<T>() {
    _codecs.remove(T);
  }

  /// Get all registered types.
  Iterable<Type> get registeredTypes => _codecs.keys;

  /// Create a typed box wrapper that uses codecs instead of generated adapters.
  ///
  /// The [box] must be a `Box<Map<String, dynamic>>` that stores the raw
  /// serialized map data. The [TypedBox] wrapper will automatically
  /// serialize and deserialize values using the provided [codec].
  TypedBox<T> createTypedBox<T>(
    Box<Map<String, dynamic>> box,
    RiftCodec<T> codec,
  ) {
    return TypedBox<T>(box, codec);
  }
}

/// A typed box wrapper that automatically serializes/deserializes using codecs.
///
/// This wraps a `Box<Map<String, dynamic>>` and provides a type-safe interface
/// for storing and retrieving objects of type [T]. All values are automatically
/// converted to/from map representation using the provided [RiftCodec].
///
/// Usage:
/// ```dart
/// final rawBox = await Rift.openBox('users');
/// final userCodec = ReflectiveCodec<User>(...);
/// final typedBox = TypedBox<User>(rawBox, userCodec);
///
/// await typedBox.put('user1', User(name: 'Alice', age: 30));
/// final user = typedBox.get('user1'); // Returns User instance
/// ```
class TypedBox<T> {
  final Box<Map<String, dynamic>> _box;
  final RiftCodec<T> _codec;

  /// Create a [TypedBox] wrapping [box] with the given [codec].
  TypedBox(this._box, this._codec);

  /// Get the value for [key], deserializing it using the codec.
  /// Returns null if the key does not exist.
  T? get(String key) {
    final map = _box.get(key);
    return map != null ? _codec.fromMap(map) : null;
  }

  /// Put a value at [key], serializing it using the codec.
  Future<void> put(String key, T value) async {
    await _box.put(key, _codec.toMap(value));
  }

  /// Put multiple entries, serializing each value using the codec.
  Future<void> putAll(Map<String, T> entries) async {
    final mapped = entries.map((k, v) => MapEntry(k, _codec.toMap(v)));
    await _box.putAll(mapped);
  }

  /// Get all values in the box, deserialized using the codec.
  List<T> get values => _box.values.map((v) => _codec.fromMap(v)).toList();

  /// Get all string keys in the box.
  Iterable<String> get keys => _box.keys.cast<String>();

  /// The number of entries in the box.
  int get length => _box.length;

  /// Delete the value at [key].
  Future<void> delete(String key) async => await _box.delete(key);

  /// Clear all entries from the box.
  Future<int> clear() async => await _box.clear();

  /// Check if the box contains [key].
  bool containsKey(String key) => _box.containsKey(key);

  /// Watch for changes on a specific key or all keys.
  Stream<BoxEvent> watch({String? key}) => _box.watch(key: key);

  /// Get the underlying raw box.
  Box<Map<String, dynamic>> get rawBox => _box;

  /// Get the codec used by this typed box.
  RiftCodec<T> get codec => _codec;
}
