import 'dart:async';
import 'dart:collection';

/// A reactive observable that wraps a value and notifies listeners on change.
///
/// [RiftObservable] is similar to MobX observables but designed for the
/// Rift ecosystem. It wraps any value and notifies all observers when
/// the value changes. Deep nested changes are supported through the
/// [ObservableMap] and [ObservableList] collections.
///
/// Usage:
/// ```dart
/// final name = RiftObservable<String>('Idris');
/// name.listen((newValue) => print('Name changed to: $newValue'));
/// name.set('Ahmed'); // Prints: Name changed to: Ahmed
/// ```
class RiftObservable<T> {
  T _value;
  final StreamController<T> _controller = StreamController.broadcast();
  final Set<void Function(T oldValue, T newValue)> _listeners = {};

  /// Creates a [RiftObservable] with an initial [value].
  RiftObservable(this._value);

  /// The current value of the observable.
  T get value => _value;

  /// A stream of value changes.
  Stream<T> get stream => _controller.stream;

  /// Sets a new value and notifies listeners if the value changed.
  ///
  /// Uses `==` comparison to avoid unnecessary notifications.
  /// Returns true if the value was changed (and listeners were notified).
  bool set(T newValue) {
    if (newValue == _value) return false;
    final oldValue = _value;
    _value = newValue;
    if (!_controller.isClosed) {
      _controller.add(newValue);
    }
    for (final listener in _listeners.toList()) {
      listener(oldValue, newValue);
    }
    return true;
  }

  /// Registers a [listener] called with old and new values on change.
  void listen(void Function(T oldValue, T newValue) listener) {
    _listeners.add(listener);
  }

  /// Removes a previously registered [listener].
  void removeListener(void Function(T oldValue, T newValue) listener) {
    _listeners.remove(listener);
  }

  /// Whether the observable has been disposed.
  bool get isDisposed => _controller.isClosed;

  /// Disposes of the observable, closing the stream and clearing listeners.
  void dispose() {
    _controller.close();
    _listeners.clear();
  }
}

/// Type of change that occurred in an [ObservableList].
enum ListChangeType { add, remove, insert, update, move, clear }

/// Describes a single change in an [ObservableList].
class ListChange<E> {
  /// The type of change.
  final ListChangeType type;

  /// The index affected by the change.
  final int? index;

  /// The element involved in the change.
  final E? element;

  /// The old element (for updates).
  final E? oldElement;

  /// The old index (for moves).
  final int? oldIndex;

  /// Creates a [ListChange].
  const ListChange({
    required this.type,
    this.index,
    this.element,
    this.oldElement,
    this.oldIndex,
  });

  @override
  String toString() =>
      'ListChange(type: $type, index: $index, element: $element)';
}

/// A reactive list that notifies listeners on any modification.
///
/// [ObservableList] implements [ListMixin] so it can be used as a
/// regular Dart list. Any mutation triggers change notifications.
///
/// Usage:
/// ```dart
/// final items = ObservableList<String>(['a', 'b']);
/// items.onChange.listen((change) => print('Change: ${change.type}'));
/// items.add('c'); // Notifies listeners
/// ```
class ObservableList<E> extends ListMixin<E> {
  final List<E> _list;
  final StreamController<ListChange<E>> _changeController =
      StreamController.broadcast();
  final Set<void Function(ListChange<E>)> _listeners = {};

  /// Creates an [ObservableList] with optional initial [items].
  ObservableList([Iterable<E>? items]) : _list = List<E>.from(items ?? []);

  /// A stream of list changes.
  Stream<ListChange<E>> get onChange => _changeController.stream;

  /// Registers a listener for list changes.
  void addChangeListener(void Function(ListChange<E>) listener) {
    _listeners.add(listener);
  }

  /// Removes a previously registered change listener.
  void removeChangeListener(void Function(ListChange<E>) listener) {
    _listeners.remove(listener);
  }

