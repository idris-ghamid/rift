part of 'rift_object.dart';

/// Not part of public API
extension RiftObjectInternal on RiftObjectMixin {
  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
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

  /// Not part of public API
  void dispose() {
    for (final list in testRiftLists.keys) {
      (list as RiftListImpl).invalidate();
    }

    testRiftLists.clear();

    testBox = null;
    testKey = null;
  }

  /// Not part of public API
  void linkRiftList(RiftList list) {
    _requireInitialized();
    testRiftLists[list] = (testRiftLists[list] ?? 0) + 1;
  }

  /// Not part of public API
  void unlinkRiftList(RiftList list) {
    final currentIndex = testRiftLists[list]!;
    final newIndex = testRiftLists[list] = currentIndex - 1;
    if (newIndex <= 0) {
      testRiftLists.remove(list);
    }
  }

  /// Not part of public API
  bool isInRiftList(RiftList list) {
    return testRiftLists.containsKey(list);
  }

  /// Not part of public API
  @visibleForTesting
  Map<RiftList, int> get debugRiftLists => testRiftLists;
}
