import 'dart:async';

import 'package:rift/rift.dart';
import 'package:rift/src/binary/frame.dart';
import 'package:rift/src/box/box_base_impl.dart';
import 'package:rift/src/object/rift_object.dart';

/// Not part of public API
class BoxImpl<E> extends BoxBaseImpl<E> implements Box<E> {
  /// Not part of public API
  BoxImpl(
    super.rift,
    super.name,
    super.keyComparator,
    super.compactionStrategy,
    super.backend, {
    super.isolated = false,
  });

  @override
  final lazy = false;

  @override
  Iterable<E> get values {
    checkOpen();

    return keystore.getValues();
  }

  @override
  Iterable<E> valuesBetween({dynamic startKey, dynamic endKey}) {
    checkOpen();

    return keystore.getValuesBetween(startKey, endKey);
  }

  @override
  E? get(dynamic key, {E? defaultValue}) {
    checkOpen();

    // Check TTL expiry — return default if expired
    if (BoxBaseImpl.ttlManager.isExpired(name, key)) {
      // Lazily purge the expired entry
      BoxBaseImpl.ttlManager.removeTTL(name, key);
      if (defaultValue != null && defaultValue is RiftObjectMixin) {
        defaultValue.init(key, this);
      }
      return defaultValue;
    }

    final frame = keystore.get(key);
    if (frame != null) {
      return frame.value as E?;
    } else {
      if (defaultValue != null && defaultValue is RiftObjectMixin) {
        defaultValue.init(key, this);
      }
      return defaultValue;
    }
  }

  @override
  E? getAt(int index) {
    checkOpen();

    final frame = keystore.getAt(index);
    if (frame != null && BoxBaseImpl.ttlManager.isExpired(name, frame.key)) {
      // Lazily purge the expired entry
      BoxBaseImpl.ttlManager.removeTTL(name, frame.key);
      return null;
    }
    return frame?.value as E?;
  }

  @override
  Future<void> putAll(Map<dynamic, E> kvPairs) async {
    // Run before-put middleware for each entry
    if (BoxBaseImpl.middlewareChain.isNotEmpty) {
      for (final entry in kvPairs.entries) {
        final allowed = await BoxBaseImpl.middlewareChain.runBeforePut(
          name,
          entry.key,
          entry.value,
        );
        if (!allowed) {
          // Remove vetoed entries from the batch
          kvPairs = Map.from(kvPairs)..remove(entry.key);
        }
      }
    }

    if (kvPairs.isEmpty) return;

    final frames = <Frame>[];
    for (final key in kvPairs.keys) {
      frames.add(Frame(key, kvPairs[key]));
    }

    await _writeFrames(frames);

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
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
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
      final oldValue = keystore.get(key)?.value;
      BoxBaseImpl.relationManager.onDelete(name, key, oldValue);
      await BoxBaseImpl.ttlManager.removeTTL(name, key);
    }

    final frames = <Frame>[];
    for (final key in keysToDelete) {
      if (keystore.containsKey(key)) {
        frames.add(Frame.deleted(key));
      }
    }

    await _writeFrames(frames);

    // Run after-delete middleware
    if (BoxBaseImpl.middlewareChain.isNotEmpty) {
      for (final key in keysToDelete) {
        await BoxBaseImpl.middlewareChain.runAfterDelete(name, key);
      }
    }

    // Apply cascade deletes to target boxes
    // (This would require access to other boxes; in practice the Rift
    // instance handles this at a higher level)
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
  }

  Future<void> _writeFrames(List<Frame> frames) async {
    checkOpen();

    // Capture old values for index updates before the transaction modifies them
    final oldValues = <dynamic, dynamic>{};
    for (final frame in frames) {
      if (keystore.containsKey(frame.key)) {
        final existingFrame = keystore.get(frame.key);
        if (existingFrame != null) {
          oldValues[frame.key] = existingFrame.value;
        }
      }
    }

    if (!keystore.beginTransaction(frames)) return;

    try {
      await backend.writeFrames(frames, verbatim: isolated);
      keystore.commitTransaction();
    } catch (e) {
      keystore.cancelTransaction();
      rethrow;
    }

    // Update indexes after successful write
    for (final frame in frames) {
      if (frame.deleted) {
        // Remove from index — use the old value we captured
        await globalIndexManager.removeFromIndex(
          name,
          frame.key,
          oldValues[frame.key],
        );
      } else {
        // If this was an update (overwriting existing key), remove old value first
        if (oldValues.containsKey(frame.key)) {
          await globalIndexManager.removeFromIndex(
            name,
            frame.key,
            oldValues[frame.key],
          );
        }
        // Add new value to index
        await globalIndexManager.updateIndex(name, frame.key, frame.value);
        // Notify relation manager of the put
        BoxBaseImpl.relationManager.onPut(name, frame.key, frame.value);
      }
    }

    await performCompactionIfNeeded();
  }

  @override
  Map<dynamic, E> toMap() {
    final map = <dynamic, E>{};
    for (final frame in keystore.frames) {
      map[frame.key] = frame.value as E;
    }
    return map;
  }

  @override
  Future<void> flush() async {
    await backend.flush();
  }
}
