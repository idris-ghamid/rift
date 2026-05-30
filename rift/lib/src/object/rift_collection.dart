import 'package:rift/rift.dart';

/// List containing [RiftObjectMixin]s.
abstract class RiftCollection<E extends RiftObjectMixin> implements List<E> {
  /// The box which contains all the objects in this collection
  BoxBase get box;

  /// The keys of all the objects in this collection.
  Iterable<dynamic> get keys;

  /// Delete all objects in this collection from Rift.
  Future<void> deleteAllFromRift();

  /// Delete the first object in this collection from Rift.
  Future<void> deleteFirstFromRift();

  /// Delete the last object in this collection from Rift.
  Future<void> deleteLastFromRift();

  /// Delete the object at [index] from Rift.
  Future<void> deleteFromRift(int index);

  /// Deprecated — use [deleteAllFromRift] instead.
  @Deprecated('Use deleteAllFromRift instead')
  Future<void> deleteAllFromHive() => deleteAllFromRift();

  /// Deprecated — use [deleteFirstFromRift] instead.
  @Deprecated('Use deleteFirstFromRift instead')
  Future<void> deleteFirstFromHive() => deleteFirstFromRift();

  /// Deprecated — use [deleteLastFromRift] instead.
  @Deprecated('Use deleteLastFromRift instead')
  Future<void> deleteLastFromHive() => deleteLastFromRift();

  /// Deprecated — use [deleteFromRift] instead.
  @Deprecated('Use deleteFromRift instead')
  Future<void> deleteFromHive(int index) => deleteFromRift(index);

  /// Converts this collection to a Map.
  Map<dynamic, E> toMap();
}
