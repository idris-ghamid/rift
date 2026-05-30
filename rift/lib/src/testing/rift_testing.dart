import 'dart:async';

import 'package:rift/rift.dart';

/// Testing utilities for Rift database.
/// Makes it easy to write unit and integration tests.
class RiftTestUtil {
  /// Create an in-memory box for testing.
  /// Optionally seed it with [seedData].
  static Future<Box<E>> createTestBox<E>(
    String name, {
    Map<dynamic, E>? seedData,
  }) async {
    Rift.init('');
    final box = await Rift.openBox<E>(name);
    if (seedData != null) {
      await box.putAll(seedData);
    }
    return box;
  }

  /// Create a box pre-filled with test data.
  /// [count] items are generated using [generator].
  static Future<Box<E>> createSeededBox<E>(
    String name,
    int count,
    E Function(int index) generator,
  ) async {
    Rift.init('');
    final box = await Rift.openBox<E>(name);
    for (int i = 0; i < count; i++) {
      await box.put(i, generator(i));
    }
    return box;
  }

  /// Clean up all test boxes by deleting them from disk.
  static Future<void> cleanUp(List<String> boxNames) async {
    for (final name in boxNames) {
      try {
        await Rift.deleteBoxFromDisk(name);
      } catch (_) {
        // Ignore errors during cleanup
      }
    }
  }

  /// Assert that a box contains specific data.
  /// Throws an exception if any key-value pair doesn't match.
  static void expectBoxContains(Box box, Map<dynamic, dynamic> expected) {
    for (final entry in expected.entries) {
      final actual = box.get(entry.key);
      if (actual != entry.value) {
        throw AssertionError(
          'Box key "${entry.key}": expected ${entry.value}, got $actual',
        );
      }
    }
  }

  /// Assert that a box has a specific number of entries.
  static void expectBoxLength(Box box, int expectedLength) {
    if (box.length != expectedLength) {
      throw AssertionError(
        'Box length: expected $expectedLength, got ${box.length}',
      );
    }
  }

  /// Assert that a box contains a specific key.
  static void expectBoxHasKey(Box box, dynamic key) {
    if (!box.containsKey(key)) {
      throw AssertionError('Box should contain key: $key');
    }
  }

  /// Assert that a box does not contain a specific key.
  static void expectBoxDoesNotHaveKey(Box box, dynamic key) {
    if (box.containsKey(key)) {
      throw AssertionError('Box should not contain key: $key');
    }
  }
}

/// Mock Box for unit testing without a real database.
/// All data is stored in memory.
class MockBox<E> implements Box<E> {
  final Map<String, E> _data = {};
  final StreamController<BoxEvent> _changeController =
      StreamController.broadcast();
  String _name;

  /// Create a mock box with an optional name.
  MockBox({String name = 'mock_box'}) : _name = name;

  @override
  E? get(dynamic key, {E? defaultValue}) =>
      _data[key.toString()] ?? defaultValue;

  @override
  Future<void> put(dynamic key, E value) async {
    final keyStr = key.toString();
    final old = _data[keyStr];
    _data[keyStr] = value;
    _changeController.add(BoxEvent(key, value, old == null));
  }

  @override
  Future<void> delete(dynamic key) async {
    final keyStr = key.toString();
    _data.remove(keyStr);
    _changeController.add(BoxEvent(key, null, false));
  }

  @override
  Iterable<dynamic> get keys => _data.keys;

  @override
  int get length => _data.length;

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  Stream<BoxEvent> watch({dynamic key}) {
    if (key != null) {
      return _changeController.stream.where((e) => e.key == key);
    }
    return _changeController.stream;
  }

  @override
  String get name => _name;

  @override
  bool get isOpen => true;

  @override
  bool containsKey(dynamic key) => _data.containsKey(key.toString());

  @override
  E? getAt(int index) {
    if (index < 0 || index >= _data.length) return null;
    return _data.values.elementAt(index);
  }

  @override
  Future<void> putAll(Map<dynamic, E> entries) async {
    for (final entry in entries.entries) {
      _data[entry.key.toString()] = entry.value;
      _changeController.add(BoxEvent(entry.key, entry.value, true));
    }
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    for (final key in keys) {
      _data.remove(key.toString());
      _changeController.add(BoxEvent(key, null, false));
    }
  }

  @override
  Future<int> clear() async {
    final count = _data.length;
    _data.clear();
    return count;
  }

  @override
  Future<void> compact() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> flush() async {}

  @override
  Future<void> deleteFromDisk() async {
    _data.clear();
  }

  @override
  Map<dynamic, E> toMap() => Map<dynamic, E>.from(_data);

  @override
  Iterable<E> get values => _data.values;

  @override
  Iterable<E> valuesBetween({dynamic startKey, dynamic endKey}) {
    if (startKey == null) return values;
    final startStr = startKey.toString();
    final endStr = endKey?.toString();
    final result = <E>[];
    bool inRange = false;
    final sortedKeys = _data.keys.toList()..sort();
    for (final key in sortedKeys) {
      if (key == startStr) inRange = true;
      if (inRange) {
        result.add(_data[key] as E);
      }
      if (endStr != null && key == endStr) break;
    }
    return result;
  }

  @override
  dynamic keyAt(int index) {
    if (index < 0 || index >= _data.length) return null;
    return _data.keys.elementAt(index);
  }

  @override
  Future<void> putAt(int index, E value) async {
    final key = keyAt(index);
    if (key != null) {
      await put(key, value);
    }
  }

  @override
  Future<int> add(E value) async {
    final key = _data.length;
    await put(key, value);
    return key;
  }

  @override
  Future<Iterable<int>> addAll(Iterable<E> values) async {
    final keys = <int>[];
    for (final value in values) {
      keys.add(await add(value));
    }
    return keys;
  }

  @override
  Future<void> deleteAt(int index) async {
    final key = keyAt(index);
    if (key != null) {
      await delete(key);
    }
  }

  @override
  String? get path => null;

  @override
  bool get lazy => false;

  /// Set the box name (for testing).
  set name(String value) => _name = value;

  @override
  RiftQuery<E> query() {
    throw UnimplementedError('MockBox does not support query()');
  }

  /// Direct access to the underlying data map (for testing).
  Map<String, E> get data => _data;

  /// Seed the mock box with data.
  void seed(Map<dynamic, E> data) {
    for (final entry in data.entries) {
      _data[entry.key.toString()] = entry.value;
    }
  }
}
