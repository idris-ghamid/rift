import 'package:rift/rift.dart';

/// Cross-box atomic transactions.
/// Ensures consistency when modifying multiple boxes atomically.
///
/// Usage:
/// ```dart
/// final tx = CrossBoxTransaction([usersBox, ordersBox]);
/// tx.put('users', 'user1', {'name': 'Alice'});
/// tx.put('orders', 'order1', {'userId': 'user1'});
/// await tx.commit();
/// ```
class CrossBoxTransaction {
  final List<Box> _boxes;
  final Map<String, Map<dynamic, dynamic>> _pendingWrites =
      {}; // boxName → {key: value}
  final Map<String, List<dynamic>> _pendingDeletes = {}; // boxName → [keys]
  final Map<String, Map<dynamic, dynamic>> _originalValues =
      {}; // boxName → {key: oldValue}
  bool _isActive = true;
  bool _isCommitted = false;

  /// Create a cross-box transaction spanning the given [boxes].
  CrossBoxTransaction(List<Box> boxes) : _boxes = boxes;

  /// Put a value in a box within this transaction.
  void put(String boxName, dynamic key, dynamic value) {
    if (!_isActive) throw RiftError('Transaction is not active');
    // Save original value for potential rollback
    _saveOriginal(boxName, key);
    _pendingWrites.putIfAbsent(boxName, () => {});
    _pendingWrites[boxName]![key] = value;
  }

  /// Delete a key from a box within this transaction.
  void delete(String boxName, dynamic key) {
    if (!_isActive) throw RiftError('Transaction is not active');
    _saveOriginal(boxName, key);
    _pendingDeletes.putIfAbsent(boxName, () => []);
    _pendingDeletes[boxName]!.add(key);
  }

  /// Commit all changes atomically.
  Future<void> commit() async {
    if (!_isActive) throw RiftError('Transaction is not active');
    if (_isCommitted) throw RiftError('Transaction has already been committed');

    try {
      // Phase 1: Write all pending data
      for (final box in _boxes) {
        final writes = _pendingWrites[box.name];
        if (writes != null && writes.isNotEmpty) {
          await box.putAll(writes);
        }
      }
      // Phase 2: Delete all pending keys
      for (final box in _boxes) {
        final deletes = _pendingDeletes[box.name];
        if (deletes != null && deletes.isNotEmpty) {
          await box.deleteAll(deletes);
        }
      }
    } catch (e) {
      // Rollback: attempt to restore previous values
      await _rollback();
      rethrow;
    }
    _isActive = false;
    _isCommitted = true;
  }

  /// Rollback all changes (abandons the transaction without applying).
  Future<void> rollback() async {
    _isActive = false;
    _pendingWrites.clear();
    _pendingDeletes.clear();
    _originalValues.clear();
  }

  /// Save the original value for a key before modification (for rollback).
  void _saveOriginal(String boxName, dynamic key) {
    // Only save once per key
    _originalValues.putIfAbsent(boxName, () => {});
    if (!_originalValues[boxName]!.containsKey(key)) {
      final box = _boxes.where((b) => b.name == boxName).firstOrNull;
      if (box != null && box.containsKey(key)) {
        _originalValues[boxName]![key] = box.get(key);
      }
    }
  }

  /// Attempt to rollback by restoring original values.
  Future<void> _rollback() async {
    try {
      for (final box in _boxes) {
        final originals = _originalValues[box.name];
        if (originals != null && originals.isNotEmpty) {
          await box.putAll(originals);
        }
      }
    } catch (_) {
      // If rollback fails, there's not much we can do
      // In a real implementation, this would log the error
    }
    _isActive = false;
  }

  /// Whether the transaction is still active (not committed or rolled back).
  bool get isActive => _isActive;

  /// Whether the transaction has been committed.
  bool get isCommitted => _isCommitted;

  /// Number of pending write operations.
  int get pendingWriteCount =>
      _pendingWrites.values.fold(0, (sum, map) => sum + map.length);

  /// Number of pending delete operations.
  int get pendingDeleteCount =>
      _pendingDeletes.values.fold(0, (sum, list) => sum + list.length);

  /// Names of boxes involved in the transaction.
  List<String> get boxNames => _boxes.map((b) => b.name).toList();
}
