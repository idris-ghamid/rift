import 'dart:io';

import 'package:rift/rift.dart';
import 'package:rift/src/backend/storage_backend.dart';
import 'package:rift/src/box/change_notifier.dart';
import 'package:rift/src/box/keystore.dart';
import 'package:rift/src/rift_impl.dart';
import 'package:rift/src/io/frame_io_helper.dart';
import 'package:rift/src/object/rift_list_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:meta/meta.dart';

// Mocks

@immutable
class MockBox<E> extends Mock implements Box<E> {
  @override
  final bool lazy;

  MockBox({this.lazy = false});
}

class MockChangeNotifier extends Mock implements ChangeNotifier {}

class MockStorageBackend extends Mock implements StorageBackend {}

class MockKeystore extends Mock implements Keystore {}

class MockRiftImpl extends Mock implements RiftImpl {}

class MockRiftList extends Mock implements RiftList {
  void invalidate() {}
}

class MockRandomAccessFile extends Mock implements RandomAccessFile {}

class MockBinaryReader extends Mock implements BinaryReader {}

class MockBinaryWriter extends Mock implements BinaryWriter {}

class MockFile extends Mock implements File {
  @override
  bool existsSync() => false;
}

class MockFrameIoHelper extends Mock implements FrameIoHelper {}

// Fakes

class KeystoreFake extends Fake implements Keystore {}

class TypeRegistryFake extends Fake implements TypeRegistry {}

// Test object
class TestRiftObject extends RiftObject {}

// Extension for testing RiftObjectInternal methods
extension TestRiftObjectInternal on TestRiftObject {
  void init(dynamic key, BoxBase box) {
    if (testBox != null) {
      if (testBox != box) {
        throw RiftError(
          'The same instance of a RiftObject cannot '
          'be stored in two different boxes.',
        );
      } else if (testKey != key) {
        throw RiftError(
          'The same instance of a RiftObject cannot '
          'be stored with two different keys ("$testKey" and "$key").',
        );
      }
    }
    testBox = box;
    testKey = key;
  }

  void dispose() {
    for (final list in testRiftLists.keys) {
      (list as RiftListImpl).invalidate();
    }

    testRiftLists.clear();

    testBox = null;
    testKey = null;
  }

  void linkRiftList(RiftList list) {
    if (testBox == null) {
      throw RiftError('This object is currently not in a box.');
    }
    testRiftLists[list] = (testRiftLists[list] ?? 0) + 1;
  }

  void unlinkRiftList(RiftList list) {
    final currentIndex = testRiftLists[list]!;
    final newIndex = testRiftLists[list] = currentIndex - 1;
    if (newIndex <= 0) {
      testRiftLists.remove(list);
    }
  }

  bool isInRiftList(RiftList list) {
    return testRiftLists.containsKey(list);
  }

  @visibleForTesting
  Map<RiftList, int> get debugRiftLists => testRiftLists;
}

