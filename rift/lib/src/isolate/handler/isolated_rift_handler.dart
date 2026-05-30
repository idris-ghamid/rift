import 'package:rift/rift.dart';
import 'package:rift/src/box/default_compaction_strategy.dart';
import 'package:rift/src/box/default_key_comparator.dart';
import 'package:rift/src/rift_impl.dart';
import 'package:rift/src/isolate/handler/isolated_box_handler.dart';
import 'package:rift/src/util/logger.dart';
import 'package:isolate_channel/isolate_channel.dart';

/// Method call handler for Rift methods
Future<dynamic> handleRiftMethodCall(
  IsolateMethodCall call,
  IsolateConnection connection,
  Map<String, IsolatedBoxHandler> boxHandlers,
) async {
  switch (call.method) {
    case 'init':
      Rift.init(call.arguments['path']);
      (Rift as RiftImpl).setIsolated();
      final loggerLevel = call.arguments['logger_level'];
      Logger.level = LoggerLevel.values.byName(loggerLevel);
    case 'openBox':
      final name = call.arguments['name'];
      final lazy = call.arguments['lazy'];

      if (boxHandlers.containsKey(name)) {
        // Ensure this is a valid `openBox` call
        if (lazy) {
          Rift.lazyBox(name);
        } else {
          Rift.box(name);
        }
        return;
      }

      final keyCrc = call.arguments['keyCrc'];
      final keyComparator =
          call.arguments['keyComparator'] ?? defaultKeyComparator;
      final compactionStrategy =
          call.arguments['compactionStrategy'] ?? defaultCompactionStrategy;
      final crashRecovery = call.arguments['crashRecovery'];
      final path = call.arguments['path'];
      final bytes = call.arguments['bytes'];
      final collection = call.arguments['collection'];

      final BoxBase box;
      if (lazy) {
        box = await (Rift as RiftImpl).openLazyBox(
          name,
          keyCrc: keyCrc,
          keyComparator: keyComparator,
          compactionStrategy: compactionStrategy,
          crashRecovery: crashRecovery,
          path: path,
          collection: collection,
        );
      } else {
        box = await (Rift as RiftImpl).openBox(
          name,
          keyCrc: keyCrc,
          keyComparator: keyComparator,
          compactionStrategy: compactionStrategy,
          crashRecovery: crashRecovery,
          path: path,
          bytes: bytes,
          collection: collection,
        );
      }

      boxHandlers[name] = IsolatedBoxHandler(box, connection);
    case 'deleteBoxFromDisk':
      await Rift.deleteBoxFromDisk(
        call.arguments['name'],
        path: call.arguments['path'],
      );
    case 'boxExists':
      return Rift.boxExists(
        call.arguments['name'],
        path: call.arguments['path'],
      );
    case 'unregisterBox':
      boxHandlers.remove(call.arguments['name']);
    default:
      return call.notImplemented();
  }
}
