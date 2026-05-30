import 'dart:async';

import 'package:rift/src/box/box.dart';

/// Bloc/Cubit integration for Rift boxes.
/// Provides base classes for creating Bloc-compatible state from Rift boxes.
///
/// Usage:
/// ```dart
/// final box = await Rift.openBox('settings');
/// final cubit = RiftBoxCubit<Settings>(box);
///
/// // Read current state
/// print(cubit.state); // {theme: dark, lang: en}
///
/// // React to changes
/// cubit.stream.listen((state) {
///   print('Settings changed: $state');
/// });
///
/// // Modify data
/// await cubit.put('theme', 'light');
/// ```

/// Base cubit-like class for a Rift box.
///
/// This wraps a Rift [Box] and exposes it as a reactive state object
/// compatible with the Bloc/Cubit pattern. It provides:
/// - A synchronous [state] getter returning the current box contents as a Map
/// - A [stream] that emits the full box state on every change
/// - Convenience methods for [put], [delete], and [clear]
///
/// The class does NOT depend on any Bloc library directly, making it
/// easy to integrate with any Bloc implementation or as a standalone
/// reactive state container.
class RiftBoxCubit<T> {
  final Box _box;
  final StreamController<Map<dynamic, dynamic>> _stateController =
      StreamController.broadcast();
  StreamSubscription? _subscription;

  /// Create a [RiftBoxCubit] wrapping the given [box].
  RiftBoxCubit(this._box) {
    _subscription = _box.watch().listen((_) {
      if (!_stateController.isClosed) {
        _stateController.add(_box.toMap());
      }
    });
  }

  /// The current state of the box as a Map.
  Map<dynamic, dynamic> get state => _box.toMap();

  /// A stream of box state changes.
  ///
  /// Emits the full box contents as a Map every time any value changes.
  Stream<Map<dynamic, dynamic>> get stream => _stateController.stream;

  /// Put a value at the given [key].
  Future<void> put(dynamic key, dynamic value) => _box.put(key, value);

  /// Delete the value at the given [key].
  Future<void> delete(dynamic key) => _box.delete(key);

  /// Clear all entries from the box.
  Future<int> clear() => _box.clear();

  /// Get a value from the box by [key].
  dynamic get(dynamic key) => _box.get(key);

  /// Check if the box contains [key].
  bool containsKey(dynamic key) => _box.containsKey(key);

  /// Get all keys in the box.
  Iterable<dynamic> get keys => _box.keys;

  /// The number of entries in the box.
  int get length => _box.length;

  /// Dispose of the cubit, canceling the watch subscription and
  /// closing the state stream controller.
  void dispose() {
    _subscription?.cancel();
    _stateController.close();
  }
}
