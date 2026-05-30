import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:rift/rift.dart';
import 'package:rift/src/rift_impl.dart';
import 'package:rift/src/isolate/isolated_rift_impl/rift_isolate.dart';
import 'package:rift/src/isolate/isolated_rift_impl/isolated_rift_impl.dart';
import 'package:isolate_channel/isolate_channel.dart';
import 'package:test/test.dart';

import '../tests/common.dart';
import '../util/is_browser/is_browser.dart';
import '../util/print_utils.dart';
import 'package:meta/meta.dart';

@immutable
class RiftWrapper {
  final dynamic rift;

  const RiftWrapper(this.rift);

  FutureOr<void> init(String? path) => rift.init(path);

  Future<BoxWrapper<T>> openBox<T>(
    String name, {
    bool crashRecovery = true,
    RiftCipher? encryptionCipher,
    Uint8List? bytes,
  }) async => BoxWrapper(
    await rift.openBox<T>(
      name,
      crashRecovery: crashRecovery,
      encryptionCipher: encryptionCipher,
      bytes: bytes,
    ),
  );

  Future<LazyBoxWrapper<T>> openLazyBox<T>(
    String name, {
    bool crashRecovery = true,
    RiftCipher? encryptionCipher,
  }) async => LazyBoxWrapper(
    await rift.openLazyBox<T>(
      name,
      crashRecovery: crashRecovery,
      encryptionCipher: encryptionCipher,
    ),
  );

  Future<void> close() => rift.close();

  FutureOr<void> registerAdapter<T>(
    TypeAdapter<T> adapter, {
    bool internal = false,
    bool override = false,
  }) => rift.registerAdapter(adapter, internal: internal, override: override);

  FutureOr<void> resetAdapters() => rift.resetAdapters();
  FutureOr<void> ignoreTypeId<T>(int typeId) => rift.ignoreTypeId(typeId);
}

@immutable
class BoxBaseWrapper<E> {
  final dynamic box;

  const BoxBaseWrapper(this.box);

  String get name => box.name;
  String? get path => box.path;
  bool get lazy => box.lazy;
  FutureOr<Iterable> get keys => box.keys;
  Stream<BoxEvent> watch({dynamic key}) => box.watch(key: key);
  FutureOr<bool> containsKey(dynamic key) => box.containsKey(key);
  Future<void> put(dynamic key, E value) => box.put(key, value);
  Future<void> putAt(int index, E value) => box.putAt(index, value);
  Future<void> delete(dynamic key) => box.delete(key);
  Future<void> putAll(Map<dynamic, E> entries) => box.putAll(entries);
  Future<int> add(E value) => box.add(value);
  Future<void> deleteAll(Iterable keys) => box.deleteAll(keys);
  Future<void> compact() => box.compact();
  Future<void> close() => box.close();
  FutureOr<E?> get(dynamic key, {E? defaultValue}) =>
      box.get(key, defaultValue: defaultValue);
}

class LazyBoxWrapper<E> extends BoxBaseWrapper<E> {
  const LazyBoxWrapper(super.box);
}

class BoxWrapper<E> extends BoxBaseWrapper<E> {
  const BoxWrapper(super.box);

  FutureOr<Map<dynamic, E>> toMap() => box.toMap();
}

extension RiftIsolateExtension on RiftIsolate {
  set entryPoint(IsolateEntryPoint entryPoint) {
    spawnRiftIsolate = () => spawnIsolate(
      entryPoint,
      debugName: 'RiftIsolate',
      onConnect: onConnect,
      onExit: onExit,
    );
  }

  void useUriIsolate() {
    spawnRiftIsolate = () => spawnUriIsolate(
      Uri.file('${Directory.current.path}/test/util/isolate_entry_point.dart'),
      debugName: 'RiftIsolate',
      onConnect: onConnect,
      onExit: onExit,
    );
  }
}

Future<RiftWrapper> createHive({
  required TestType type,
  Directory? directory,
  IsolateEntryPoint? entryPoint,
}) async {
  final RiftWrapper rift;
  if (type == TestType.normal) {
    rift = RiftWrapper(RiftImpl());
  } else {
    final isolatedRift = IsolatedRiftImpl();
    if (isolatedRift is RiftIsolate) {
      if (entryPoint != null) {
        (isolatedRift as RiftIsolate).entryPoint = entryPoint;
      } else if (type == TestType.uriIsolate) {
        (isolatedRift as RiftIsolate).useUriIsolate();
      }
    }
    rift = RiftWrapper(isolatedRift);
  }

  addTearDown(rift.close);
  if (!isBrowser) {
    final dir = directory ?? await getTempDir();
    await silenceOutput(() => rift.init(dir.path));
  } else {
    await rift.init(null);
  }
  return rift;
}

Future<(RiftWrapper, BoxBaseWrapper<T>)> openBox<T>(
  bool lazy, {
  RiftWrapper? rift,
  required TestType type,
  List<int>? encryptionKey,
}) async {
  rift ??= await createHive(type: type);
  final boxName = generateBoxName();
  RiftCipher? cipher;
  if (encryptionKey != null) {
    cipher = RiftAesCipher(encryptionKey);
  }
  final BoxBaseWrapper<T> box;
  if (lazy) {
    box = await rift.openLazyBox<T>(
      boxName,
      crashRecovery: false,
      encryptionCipher: cipher,
    );
  } else {
    box = await rift.openBox<T>(
      boxName,
      crashRecovery: false,
      encryptionCipher: cipher,
    );
  }
  return (rift, box);
}

extension RiftWrapperX on RiftWrapper {
  Future<BoxBaseWrapper<T>> reopenBox<T>(
    BoxBaseWrapper<T> box, {
    List<int>? encryptionKey,
  }) async {
    await box.close();
    RiftCipher? cipher;
    if (encryptionKey != null) {
      cipher = RiftAesCipher(encryptionKey);
    }
    if (box.lazy) {
      return openLazyBox(
        box.name,
        crashRecovery: false,
        encryptionCipher: cipher,
      );
    } else {
      return this.openBox(
        box.name,
        crashRecovery: false,
        encryptionCipher: cipher,
      );
    }
  }
}

const longTimeout = Timeout(Duration(minutes: 2));

enum TestType { normal, isolate, uriIsolate }

void riftIntegrationTest(void Function(TestType type) test) {
  test(TestType.normal);
  group('IsolatedRift', () => test(TestType.isolate));
  if (!isBrowser) {
    group('IsolatedRift.spawnUri', () => test(TestType.uriIsolate));
  }
}
