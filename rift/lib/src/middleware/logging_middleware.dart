import 'package:rift/src/middleware/middleware.dart';

/// Log level for the logging middleware.
enum LogLevel {
  /// No logging.
  none,

  /// Log only errors and vetoes.
  error,

  /// Log all operations (put, delete, clear).
  info,

  /// Log all operations with full value details.
  debug,
}

/// Built-in logging middleware that logs all box operations.
///
/// The logging middleware outputs information about every put, delete,
/// and clear operation, including the box name, key, and (optionally)
/// the value.
///
/// Usage:
/// ```dart
/// // Basic logging
/// rift.use(LoggingMiddleware());
///
/// // With custom log level
/// rift.use(LoggingMiddleware(level: LogLevel.debug));
///
/// // With custom logger function
/// rift.use(LoggingMiddleware(
///   logger: (message) => myLogger.info(message),
/// ));
/// ```
class LoggingMiddleware extends RiftMiddleware {
  /// The log level.
  final LogLevel level;

  /// Custom logger function.
  ///
  /// If not provided, defaults to [print].
  final void Function(String message) logger;

  /// Whether to include values in log output.
  ///
  /// When true, the full value of put operations is logged.
  /// When false (default), only the key is logged for brevity.
  final bool includeValues;

  /// Whether to include timestamps in log output.
  final bool includeTimestamps;

  LoggingMiddleware({
    this.level = LogLevel.info,
    void Function(String message)? logger,
    this.includeValues = false,
    this.includeTimestamps = true,
  }) : logger = logger ?? _defaultLogger;

  static void _defaultLogger(String message) => print(message);

  String _prefix() {
    if (includeTimestamps) {
      final now = DateTime.now().toUtc().toIso8601String();
      return '[Rift:$now]';
    }
    return '[Rift]';
  }

  @override
  String get name => 'LoggingMiddleware';

  @override
  Future<bool> beforePut(String boxName, dynamic key, dynamic value) async {
    if (level == LogLevel.none) return true;

    if (level.index >= LogLevel.info.index) {
      if (includeValues) {
        logger('${_prefix()} BEFORE PUT box=$boxName key=$key value=$value');
      } else {
        logger('${_prefix()} BEFORE PUT box=$boxName key=$key');
      }
    }

    return true;
  }

  @override
  Future<void> afterPut(String boxName, dynamic key, dynamic value) async {
    if (level == LogLevel.none) return;

    if (level.index >= LogLevel.info.index) {
      if (includeValues) {
        logger('${_prefix()} AFTER PUT box=$boxName key=$key value=$value');
      } else {
        logger('${_prefix()} AFTER PUT box=$boxName key=$key');
      }
    }
  }

  @override
  Future<bool> beforeDelete(String boxName, dynamic key) async {
    if (level == LogLevel.none) return true;

    if (level.index >= LogLevel.info.index) {
      logger('${_prefix()} BEFORE DELETE box=$boxName key=$key');
    }

    return true;
  }

  @override
  Future<void> afterDelete(String boxName, dynamic key) async {
    if (level == LogLevel.none) return;

    if (level.index >= LogLevel.info.index) {
      logger('${_prefix()} AFTER DELETE box=$boxName key=$key');
    }
  }

  @override
  Future<bool> beforeClear(String boxName) async {
    if (level == LogLevel.none) return true;

    if (level.index >= LogLevel.info.index) {
      logger('${_prefix()} BEFORE CLEAR box=$boxName');
    }

    return true;
  }

  @override
  Future<void> afterClear(String boxName) async {
    if (level == LogLevel.none) return;

    if (level.index >= LogLevel.info.index) {
      logger('${_prefix()} AFTER CLEAR box=$boxName');
    }
  }
}
