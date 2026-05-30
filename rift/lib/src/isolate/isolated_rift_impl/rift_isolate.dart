import 'dart:isolate';

import 'package:isolate_channel/isolate_channel.dart';
import 'package:meta/meta.dart';

/// Base class for managing the Rift isolate
///
/// Used for testing
abstract class RiftIsolate {
  /// Access to the isolate connection for testing
  @visibleForTesting
  IsolateConnection get connection;

  /// Override the isolate spawn method for testing
  @visibleForTesting
  set spawnRiftIsolate(Future<IsolateConnection> Function() spawnRiftIsolate);

  /// Called when the Rift isolate connects
  @visibleForTesting
  void onConnect(SendPort send);

  /// Called when the Rift isolate exits
  @visibleForTesting
  void onExit();
}
