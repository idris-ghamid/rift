import 'dart:collection';

import 'package:rift/rift.dart';
import 'package:rift/src/rift_impl.dart';
import 'package:rift/src/object/rift_collection_mixin.dart';
import 'package:rift/src/object/rift_object.dart';
import 'package:rift/src/util/delegating_list_view_mixin.dart';
import 'package:meta/meta.dart';

/// Not part of public API
class RiftListImpl<E extends RiftObjectMixin>
    with RiftCollectionMixin<E>, ListMixin<E>, DelegatingListViewMixin<E>
    implements RiftList<E> {
  /// Not part of public API
  final String boxName;

  final List<dynamic>? _keys;

  RiftInterface _rift = Rift;

  List<E>? _delegate;

  Box? _box;

  var _invalidated = false;

  var _disposed = false;

  /// Not part of public API
  RiftListImpl(Box box, {List<E>? objects})
    : boxName = box.name,
      _keys = null,
      _delegate = [],
      _box = box {
    if (objects != null) {
      addAll(objects);
    }
  }

  /// Not part of public API
  RiftListImpl.lazy(this.boxName, List<dynamic>? keys) : _keys = keys;

  @override
  Iterable<dynamic> get keys {
    if (_delegate == null) {
      return _keys!;
    } else {
      return super.keys;
    }
  }

  @override
  Box get box {
    if (_box == null) {
      final box = (_rift as RiftImpl).getBoxWithoutCheckInternal(boxName);
      if (box == null) {
        throw RiftError(
          'To use this list, you have to open the box "$boxName" first.',
        );
      } else if (box is! Box) {
        throw RiftError(
          'The box "$boxName" is a lazy box. '
          'You can only use RiftLists with normal boxes.',
        );
      } else {
        _box = box;
      }
    }
    return _box!;
  }

  @override
  List<E> get delegate {
    if (_disposed) {
      throw RiftError('RiftList has already been disposed.');
    }

    if (_invalidated) {
      final retained = <E>[];
      for (final obj in _delegate!) {
        if (obj.isInRiftList(this)) {
          retained.add(obj);
        }
      }
      _delegate = retained;
      _invalidated = false;
    } else if (_delegate == null) {
      final list = <E>[];
      for (final key in _keys!) {
        if (box.containsKey(key)) {
          final obj = box.get(key) as E;
          obj.linkRiftList(this);
          list.add(obj);
        }
      }
      _delegate = list;
    }

    return _delegate!;
  }

  @override
  void dispose() {
    if (_delegate != null) {
      for (final element in _delegate!) {
        element.unlinkRiftList(this);
      }
      _delegate = null;
    }

    _disposed = true;
  }

  /// Not part of public API
  void invalidate() {
    if (_delegate != null) {
      _invalidated = true;
    }
  }

  void _checkElementIsValid(E obj) {
    if (obj.box != box) {
      throw RiftError('RiftObjects needs to be in the box "$boxName".');
    }
  }

  @override
  set length(int newLength) {
    if (newLength < delegate.length) {
      for (var i = newLength; i < delegate.length; i++) {
        delegate[i].unlinkRiftList(this);
      }
    }
    delegate.length = newLength;
  }

  @override
  void operator []=(int index, E value) {
    _checkElementIsValid(value);
    value.linkRiftList(this);

    final oldValue = delegate[index];
    delegate[index] = value;

    oldValue.unlinkRiftList(this);
  }

  @override
  void add(E element) {
    _checkElementIsValid(element);
    element.linkRiftList(this);
    delegate.add(element);
  }

  @override
  void addAll(Iterable<E> iterable) {
    for (final element in iterable) {
      _checkElementIsValid(element);
      element.linkRiftList(this);
    }
    delegate.addAll(iterable);
  }

  @override
  RiftList<T> castRiftList<T extends RiftObjectMixin>() {
    if (_delegate != null) {
      return RiftListImpl(box, objects: _delegate!.cast());
    } else {
      return RiftListImpl.lazy(boxName, _keys);
    }
  }

  @override
  Future<void> deleteAllFromRift() async {
    for (final obj in delegate.toList()) {
      await obj.delete();
    }
  }

  @override
  Future<void> deleteFirstFromRift() async {
    if (delegate.isNotEmpty) {
      await delegate.first.delete();
    }
  }

  @override
  Future<void> deleteFromRift(int index) async {
    if (index >= 0 && index < delegate.length) {
      await delegate[index].delete();
    }
  }

  @override
  Future<void> deleteLastFromRift() async {
    if (delegate.isNotEmpty) {
      await delegate.last.delete();
    }
  }

  @override
  Future<void> deleteAllFromHive() => deleteAllFromRift();

  @override
  Future<void> deleteFirstFromHive() => deleteFirstFromRift();

  @override
  Future<void> deleteFromHive(int index) => deleteFromRift(index);

  @override
  Future<void> deleteLastFromHive() => deleteLastFromRift();

  /// Not part of public API
  @visibleForTesting
  set debugRift(RiftInterface rift) => _rift = rift;
}
