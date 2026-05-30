import 'package:rift/rift.dart';

/// Implemetation of [RiftCollection].
mixin RiftCollectionMixin<E extends RiftObjectMixin>
    implements RiftCollection<E> {
  @override
  Iterable<dynamic> get keys sync* {
    for (final value in this) {
      yield value.key;
    }
  }

  @override
  Future<void> deleteAllFromRift() {
    return box.deleteAll(keys);
  }

  @override
  Future<void> deleteFirstFromRift() {
    return first.delete();
  }

  @override
  Future<void> deleteLastFromRift() {
    return last.delete();
  }

  @override
  Future<void> deleteFromRift(int index) {
    return this[index].delete();
  }

  @override
  Map<dynamic, E> toMap() {
    final map = <dynamic, E>{};
    for (final item in this) {
      map[item.key] = item;
    }
    return map;
  }
}
