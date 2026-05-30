import 'dart:async';

import 'package:rift/src/ttl/ttl_storage.dart';

/// Manages TTL (Time-To-Live) for box entries.
///
/// The [TTLManager] allows entries in Rift boxes to have an expiration
/// time. When an entry's TTL expires, it is considered deleted and
/// will return null on the next access.
///
/// TTL metadata is stored in a special internal box `__rift_ttl__`.
/// The format is: `boxName:key` → expiry timestamp (milliseconds since epoch).
///
/// Usage:
/// ```dart
/// // Store with TTL
/// await box.put('session', token, ttl: Duration(hours: 1));
///
/// // Entry automatically expires after 1 hour
/// // Next access returns null
///
/// // Check remaining TTL
/// final remaining = ttlManager.getRemainingTTL('sessions', 'session');
///
/// // Manually purge expired entries
/// await ttlManager.purgeExpired('sessions');
///
/// // Start background purge timer
/// ttlManager.startPurgeTimer(interval: Duration(seconds: 30));
/// ```
class TTLManager {
  /// The storage backend for TTL metadata.
  final TTLStorage _storage;

  /// The background purge timer.
  Timer? _purgeTimer;

  /// Default purge interval.
  static const Duration _defaultPurgeInterval = Duration(seconds: 60);

  /// Callback for when an entry expires during purge.
  /// This allows the box to be notified so it can clean up.
  final void Function(String boxName, dynamic key)? onExpired;

  /// Creates a new TTL manager.
  ///
  /// [storage] is the TTL metadata storage.
  /// [onExpired] is an optional callback invoked when an entry
  /// is found to be expired during a purge operation.
  TTLManager({required TTLStorage storage, this.onExpired})
    : _storage = storage;

  /// Stores TTL metadata for a key.
  ///
  /// [boxName] is the name of the box containing the entry.
  /// [key] is the primary key of the entry.
  /// [ttl] is the time-to-live duration from now.
  Future<void> setTTL(String boxName, dynamic key, Duration ttl) async {
    final expiryMs = DateTime.now().millisecondsSinceEpoch + ttl.inMilliseconds;
    await _storage.setExpiry(boxName, key, expiryMs);
  }

  /// Gets the remaining TTL for a key.
  ///
  /// Returns the remaining duration before the key expires, or null if:
  /// - The key has no TTL set
  /// - The key has already expired
  Duration? getRemainingTTL(String boxName, dynamic key) {
    final expiryMs = _storage.getExpiry(boxName, key);
    if (expiryMs == null) return null;

    final remaining = expiryMs - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) return null;

    return Duration(milliseconds: remaining);
  }

  /// Checks if a key has expired.
  ///
  /// Returns true if the key has a TTL and it has expired.
  /// Returns false if the key has no TTL or hasn't expired yet.
  bool isExpired(String boxName, dynamic key) {
    final expiryMs = _storage.getExpiry(boxName, key);
    if (expiryMs == null) return false;

    return DateTime.now().millisecondsSinceEpoch >= expiryMs;
  }

  /// Removes expired entries from the given box.
  ///
  /// This method scans all TTL metadata entries for the given box
  /// and deletes any entries that have expired. For each expired
  /// entry, the [onExpired] callback is invoked (if set) so that
  /// the calling code can also remove the entry from the actual box.
  ///
  /// Returns the number of entries that were purged.
  Future<int> purgeExpired(String boxName) async {
    final expiredKeys = _storage.getExpiredKeys(boxName);
    var count = 0;

    for (final key in expiredKeys) {
      await _storage.removeExpiry(boxName, key);
      onExpired?.call(boxName, key);
      count++;
    }

    return count;
  }

  /// Purges all expired entries across all boxes.
  ///
  /// Returns the total number of entries purged across all boxes.
  Future<int> purgeAllExpired() async {
    final boxNames = _storage.getAllBoxNames();
    var totalCount = 0;

    for (final boxName in boxNames) {
      totalCount += await purgeExpired(boxName);
    }

    return totalCount;
  }

  /// Starts a background purge timer that periodically removes
  /// expired entries.
  ///
  /// [interval] is the time between purge runs. Defaults to 60 seconds.
  ///
  /// If a timer is already running, it is stopped and replaced with
  /// a new one.
  void startPurgeTimer({Duration interval = _defaultPurgeInterval}) {
    stopPurgeTimer();
    _purgeTimer = Timer.periodic(interval, (_) async {
      await purgeAllExpired();
    });
  }

  /// Stops the background purge timer.
  ///
  /// Does nothing if no timer is running.
  void stopPurgeTimer() {
    _purgeTimer?.cancel();
    _purgeTimer = null;
  }

  /// Checks if the background purge timer is running.
  bool get isPurgeTimerRunning => _purgeTimer != null;

  /// Removes the TTL metadata for a key.
  ///
  /// This is called when a key is manually deleted from a box.
  Future<void> removeTTL(String boxName, dynamic key) async {
    await _storage.removeExpiry(boxName, key);
  }

  /// Removes all TTL metadata for a box.
  ///
  /// This is called when a box is cleared.
  Future<void> removeAllTTL(String boxName) async {
    await _storage.removeAllExpiry(boxName);
  }

  /// Gets the expiry timestamp for a key.
  ///
  /// Returns the expiry time as milliseconds since epoch, or null
  /// if no TTL is set.
  int? getExpiryTimestamp(String boxName, dynamic key) {
    return _storage.getExpiry(boxName, key);
  }

  /// Gets all keys in a box that have TTL set.
  ///
  /// Returns an iterable of keys that have TTL metadata.
  Iterable<dynamic> getKeysWithTTL(String boxName) {
    return _storage.getKeysWithTTL(boxName);
  }

  /// Disposes the TTL manager, stopping any running timers.
  void dispose() {
    stopPurgeTimer();
  }
}
