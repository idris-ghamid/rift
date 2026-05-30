import 'dart:typed_data';

import 'package:rift/rift.dart';
import 'package:rift/src/box/default_compaction_strategy.dart';
import 'package:rift/src/box/default_key_comparator.dart';
import 'package:rift/src/isolate/isolated_box_impl/isolated_box_impl_web.dart';

/// Web implementation of [IsolatedRiftInterface]
///
/// All operations are delegated to [Rift] since web does not support isolates
class IsolatedRiftImpl implements IsolatedRiftInterface {
  @override
  Future<void> init(
    String? path, {
    IsolateNameServer? isolateNameServer,
  }) async => Rift.init(path);

  @override
  Future<IsolatedBox<E>> openBox<E>(
    String name, {
    RiftCipher? encryptionCipher,
    KeyComparator? keyComparator,
    CompactionStrategy? compactionStrategy,
    bool crashRecovery = true,
    String? path,
    Uint8List? bytes,
    String? collection,
  }) async => IsolatedBoxImpl(
    await Rift.openBox(
      name,
      encryptionCipher: encryptionCipher,
      keyComparator: keyComparator ?? defaultKeyComparator,
      compactionStrategy: compactionStrategy ?? defaultCompactionStrategy,
      crashRecovery: crashRecovery,
      path: path,
      bytes: bytes,
      collection: collection,
    ),
  );

  @override
  Future<IsolatedLazyBox<E>> openLazyBox<E>(
    String name, {
    RiftCipher? encryptionCipher,
    KeyComparator? keyComparator,
    CompactionStrategy? compactionStrategy,
    bool crashRecovery = true,
    String? path,
    String? collection,
  }) async => IsolatedLazyBoxImpl(
    await Rift.openLazyBox(
      name,
      encryptionCipher: encryptionCipher,
      keyComparator: keyComparator ?? defaultKeyComparator,
      compactionStrategy: compactionStrategy ?? defaultCompactionStrategy,
      crashRecovery: crashRecovery,
      path: path,
      collection: collection,
    ),
  );

  @override
  IsolatedBox<E> box<E>(String name) => IsolatedBoxImpl(Rift.box(name));

  @override
  IsolatedLazyBox<E> lazyBox<E>(String name) =>
      IsolatedLazyBoxImpl(Rift.lazyBox(name));

  @override
  bool isBoxOpen(String name) => Rift.isBoxOpen(name);

  @override
  Future<void> close() => Rift.close();

  @override
  Future<void> deleteBoxFromDisk(String name, {String? path}) =>
      Rift.deleteBoxFromDisk(name, path: path);

  @override
  Future<void> deleteFromDisk() => Rift.deleteFromDisk();

  @override
  Future<bool> boxExists(String name, {String? path}) =>
      Rift.boxExists(name, path: path);

  @override
  Future<void> registerAdapter<T>(
    TypeAdapter<T> adapter, {
    bool internal = false,
    bool override = false,
  }) async =>
      Rift.registerAdapter(adapter, internal: internal, override: override);

  @override
  bool isAdapterRegistered(int typeId) => Rift.isAdapterRegistered(typeId);

  @override
  void resetAdapters() {
    // This is an override
    // ignore: invalid_use_of_visible_for_testing_member
    Rift.resetAdapters();
  }

  @override
  Future<void> ignoreTypeId<T>(int typeId) async =>
      Rift.ignoreTypeId<T>(typeId);
}
