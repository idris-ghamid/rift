/// Middleware can intercept and modify database operations.
///
/// Middleware provides a hook system that allows you to add cross-cutting
/// concerns to Rift box operations. Each middleware can intercept
/// before and after every put, delete, and clear operation.
///
/// Before-hooks can cancel an operation by returning false.
/// After-hooks are notified after the operation completes.
///
/// Middleware is executed in the order it is added. Before-hooks run
/// first-to-last; after-hooks run last-to-first (like a stack).
///
/// Usage:
/// ```dart
/// rift.use(LoggingMiddleware()); // Log all operations
/// rift.use(ValidationMiddleware(schema)); // Validate before write
/// rift.use(SyncMiddleware(remote)); // Sync to remote server
/// rift.use(CachingMiddleware(cache)); // Cache frequently read data
/// ```
abstract class RiftMiddleware {
  /// Optional name for debugging purposes.
  String get name => runtimeType.toString();

  /// Called before a put operation.
  ///
  /// Return true to allow the operation, false to cancel it.
  /// If any middleware returns false, the put is cancelled.
  Future<bool> beforePut(String boxName, dynamic key, dynamic value);

  /// Called after a put operation completes successfully.
  Future<void> afterPut(String boxName, dynamic key, dynamic value);

  /// Called before a delete operation.
  ///
  /// Return true to allow the operation, false to cancel it.
  /// If any middleware returns false, the delete is cancelled.
  Future<bool> beforeDelete(String boxName, dynamic key);

  /// Called after a delete operation completes successfully.
  Future<void> afterDelete(String boxName, dynamic key);

  /// Called before a box is cleared.
  ///
  /// Return true to allow the operation, false to cancel it.
  /// If any middleware returns false, the clear is cancelled.
  Future<bool> beforeClear(String boxName);

  /// Called after a box is cleared successfully.
  Future<void> afterClear(String boxName);
}

/// A chain of middleware that processes box operations.
///
/// The [MiddlewareChain] manages an ordered list of [RiftMiddleware]
/// instances and provides methods to run the before/after hooks for
/// each operation type.
///
/// Before-hooks are executed in order (first added, first executed).
/// If any before-hook returns false, the chain stops and the operation
/// is cancelled.
///
/// After-hooks are executed in reverse order (last added, first executed)
/// to unwind the middleware stack properly.
class MiddlewareChain {
  /// The ordered list of middleware.
  final List<RiftMiddleware> _middlewares = [];

  /// Gets an unmodifiable view of the current middleware list.
  List<RiftMiddleware> get middlewares => List.unmodifiable(_middlewares);

  /// Adds a middleware to the chain.
  ///
  /// Middleware are executed in the order they are added.
  void add(RiftMiddleware middleware) {
    _middlewares.add(middleware);
  }

  /// Removes a middleware from the chain.
  ///
  /// Does nothing if the middleware is not in the chain.
  void remove(RiftMiddleware middleware) {
    _middlewares.remove(middleware);
  }

  /// Removes all middleware from the chain.
  void clear() {
    _middlewares.clear();
  }

  /// The number of middleware in the chain.
  int get length => _middlewares.length;

  /// Whether the chain has any middleware.
  bool get isEmpty => _middlewares.isEmpty;

  /// Whether the chain has middleware.
  bool get isNotEmpty => _middlewares.isNotEmpty;

  /// Runs before-put hooks for all middleware.
  ///
  /// Returns true if all middleware allow the operation,
  /// false if any middleware vetoes it.
  Future<bool> runBeforePut(String boxName, dynamic key, dynamic value) async {
    for (final middleware in _middlewares) {
      try {
        final allowed = await middleware.beforePut(boxName, key, value);
        if (!allowed) return false;
      } catch (e) {
        // If a middleware throws, treat it as a veto
        return false;
      }
    }
    return true;
  }

  /// Runs after-put hooks for all middleware (in reverse order).
  Future<void> runAfterPut(String boxName, dynamic key, dynamic value) async {
    for (final middleware in _middlewares.reversed) {
      try {
        await middleware.afterPut(boxName, key, value);
      } catch (_) {
        // After-hooks should not prevent other middleware from running.
        // Swallow errors to continue the chain.
      }
    }
  }

  /// Runs before-delete hooks for all middleware.
  ///
  /// Returns true if all middleware allow the operation,
  /// false if any middleware vetoes it.
  Future<bool> runBeforeDelete(String boxName, dynamic key) async {
    for (final middleware in _middlewares) {
      try {
        final allowed = await middleware.beforeDelete(boxName, key);
        if (!allowed) return false;
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  /// Runs after-delete hooks for all middleware (in reverse order).
  Future<void> runAfterDelete(String boxName, dynamic key) async {
    for (final middleware in _middlewares.reversed) {
      try {
        await middleware.afterDelete(boxName, key);
      } catch (_) {
        // Swallow errors to continue the chain.
      }
    }
  }

  /// Runs before-clear hooks for all middleware.
  ///
  /// Returns true if all middleware allow the operation,
  /// false if any middleware vetoes it.
  Future<bool> runBeforeClear(String boxName) async {
    for (final middleware in _middlewares) {
      try {
        final allowed = await middleware.beforeClear(boxName);
        if (!allowed) return false;
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  /// Runs after-clear hooks for all middleware (in reverse order).
  Future<void> runAfterClear(String boxName) async {
    for (final middleware in _middlewares.reversed) {
      try {
        await middleware.afterClear(boxName);
      } catch (_) {
        // Swallow errors to continue the chain.
      }
    }
  }
}
