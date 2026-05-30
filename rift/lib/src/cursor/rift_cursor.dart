import 'package:rift/src/box/box.dart';
import 'package:rift/src/box/box_base.dart';
import 'package:rift/src/box/lazy_box.dart';

/// Cursor-based iterator for Rift boxes.
///
/// Allows iterating over large datasets without loading everything into
/// memory at once. The cursor maintains a position and can move forward
/// or backward through entries, fetching values on demand.
///
/// For [LazyBox] instances, values are loaded lazily from the backend
/// only when accessed. For regular [Box] instances, values are read
/// from memory.
///
/// Usage:
/// ```dart
/// final box = await Rift.openBox('largeData');
/// final cursor = RiftCursor(box, box.keys.toList());
///
/// while (cursor.hasNext) {
///   final entry = await cursor.next();
///   print('${entry!.key}: ${entry.value}');
/// }
/// ```
class RiftCursor<K, V> {
  /// The box to iterate over (null for pre-loaded cursors).
  final BoxBase<dynamic>? _box;

  /// The ordered list of keys to iterate through.
  final List<K> _keys;

  /// Current position in the key list.
  int _position = 0;

  /// Number of items to fetch in each batch.
  final int _batchSize;

  /// Optional pre-loaded values for cursors from map() operations.
  final Map<K, V>? _preloadedValues;

  /// Creates a new cursor over [box] for the given [keys].
  RiftCursor(BoxBase<V> box, List<K> keys, {int batchSize = 50})
    : _box = box,
      _keys = List<K>.from(keys),
      _batchSize = batchSize,
      _preloadedValues = null;

  /// Creates a cursor backed by pre-loaded values (internal).
  RiftCursor._preloaded(this._keys, this._preloadedValues, {int batchSize = 50})
    : _box = null,
      _batchSize = batchSize;

  /// Whether there are more items ahead of the current position.
  bool get hasNext => _position < _keys.length;

  /// Whether there are items behind the current position.
  bool get hasPrevious => _position > 0;

  /// The current position in the key list (zero-based).
  int get position => _position;

  /// The total number of keys in the cursor.
  int get length => _keys.length;

  /// The number of remaining items ahead of the current position.
  int get remaining => _keys.length - _position;

  /// Whether the cursor has been exhausted (all items consumed).
  bool get isExhausted => _position >= _keys.length;

  /// Peeks at the next item without advancing the cursor position.
  MapEntry<K, V>? peek() {
    if (!hasNext) return null;
    final key = _keys[_position];

    if (_preloadedValues != null) {
      final value = _preloadedValues[key];
      if (value != null) return MapEntry(key, value);
      return null;
    }

    if (_box is Box) {
      final value = (_box).get(key) as V?;
      if (value != null) return MapEntry(key, value);
    }
    return null;
  }

  /// Gets the next item and advances the cursor position.
  Future<MapEntry<K, V>?> next() async {
    if (!hasNext) return null;

    final key = _keys[_position];
    _position++;

    final value = await _getValue(key);
    if (value != null) return MapEntry(key, value);
    return await next();
  }

  /// Gets the next batch of items and advances the cursor position.
  Future<List<MapEntry<K, V>>> nextBatch() async {
    final results = <MapEntry<K, V>>[];
    final end = (_position + _batchSize).clamp(0, _keys.length);

    for (int i = _position; i < end; i++) {
      final key = _keys[i];
      final value = await _getValue(key);
      if (value != null) results.add(MapEntry(key, value));
    }

    _position = end;
    return results;
  }

  /// Gets the previous item and moves the cursor position backward.
  Future<MapEntry<K, V>?> previous() async {
    if (!hasPrevious) return null;

    _position--;
    final key = _keys[_position];
    final value = await _getValue(key);
    if (value != null) return MapEntry(key, value);
    return await previous();
  }

  /// Skips [count] items forward from the current position.
  void skip(int count) {
    _position = (_position + count).clamp(0, _keys.length);
  }

  /// Moves the cursor to a specific [index] position.
  void seek(int index) {
    if (index < 0) throw RangeError('Index must be non-negative: $index');
    _position = index.clamp(0, _keys.length);
  }

  /// Resets the cursor to the beginning.
  void reset() => _position = 0;

  /// Resets the cursor to the end (before the last item).
  void resetToEnd() {
    _position = _keys.isNotEmpty ? _keys.length - 1 : 0;
  }

  /// Creates a new cursor with only the keys whose values satisfy [predicate].
  Future<RiftCursor<K, V>> where(
    bool Function(K key, V? value) predicate,
  ) async {
    final filteredKeys = <K>[];
    for (final key in _keys) {
      final value = await _getValue(key);
      if (predicate(key, value)) filteredKeys.add(key);
    }

    if (_box != null) {
      return RiftCursor<K, V>(
        _box as BoxBase<V>,
        filteredKeys,
        batchSize: _batchSize,
      );
    }

    final filteredValues = <K, V>{};
    if (_preloadedValues != null) {
      for (final key in filteredKeys) {
        final val = _preloadedValues[key];
        if (val != null) filteredValues[key] = val;
      }
    }
    return RiftCursor<K, V>._preloaded(
      filteredKeys,
      filteredValues,
      batchSize: _batchSize,
    );
  }

  /// Creates a new cursor by transforming each entry with [mapper].
  Future<RiftCursor<K, T>> map<T>(T Function(K key, V? value) mapper) async {
    final mappedValues = <K, T>{};
    for (final key in _keys) {
      final value = await _getValue(key);
      mappedValues[key] = mapper(key, value);
    }
    return RiftCursor<K, T>._preloaded(
      _keys,
      mappedValues,
      batchSize: _batchSize,
    );
  }

  /// Collects all remaining entries into a list.
  Future<List<MapEntry<K, V>>> collectAll() async {
    final results = <MapEntry<K, V>>[];
    while (hasNext) {
      final batch = await nextBatch();
      results.addAll(batch);
    }
    return results;
  }

  /// Collects all remaining entries into a map.
  Future<Map<K, V>> collectAsMap() async {
    final results = <K, V>{};
    while (hasNext) {
      final batch = await nextBatch();
      for (final entry in batch) {
        results[entry.key] = entry.value;
      }
    }
    return results;
  }

  /// Applies an action to each remaining entry.
  Future<void> forEach(void Function(K key, V value) action) async {
    while (hasNext) {
      final batch = await nextBatch();
      for (final entry in batch) {
        action(entry.key, entry.value);
      }
    }
  }

  /// Gets the value for a key, handling Box, LazyBox, and pre-loaded values.
  Future<V?> _getValue(K key) async {
    if (_preloadedValues != null) return _preloadedValues[key];

    if (_box is Box) {
      return (_box).get(key) as V?;
    } else if (_box is LazyBox) {
      return await (_box).get(key) as V?;
    }
    return null;
  }
}
