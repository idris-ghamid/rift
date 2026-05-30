import 'dart:async';

import 'package:rift/src/isolate/isolate_debug_name/isolate_debug_name.dart';
import 'package:rift/src/util/debug_utils.dart';

// Dispatch through the current zone so that callers (most importantly tests)
// can intercept log output via Zone print specifications. The top-level
// `print` function relies on the global `printToZone` mutable field, which is
// only set as a side-effect of `_rootFork`. When `printToZone` is null in the
// current isolate, `print` writes directly to stdout, bypassing any zone
// `print` handler installed by `runZoned` and causing race-condition flakes
// in tests that use `captureOutput`.
void _zonePrint(Object? message) => Zone.current.print('$message');

/// Configures the logging behavior of Rift
abstract class Logger {
  /// The overall logging level
  static var level = kDebugMode ? LoggerLevel.debug : LoggerLevel.info;

  /// If the big int warning is enabled
  static var bigIntWarning = true;

  /// If the unsafe isolate warning is enabled
  static var unsafeIsolateWarning = true;

  /// If the unmatched isolation warning is enabled
  static var unmatchedIsolationWarning = true;

  /// If the no isolate name server warning is enabled
  static var noIsolateNameServerWarning = true;

  /// If the crc recompute warning is enabled
  static var crcRecomputeWarning = true;

  /// Log a verbose message
  static void v(Object? message) {
    if (level.index > LoggerLevel.verbose.index) return;
    _zonePrint(message);
  }

  /// Log a debug message
  static void d(Object? message) {
    if (level.index > LoggerLevel.debug.index) return;
    _zonePrint(message);
  }

  /// Log an informational message
  static void i(Object? message) {
    if (level.index > LoggerLevel.info.index) return;
    _zonePrint(message);
  }

  /// Log a warning message
  static void w(Object? message) {
    if (level.index > LoggerLevel.warn.index) return;
    _zonePrint(message);
  }

  /// Log an error message
  static void e(Object? message) {
    if (level.index > LoggerLevel.error.index) return;
    _zonePrint(message);
  }

  /// Log a message for an event that should not be possible
  static void wtf(Object? message) => _zonePrint(message);
}

/// Logging levels for Rift
enum LoggerLevel {
  /// All log messages
  verbose,

  /// Debug log messages
  debug,

  /// Informational log messages
  info,

  /// Warnings
  warn,

  /// Errors
  error,
}

/// Warning messages from Rift
abstract class RiftWarning {
  const RiftWarning._();

  /// Warning message printed when attempting to store an integer that is too large
  static const bigInt =
      'WARNING: Writing integer values greater than 2^53 will result in precision loss.'
      ' This is due to Rift storing all numbers as 64 bit floats.'
      ' Consider using a BigInt.';

  /// Warning message printed when accessing Rift from an unsafe isolate
  static final unsafeIsolate =
      '''
⚠️ WARNING: RIFT MULTI-ISOLATE RISK DETECTED ⚠️

Accessing Rift from an unsafe isolate (current isolate: "$isolateDebugName")
This can lead to DATA CORRUPTION as Rift boxes are not designed for concurrent
access across isolates. Each isolate would maintain its own box cache,
potentially causing data inconsistency and corruption.

RECOMMENDED ACTIONS:
- Use IsolatedRift instead

''';

  /// Warning for existing lock of unmatched isolation
  static const unmatchedIsolation = '''
⚠️ WARNING: RIFT MULTI-ISOLATE RISK DETECTED ⚠️

You are opening this box with Rift, but this box was previously opened with
IsolatedRift. This can lead to DATA CORRUPTION as Rift boxes are not designed
for concurrent access across isolates. Each isolate would maintain its own box
cache, potentially causing data inconsistency and corruption.

RECOMMENDED ACTIONS:
- ALWAYS use IsolatedRift to perform box operations when working with multiple
  isolates
''';

  /// Warning message printed when using [IsolatedRift] without an [IsolateNameServer]
  static final noIsolateNameServer = '''
⚠️ WARNING: RIFT MULTI-ISOLATE RISK DETECTED ⚠️

Using IsolatedRift without an IsolateNameServer is unsafe. This can lead to
DATA CORRUPTION as Rift boxes are not designed for concurrent access across
isolates. Using an IsolateNameServer allows IsolatedRift to maintain a single
isolate for all Rift operations.

RECOMMENDED ACTIONS:
- Initialize IsolatedRift with IsolatedRift.initFlutter from rift_flutter
- Provide your own IsolateNameServer

''';

  /// Warning message printed when CRC recompute is needed
  static const crcRecomputeNeeded =
      'WARNING: CRC recompute needed for frame.'
      ' This happens when IsolatedRift was used with encryption before it was properly handled.'
      ' IsolatedRift will continue to work, but read performance may be degraded for old entries.'
      ' To restore performance, rewrite all box entries.'
      ' This only needs to be done once.'
      '\n\nEXAMPLE:\n'
      '''
for (final key in await box.keys) {
  await box.put(key, await box.get(key));
}''';
}