  void _notify(ListChange<E> change) {
    if (!_changeController.isClosed) {
      _changeController.add(change);
    }
    for (final listener in _listeners.toList()) {
      listener(change);
    }
  }

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    if (newLength < _list.length) {
      final removed = _list.sublist(newLength);
      _list.length = newLength;
      _notify(ListChange<E>(type: ListChangeType.clear));
      for (final item in removed) {
        _notify(ListChange<E>(type: ListChangeType.remove, element: item));
      }
    } else if (newLength > _list.length) {
      _list.length = newLength;
    }
  }

  @override
  E operator [](int index) => _list[index];

  @override
  void operator []=(int index, E value) {
    final old = _list[index];
    _list[index] = value;
    _notify(
      ListChange<E>(
        type: ListChangeType.update,
        index: index,
        oldElement: old,
        element: value,
      ),
    );
  }

  @override
  void add(E element) {
    _list.add(element);
    _notify(
      ListChange<E>(
        type: ListChangeType.add,
        index: _list.length - 1,
        element: element,
      ),
    );
  }

  @override
  void addAll(Iterable<E> iterable) {
    for (final element in iterable) {
      add(element);
    }
  }

  @override
  bool remove(Object? element) {
    final index = _list.indexOf(element as E);
    if (index == -1) return false;
    _list.removeAt(index);
    _notify(
      ListChange<E>(
        type: ListChangeType.remove,
        index: index,
        element: element,
      ),
    );
    return true;
  }

  @override
  E removeAt(int index) {
    final element = _list.removeAt(index);
    _notify(
      ListChange<E>(
        type: ListChangeType.remove,
        index: index,
        element: element,
      ),
    );
    return element;
  }

  @override
  void insert(int index, E element) {
    _list.insert(index, element);
    _notify(
      ListChange<E>(
        type: ListChangeType.insert,
        index: index,
        element: element,
      ),
    );
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    var i = index;
    for (final element in iterable) {
      insert(i, element);
      i++;
    }
  }

  @override
  void clear() {
    _list.clear();
    _notify(const ListChange(type: ListChangeType.clear));
  }

  /// Moves the element at [fromIndex] to [toIndex].
  void move(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    final element = removeAt(fromIndex);
    insert(toIndex, element);
    _notify(
      ListChange<E>(
        type: ListChangeType.move,
        oldIndex: fromIndex,
        index: toIndex,
        element: element,
      ),
    );
  }

  @override
  int indexOf(Object? element, [int start = 0]) =>
      _list.indexOf(element as E, start);

  @override
  int lastIndexWhere(bool Function(E element) test, [int? start]) =>
      _list.lastIndexWhere(test, start);

  @override
  List<E> sublist(int start, [int? end]) => _list.sublist(start, end);

  @override
  Iterator<E> get iterator => _list.iterator;

  /// Disposes the observable list.
  void dispose() {
    _changeController.close();
    _listeners.clear();
  }
}

/// Type of change that occurred in an [ObservableMap].
enum MapChangeType { add, update, remove, clear }

/// Describes a single change in an [ObservableMap].
class MapChange<K, V> {
  /// The type of change.
  final MapChangeType type;

  /// The key affected by the change.
  final K? key;

  /// The new value.
  final V? value;

  /// The old value (for updates and removals).
  final V? oldValue;

  /// Creates a [MapChange].
  const MapChange({required this.type, this.key, this.value, this.oldValue});

  @override
  String toString() =>
      'MapChange(type: $type, key: $key, value: $value, oldValue: $oldValue)';
}

/// A reactive map that notifies listeners on any modification.
///
/// [ObservableMap] implements [MapMixin] so it can be used as a
/// regular Dart map. Any mutation triggers change notifications.
///
/// Usage:
/// ```dart
/// final data = ObservableMap<String, int>();
/// data.onChange.listen((change) => print('Change: ${change.type} at ${change.key}'));
/// data['count'] = 1; // Notifies listeners
/// ```
class ObservableMap<K, V> extends MapMixin<K, V> {
  final Map<K, V> _map;
  final StreamController<MapChange<K, V>> _changeController =
      StreamController.broadcast();
  final Set<void Function(MapChange<K, V>)> _listeners = {};

  /// Creates an [ObservableMap] with optional initial [entries].
  ObservableMap([Map<K, V>? entries]) : _map = Map<K, V>.from(entries ?? {});

  /// A stream of map changes.
  Stream<MapChange<K, V>> get onChange => _changeController.stream;

