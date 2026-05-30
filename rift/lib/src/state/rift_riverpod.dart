import 'package:rift/src/box/box.dart';

/// Riverpod integration for Rift boxes.
/// Provides providers that automatically update when box data changes.
///
/// Note: This is a standalone integration file. Users import it optionally.
/// It does NOT depend on riverpod directly - it provides the interface
/// and helpers that can be used with any Riverpod-based application.
///
/// Usage:
/// ```dart
/// // Create a config for a Riverpod provider
/// final config = RiftBoxProviderConfig<User>(
///   boxName: 'users',
///   defaultValue: User.empty(),
///   keepAlive: true,
/// );
///
/// // Watch a specific key
/// final stream = RiftRiverpodHelper.watchKey<User>(box, 'user_1');
/// stream.listen((user) => print('User updated: $user'));
///
/// // Watch all changes
/// final allStream = RiftRiverpodHelper.watchAll(box);
/// allStream.listen((state) => print('Box changed: $state'));
/// ```

/// Configuration for creating a Riverpod provider for a Rift box.
///
/// This class encapsulates the configuration needed to create a Riverpod
/// provider that wraps a Rift box. It can be used as a template for
/// creating Riverpod `NotifierProvider` or `StateNotifierProvider` instances.
class RiftBoxProviderConfig<T> {
  /// The name of the Rift box to connect to.
  final String boxName;

  /// Default value to use when the box or key is empty.
  final T? defaultValue;

  /// Whether the provider should stay alive when no longer watched.
  final bool keepAlive;

  /// Create a [RiftBoxProviderConfig].
  RiftBoxProviderConfig({
    required this.boxName,
    this.defaultValue,
    this.keepAlive = true,
  });
}

/// Helper to create Riverpod-compatible notifiers for Rift boxes.
///
/// This class provides static methods that convert Rift box data and events
/// into formats compatible with Riverpod's state management model.
///
/// The helper doesn't depend on Riverpod directly, making it safe to use
/// in any project. The returned streams and maps can be consumed by
/// Riverpod's `StreamNotifier` or `AsyncNotifier` patterns.
class RiftRiverpodHelper {
  /// Create a map of box values that can be used as state in any
  /// state management solution.
  ///
  /// Returns a snapshot of the current box contents as a [Map].
  static Map<dynamic, dynamic> boxToState(Box box) => box.toMap();

  /// Watch a specific key in a box and get notified of changes.
  ///
  /// Returns a [Stream] that emits the new value every time the
  /// specified [key] changes. The stream casts values to type [T].
  ///
  /// Usage:
  /// ```dart
  /// final userStream = RiftRiverpodHelper.watchKey<User>(box, 'user_1');
  /// userStream.listen((user) {
  ///   // Update Riverpod state
  /// });
  /// ```
  static Stream<T> watchKey<T>(Box box, String key) {
    return box.watch(key: key).map((event) => event.value as T);
  }

  /// Watch all changes in a box.
  ///
  /// Returns a [Stream] that emits the full box state as a [Map]
  /// every time any value in the box changes.
  ///
  /// Usage:
  /// ```dart
  /// final stateStream = RiftRiverpodHelper.watchAll(box);
  /// stateStream.listen((state) {
  ///   // Update Riverpod state with full box snapshot
  /// });
  /// ```
  static Stream<Map<dynamic, dynamic>> watchAll(Box box) {
    return box.watch().map((_) => box.toMap());
  }

  /// Watch a specific key and provide a default value when the key
  /// is deleted or doesn't exist.
  ///
  /// Unlike [watchKey], this never emits null — it substitutes
  /// [defaultValue] whenever the value is null (key deleted).
  static Stream<T> watchKeyWithDefault<T>(
    Box box,
    String key, {
    required T defaultValue,
  }) {
    return box.watch(key: key).map((event) {
      if (event.deleted || event.value == null) return defaultValue;
      return event.value as T;
    });
  }
}
