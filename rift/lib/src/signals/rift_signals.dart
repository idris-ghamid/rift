import 'dart:async';

import 'package:rift/src/box/box.dart';

/// Reactive signals integration for Rift.
/// Creates reactive signals from box values that auto-update on data changes.
///
/// The signals system provides a lightweight reactive primitive that can be
/// used with any UI framework. Each signal wraps a value and notifies
/// listeners when the value changes.
///
/// Usage:
/// ```dart
/// final factory = RiftSignalFactory();
///
/// // Create a signal for a specific key
/// final nameSignal = factory.forKey<String>(box, 'user_name');
/// nameSignal.listen((name) => print('Name changed to: $name'));
///
/// // Create a signal for the entire box
/// final boxSignal = factory.forBox(box);
/// boxSignal.listen((state) => print('Box changed: $state'));
///
/// // Clean up
/// factory.disposeAll();
/// ```

/// A reactive signal that holds a value and notifies listeners on change.
///
/// Signals are the fundamental reactive primitive. They hold a single
/// value and emit updates through both a [Stream] and direct listener
/// callbacks.
///
/// Value equality is used to prevent unnecessary notifications: if the
/// new value is equal to the current value (using `==`), no notification
/// is emitted.
class RiftSignal<T> {
  T _value;
  final StreamController<T> _controller = StreamController.broadcast();
  final Set<void Function(T)> _listeners = {};

  /// Create a [RiftSignal] with an initial [value].
  RiftSignal(this._value);

  /// The current value of the signal.
  T get value => _value;

  /// A stream of value changes.
  Stream<T> get stream => _controller.stream;

  /// Set a new value for the signal.
  ///
  /// If [newValue] is different from the current value (using `==`),
  /// listeners are notified. If the value is the same, nothing happens.
  void set(T newValue) {
    if (newValue != _value) {
      _value = newValue;
      if (!_controller.isClosed) {
        _controller.add(newValue);
      }
      for (final listener in _listeners.toList()) {
        listener(newValue);
      }
    }
  }

  /// Register a [listener] that is called when the value changes.
  void listen(void Function(T) listener) {
    _listeners.add(listener);
  }

  /// Remove a previously registered [listener].
  void removeListener(void Function(T) listener) {
    _listeners.remove(listener);
  }

  /// Dispose of the signal, closing the stream and clearing listeners.
  void dispose() {
    _controller.close();
    _listeners.clear();
  }

  /// Whether the signal has been disposed.
  bool get isDisposed => _controller.isClosed;
}

/// Factory for creating signals from Rift boxes.
///
/// The factory manages signal lifecycle and ensures that only one signal
/// is created per box key. If a signal for a key already exists, the
/// existing signal is returned.
///
/// Signals created by the factory automatically subscribe to box change
/// events and update their values when the underlying box data changes.
class RiftSignalFactory {
  final Map<String, RiftSignal> _signals = {};

  /// Create or get a signal for a specific [key] in a [box].
  ///
  /// The signal's value is initialized from the current box value
  /// and automatically updates when the key's value changes.
  ///
  /// The signal is identified by `{box.name}:{key}`, so calling this
  /// method multiple times with the same box and key returns the same
  /// signal instance.
  RiftSignal<T?> forKey<T>(Box box, String key) {
    final signalId = '${box.name}:$key';
    if (_signals.containsKey(signalId)) {
      return _signals[signalId] as RiftSignal<T?>;
    }

    final signal = RiftSignal<T?>(box.get(key) as T?);
    box.watch(key: key).listen((event) {
      if (event.deleted) {
        signal.set(null);
      } else {
        signal.set(event.value as T?);
      }
    });
    _signals[signalId] = signal;
    return signal;
  }

  /// Create a signal that tracks the entire box state.
  ///
  /// The signal's value is initialized from the current box contents
  /// and automatically updates when any value in the box changes.
  RiftSignal<Map<dynamic, dynamic>> forBox(Box box) {
    final signalId = '${box.name}:__all__';
    if (_signals.containsKey(signalId)) {
      return _signals[signalId] as RiftSignal<Map<dynamic, dynamic>>;
    }

    final signal = RiftSignal<Map<dynamic, dynamic>>(box.toMap());
    box.watch().listen((_) {
      signal.set(box.toMap());
    });
    _signals[signalId] = signal;
    return signal;
  }

  /// Dispose a specific signal by its [signalId].
  ///
  /// The signal is removed from the factory and its resources are released.
  void dispose(String signalId) {
    _signals.remove(signalId)?.dispose();
  }

  /// Dispose all managed signals.
  ///
  /// Removes all signals from the factory and releases their resources.
  void disposeAll() {
    for (final s in _signals.values) {
      s.dispose();
    }
    _signals.clear();
  }

  /// Check if a signal with the given [signalId] exists.
  bool hasSignal(String signalId) => _signals.containsKey(signalId);

  /// Get the number of active signals.
  int get signalCount => _signals.length;

  /// Get all signal IDs.
  Iterable<String> get signalIds => _signals.keys;
}
