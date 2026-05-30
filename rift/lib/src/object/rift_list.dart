import 'package:rift/rift.dart';
import 'package:rift/src/object/rift_list_impl.dart';
import 'package:meta/meta.dart';

/// Allows defining references to other [RiftObjectMixin]s.
@experimental
abstract class RiftList<E extends RiftObjectMixin> extends RiftCollection<E>
    implements List<E> {
  /// Create a new RiftList which can contain RiftObjects from [box].
  factory RiftList(Box box, {List<E>? objects}) =>
      RiftListImpl(box, objects: objects);

  /// Disposes this list. It is important to call this method when the list is
  /// no longer used to avoid memory leaks.
  void dispose();

  /// Casts the list to a new RiftList.
  RiftList<T> castRiftList<T extends RiftObjectMixin>();
}
