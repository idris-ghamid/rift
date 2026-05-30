import 'package:rift/rift.dart';
import 'package:rift/src/object/rift_list_impl.dart';
import 'package:meta/meta.dart';

part 'rift_object_internal.dart';

/// Extend `RiftObject` to add useful methods to the objects you want to store
/// in Rift
mixin RiftObjectMixin {
  @visibleForTesting
  BoxBase? testBox;

  @visibleForTesting
  dynamic testKey;

  // RiftLists containing this object
  @visibleForTesting
  final testRiftLists = <RiftList, int>{};

  /// Get the box in which this object is stored. Returns `null` if object has
  /// not been added to a box yet.
  BoxBase? get box => testBox;

  /// Get the key associated with this object. Returns `null` if object has
  /// not been added to a box yet.
  dynamic get key => testKey;

  void _requireInitialized() {
    if (testBox == null) {
      throw RiftError('This object is currently not in a box.');
    }
  }

  /// Persists this object.
  Future<void> save() {
    _requireInitialized();
    return testBox!.put(testKey, this);
  }

  /// Deletes this object from the box it is stored in.
  Future<void> delete() async {
    _requireInitialized();
    await testBox!.delete(testKey);
    if (testBox?.lazy == true) {
      // Lazy boxes won't automatically dispose their RiftObjects
      dispose();
    }
  }

  /// Returns whether this object is currently stored in a box.
  ///
  /// For lazy boxes this only checks if the key exists in the box and NOT
  /// whether this instance is actually stored in the box.
  bool get isInBox {
    if (testBox != null) {
      if (testBox!.lazy) {
        return testBox!.containsKey(testKey);
      } else {
        return true;
      }
    }
    return false;
  }
}

/// TODO: Document this!
abstract class RiftObject with RiftObjectMixin {}
