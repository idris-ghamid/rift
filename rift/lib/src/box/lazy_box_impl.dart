import 'package:rift/rift.dart';
import 'package:rift/src/binary/frame.dart';
import 'package:rift/src/box/box_base_impl.dart';
import 'package:rift/src/object/rift_object.dart';

/// Not part of public API
class LazyBoxImpl<E> extends BoxBaseImpl<E> implements LazyBox<E> {
  /// Not part of public API
  LazyBoxImpl(
    super.rift,
    super.name,
    super.keyComparator,
    super.compactionStrategy,
    super.backend, {
    super.isolated = false,
  });

  @override
  final lazy = true;

  @override
  Future<E?> get(dynamic key, {E? defaultValue}) async {
    checkOpen();

    // Check TTL expiry — return default if expired
    if (BoxBaseImpl.ttlManager.isExpired(name, key)) {
      // Lazily purge the expired entry
      await BoxBaseImpl.ttlManager.removeTTL(name, key);
      if (defaultValue != null && defaultValue is RiftObjectMixin) {
        defaultValue.init(key, this);
      }
      return defaultValue;
    }

    final frame = keystore.get(key);

    if (frame != null) {
      final value = await backend.readValue(frame, verbatim: isolated);
      if (value is RiftObjectMixin) {
        value.init(key, this);
      }
      return value as E?;
    } else {
      if (defaultValue != null && defaultValue is RiftObjectMixin) {
        defaultValue.init(key, this);
      }
      return defaultValue;
    }
  }

  @override
  Future<E?> getAt(int index) {
    return get(keystore.keyAt(index));
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> kvPairs) async {
    checkOpen();

    // Run before-put middleware for each entry
    if (BoxBaseImpl.middlewareChain.isNotEmpty) {
      final vetoedKeys = <dynamic>{};
      for (final entry in kvPairs.entries) {
        final allowed = await BoxBaseImpl.middlewareChain.runBeforePut(
          name,
          entry.key,
          entry.value,
        );
        if (!allowed) {
          vetoedKeys.add(entry.key);
        }
      }
      // Remove vetoed entries
      if (vetoedKeys.isNotEmpty) {
        kvPairs = Map.from(kvPairs)
          ..removeWhere((k, _) => vetoedKeys.contains(k));
      }
    }

    if (kvPairs.isEmpty) return;

    // Capture old keys for index updates
    final oldKeys = <dynamic>{};
    for (final key in kvPairs.keys) {
      if (keystore.containsKey(key)) {
        oldKeys.add(key);
      }
    }

    final frames = <Frame>[];
    for (final key in kvPairs.keys) {
      frames.add(Frame(key, kvPairs[key]));
      if (key is int) {
        keystore.updateAutoIncrement(key);
      }
    }

    if (frames.isEmpty) return;
    await backend.writeFrames(frames, verbatim: isolated);

    for (final frame in frames) {
      if (frame.value is RiftObjectMixin) {
        (frame.value as RiftObjectMixin).init(frame.key, this);
      }
      keystore.insert(frame, lazy: true);
    }

    // Update indexes after successful write
    // Note: For lazy boxes with overwrites, we can't easily remove old indexed
    // values since the old value isn't in memory. The index may need rebuilding
    // after heavy use with lazy boxes. For new keys, this works fine.
    for (final frame in frames) {
      // For overwrites, the index will have duplicate entries; the query
      // layer handles this by checking the actual value.
      await globalIndexManager.updateIndex(name, frame.key, frame.value);
      // Notify relation manager of the put
      BoxBaseImpl.relationManager.onPut(name, frame.key, frame.value);
    }

    // Run after-put middleware for each entry
    if (BoxBaseImpl.middlewareChain.isNotEmpty) {
      for (final entry in kvPairs.entries) {
        await BoxBaseImpl.middlewareChain.runAfterPut(
          name,
          entry.key,
          entry.value,
        );
      }
    }

    await performCompactionIfNeeded();
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    checkOpen();

    // Run before-delete middleware and handle cascade deletes
    final keysToDelete = <dynamic>[];
    for (final key in keys) {
      // Run before-delete middleware
      if (BoxBaseImpl.middlewareChain.isNotEmpty) {
        final allowed = await BoxBaseImpl.middlewareChain.runBeforeDelete(
          name,
          key,
        );
        if (!allowed) continue;
      }
      keysToDelete.add(key);
    }

    if (keysToDelete.isEmpty) return;

    // Handle relation cascade deletes
    final cascadeDeletes = <String, List<dynamic>>{};
    for (final key in keysToDelete) {
      final cascaded = BoxBaseImpl.relationManager.cascadeDelete(name, key);
      for (final entry in cascaded.entries) {
        cascadeDeletes.putIfAbsent(entry.key, () => []);
        cascadeDeletes[entry.key]!.addAll(entry.value);
      }
    }

    // Notify relation manager and remove TTL before actual delete
    for (final key in keysToDelete) {
      BoxBaseImpl.relationManager.onDelete(name, key, null);
      await BoxBaseImpl.ttlManager.removeTTL(name, key);
    }

    final frames = <Frame>[];
    for (final key in keysToDelete) {
      if (keystore.containsKey(key)) {
        frames.add(Frame.deleted(key));
      }
    }

    if (frames.isEmpty) return;
    await backend.writeFrames(frames, verbatim: isolated);

    // Remove from indexes before the keystore entries are deleted
    // Note: For lazy boxes, we don't have the old values in memory,
    // so we can't properly clean up indexes. The index should be
    // rebuilt after heavy delete operations on lazy boxes.
    for (final frame in frames) {
      await globalIndexManager.removeFromIndex(name, frame.key, null);
    }

    for (final frame in frames) {
      keystore.insert(frame);
    }

    // Run after-delete middleware
    if (BoxBaseImpl.middlewareChain.isNotEmpty) {
      for (final key in keysToDelete) {
        await BoxBaseImpl.middlewareChain.runAfterDelete(name, key);
      }
    }

    // Apply cascade deletes to target boxes
    if (cascadeDeletes.isNotEmpty) {
      for (final entry in cascadeDeletes.entries) {
        try {
          final targetBox = rift.getBoxWithoutCheckInternal(entry.key);
          if (targetBox != null && targetBox.isOpen) {
            await targetBox.deleteAll(entry.value);
          }
        } catch (_) {
          // Target box may not be open; skip cascade
        }
      }
    }

    await performCompactionIfNeeded();
  }

  @override
  Future<void> flush() async {
    await backend.flush();
  }
}
