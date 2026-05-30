/// The name of the special internal box used to store TTL metadata.
const String ttlBoxName = '__rift_ttl__';

/// Stores TTL metadata in a special internal box `__rift_ttl__`.
///
/// Format: key → expiry timestamp (milliseconds since epoch).
///
/// The key format used for storage is `boxName:key` to avoid collisions
/// between keys with the same name in different boxes.
///
/// This class provides an in-memory storage implementation. The TTL
/// metadata is persisted by the box itself (since `__rift_ttl__` is
/// a regular Rift box). If persistence is not needed, the metadata
/// is simply kept in memory and lost on restart.
class TTLStorage {
  /// In-memory storage: compositeKey → expiry timestamp (ms since epoch).
  ///
  /// Composite key format: `boxName:key`
  final Map<String, int> _expiryMap = {};

  /// Stores the expiry timestamp for a key in a box.
  ///
  /// [boxName] is the name of the box.
  /// [key] is the primary key of the entry.
  /// [expiryMs] is the expiry time as milliseconds since epoch.
  Future<void> setExpiry(String boxName, dynamic key, int expiryMs) async {
    final compositeKey = _makeCompositeKey(boxName, key);
    _expiryMap[compositeKey] = expiryMs;
  }

  /// Gets the expiry timestamp for a key in a box.
  ///
  /// Returns the expiry time as milliseconds since epoch, or null
  /// if no TTL is set for this key.
  int? getExpiry(String boxName, dynamic key) {
    final compositeKey = _makeCompositeKey(boxName, key);
    return _expiryMap[compositeKey];
  }

  /// Removes the expiry metadata for a key in a box.
  ///
  /// Returns true if the entry existed and was removed.
  Future<bool> removeExpiry(String boxName, dynamic key) async {
    final compositeKey = _makeCompositeKey(boxName, key);
    return _expiryMap.remove(compositeKey) != null;
  }

  /// Removes all expiry metadata for a box.
  ///
  /// Returns the number of entries removed.
  Future<int> removeAllExpiry(String boxName) async {
    final prefix = '$boxName:';
    final keysToRemove = _expiryMap.keys
        .where((key) => key.startsWith(prefix))
        .toList();

    for (final key in keysToRemove) {
      _expiryMap.remove(key);
    }

    return keysToRemove.length;
  }

  /// Gets all keys in a box that have TTL metadata set.
  ///
  /// Returns the primary keys (not composite keys) of entries
  /// that have TTL metadata.
  Iterable<dynamic> getKeysWithTTL(String boxName) {
    final prefix = '$boxName:';
    return _expiryMap.keys
        .where((compositeKey) => compositeKey.startsWith(prefix))
        .map((compositeKey) => _extractPrimaryKey(boxName, compositeKey));
  }

  /// Gets all expired keys for a box.
  ///
  /// Returns the primary keys of entries whose TTL has expired.
  List<dynamic> getExpiredKeys(String boxName) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final prefix = '$boxName:';
    final expiredKeys = <dynamic>[];

    final entries = _expiryMap.entries.toList();
    for (final entry in entries) {
      if (entry.key.startsWith(prefix) && entry.value <= now) {
        expiredKeys.add(_extractPrimaryKey(boxName, entry.key));
      }
    }

    return expiredKeys;
  }

  /// Gets the names of all boxes that have TTL metadata.
  Set<String> getAllBoxNames() {
    final boxNames = <String>{};
    for (final compositeKey in _expiryMap.keys) {
      final colonIndex = compositeKey.indexOf(':');
      if (colonIndex > 0) {
        boxNames.add(compositeKey.substring(0, colonIndex));
      }
    }
    return boxNames;
  }

  /// Checks if a key has TTL metadata set.
  bool hasTTL(String boxName, dynamic key) {
    final compositeKey = _makeCompositeKey(boxName, key);
    return _expiryMap.containsKey(compositeKey);
  }

  /// Gets the number of entries with TTL metadata for a box.
  int countEntriesWithTTL(String boxName) {
    final prefix = '$boxName:';
    return _expiryMap.keys.where((k) => k.startsWith(prefix)).length;
  }

  /// Clears all TTL metadata.
  void clear() {
    _expiryMap.clear();
  }

  /// Creates a composite key from box name and primary key.
  ///
  /// The composite key format is `boxName:key`. For string keys,
  /// this is straightforward. For non-string keys, the key is
  /// converted to a string representation.
  String _makeCompositeKey(String boxName, dynamic key) {
    return '$boxName:$key';
  }

  /// Extracts the primary key from a composite key.
  ///
  /// The composite key format is `boxName:key`. This method
  /// extracts the key portion after the box name prefix.
  dynamic _extractPrimaryKey(String boxName, String compositeKey) {
    final prefix = '$boxName:';
    if (compositeKey.startsWith(prefix)) {
      final keyStr = compositeKey.substring(prefix.length);

      // Try to parse as int for numeric keys
      final asInt = int.tryParse(keyStr);
      if (asInt != null) return asInt;

      return keyStr;
    }
    return compositeKey;
  }
}