  /// Registers a listener for map changes.
  void addChangeListener(void Function(MapChange<K, V>) listener) {
    _listeners.add(listener);
  }

  /// Removes a previously registered change listener.
  void removeChangeListener(void Function(MapChange<K, V>) listener) {
    _listeners.remove(listener);
  }

  void _notify(MapChange<K, V> change) {
    if (!_changeController.isClosed) {
      _changeController.add(change);
    }
    for (final listener in _listeners.toList()) {
      listener(change);
    }
  }

  @override
  V? operator [](Object? key) => _map[key];

  @override
  void operator []=(K key, V value) {
    final oldValue = _map[key];
    _map[key] = value;
    if (oldValue != null) {
      _notify(
        MapChange<K, V>(
          type: MapChangeType.update,
          key: key,
          value: value,
          oldValue: oldValue,
        ),
      );
    } else {
      _notify(MapChange<K, V>(type: MapChangeType.add, key: key, value: value));
    }
  }

  @override
  void clear() {
    _map.clear();
    _notify(const MapChange(type: MapChangeType.clear));
  }

  @override
  Iterable<K> get keys => _map.keys;

  @override
  V? remove(Object? key) {
    final oldValue = _map.remove(key);
    if (oldValue != null) {
      _notify(
        MapChange<K, V>(
          type: MapChangeType.remove,
          key: key as K,
          oldValue: oldValue,
        ),
      );
    }
    return oldValue;
  }

  @override
  int get length => _map.length;

  /// Disposes the observable map.
  void dispose() {
    _changeController.close();
    _listeners.clear();
  }
}

/// A computed/derived value that automatically updates when its
/// dependencies (observables) change.
///
/// [ObservableComputation] subscribes to one or more observables and
/// recomputes its value whenever any dependency changes.
///
/// Usage:
/// ```dart
/// final firstName = RiftObservable('Idris');
/// final lastName = RiftObservable('Ghamid');
///
/// final fullName = ObservableComputation(
///   dependencies: [firstName, lastName],
///   compute: () => '${firstName.value} ${lastName.value}',
/// );
///
/// fullName.listen((oldVal, newVal) => print('Full name: $newVal'));
/// firstName.set('Ahmed'); // Recomputes and notifies
/// ```
class ObservableComputation<T> {
  T _value;
  final T Function() _compute;
  final List<RiftObservable> _dependencies;
  final StreamController<T> _controller = StreamController.broadcast();
  final Set<void Function(T oldValue, T newValue)> _listeners = {};

  /// Creates an [ObservableComputation] that derives its value from
  /// [dependencies] using the [compute] function.
  ObservableComputation({
    required List<RiftObservable> dependencies,
    required T Function() compute,
  }) : _compute = compute,
       _dependencies = dependencies,
       _value = compute() {
    for (final dep in _dependencies) {
      dep.listen((_, __) => _recompute());
    }
  }

  /// The current computed value.
  T get value => _value;

  /// A stream of computed value changes.
  Stream<T> get stream => _controller.stream;

  void _recompute() {
    final newValue = _compute();
    if (newValue == _value) return;
    final oldValue = _value;
    _value = newValue;
    if (!_controller.isClosed) {
      _controller.add(newValue);
    }
    for (final listener in _listeners.toList()) {
      listener(oldValue, newValue);
    }
  }

  /// Forces an immediate recomputation regardless of dependencies.
  void forceRecompute() {
    final newValue = _compute();
    final oldValue = _value;
    _value = newValue;
    if (newValue != oldValue) {
      if (!_controller.isClosed) {
        _controller.add(newValue);
      }
      for (final listener in _listeners.toList()) {
        listener(oldValue, newValue);
      }
    }
  }

  /// Registers a listener for computed value changes.
  void listen(void Function(T oldValue, T newValue) listener) {
    _listeners.add(listener);
  }

  /// Removes a previously registered listener.
  void removeListener(void Function(T oldValue, T newValue) listener) {
    _listeners.remove(listener);
  }

  /// Disposes the computation, removing dependency subscriptions.
  void dispose() {
    _controller.close();
    _listeners.clear();
  }
}
