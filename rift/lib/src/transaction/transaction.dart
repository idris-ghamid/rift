import 'package:meta/meta.dart';
import 'package:rift/src/rift_error.dart';

/// Types of operations that can be recorded in a transaction.
enum _TransactionOpType {
  /// Insert or update a single key-value pair.
  put,

  /// Delete a single key.
  delete,

  /// Insert or update multiple key-value pairs.
  putAll,

  /// Delete multiple keys.
  deleteAll,

  /// Clear all entries.
  clear,
}

/// Represents a single operation within a transaction.
@immutable
class _TransactionOp {
  /// The type of operation.
  final _TransactionOpType type;

  /// The key for single-key operations (put, delete).
  final String? key;

  /// The value for put operations.
  final dynamic value;

  /// The entries for putAll operations.
  final Map<String, dynamic>? entries;

  /// The keys for deleteAll operations.
  final List<String>? keys;

  _TransactionOp({
    required this.type,
    this.key,
    this.value,
    this.entries,
    this.keys,
  });
}

/// A named savepoint within a transaction that can be rolled back to.
///
/// Savepoints allow partial rollbacks within a transaction without
/// aborting the entire transaction.
class _SavePoint {
  /// The name of this savepoint.
  final String name;

  /// The index in the operation list at which this savepoint was created.
  final int opIndex;

  _SavePoint(this.name, this.opIndex);
}

/// Represents an ACID transaction that can be committed or rolled back.
///
/// Transactions provide atomic, consistent, isolated, and durable operations
/// on Rift boxes. Operations are recorded in the transaction and only applied
/// when the transaction is committed. If the transaction is rolled back, all
/// recorded operations are discarded.
///
/// Savepoints allow creating intermediate checkpoints within a transaction.
/// Rolling back to a savepoint discards only the operations recorded after
/// the savepoint was created, preserving earlier operations.
///
/// Usage:
/// ```dart
/// final tx = txManager.begin();
/// try {
///   tx.put('user_1', {'name': 'Alice', 'age': 30});
///   tx.savepoint('after_user');
///   tx.put('user_2', {'name': 'Bob', 'age': 25});
///   tx.rollbackTo('after_user');
///   tx.put('user_2', {'name': 'Robert', 'age': 25});
///   txManager.commit(tx);
/// } catch (e) {
///   txManager.rollback(tx);
/// }
/// ```
class RiftTransaction {
  /// Unique identifier for this transaction.
  final String id;

  /// Timestamp when this transaction was created.
  final DateTime startedAt;

  /// Ordered list of savepoints created within this transaction.
  final List<_SavePoint> _savepoints = [];

  /// Ordered list of operations recorded in this transaction.
  final List<_TransactionOp> _operations = [];

  /// Whether this transaction is still active (can accept new operations).
  bool _isActive = true;

  /// Whether this transaction has been successfully committed.
  bool _isCommitted = false;

  RiftTransaction(this.id) : startedAt = DateTime.now();

  /// Whether this transaction is still active and can accept operations.
  bool get isActive => _isActive;

  /// Whether this transaction has been successfully committed.
  bool get isCommitted => _isCommitted;

  /// An unmodifiable view of all operations recorded in this transaction.
  List<_TransactionOp> get operations => List.unmodifiable(_operations);

  /// The number of operations recorded in this transaction.
  int get operationCount => _operations.length;

  /// The number of savepoints currently active in this transaction.
  int get savepointCount => _savepoints.length;

  /// Validates that this transaction is still active before performing
  /// an operation. Throws [RiftError] if the transaction is not active.
  void _requireActive() {
    if (!_isActive) {
      throw RiftError('Transaction $id is not active');
    }
  }

  /// Records a put operation in this transaction.
  void put(String key, dynamic value) {
    _requireActive();
    _operations.add(
      _TransactionOp(type: _TransactionOpType.put, key: key, value: value),
    );
  }

  /// Records a delete operation in this transaction.
  void delete(String key) {
    _requireActive();
    _operations.add(_TransactionOp(type: _TransactionOpType.delete, key: key));
  }

  /// Records a putAll operation in this transaction.
  void putAll(Map<String, dynamic> entries) {
    _requireActive();
    _operations.add(
      _TransactionOp(
        type: _TransactionOpType.putAll,
        entries: Map<String, dynamic>.from(entries),
      ),
    );
  }

  /// Records a deleteAll operation in this transaction.
  void deleteAll(List<String> keys) {
    _requireActive();
    _operations.add(
      _TransactionOp(
        type: _TransactionOpType.deleteAll,
        keys: List<String>.from(keys),
      ),
    );
  }

  /// Records a clear operation in this transaction.
  void clear() {
    _requireActive();
    _operations.add(_TransactionOp(type: _TransactionOpType.clear));
  }

  /// Creates a named savepoint at the current position in the transaction.
  ///
  /// Returns the name of the savepoint for use with [rollbackTo].
  ///
  /// Throws [RiftError] if the transaction is not active.
  /// Throws [RiftError] if a savepoint with the same name already exists.
  String savepoint(String name) {
    _requireActive();
    if (_savepoints.any((s) => s.name == name)) {
      throw RiftError('Savepoint $name already exists in transaction $id');
    }
    final sp = _SavePoint(name, _operations.length);
    _savepoints.add(sp);
    return name;
  }

  /// Rolls back all operations recorded after the named savepoint.
  ///
  /// Throws [RiftError] if the transaction is not active.
  /// Throws [RiftError] if no savepoint with the given [name] exists.
  void rollbackTo(String name) {
    _requireActive();
    final spIndex = _savepoints.lastIndexWhere((s) => s.name == name);
    if (spIndex == -1) {
      throw RiftError('Savepoint $name not found in transaction $id');
    }
    final sp = _savepoints[spIndex];
    _operations.removeRange(sp.opIndex, _operations.length);
    _savepoints.removeRange(spIndex, _savepoints.length);
  }

  /// Rolls back the entire transaction, discarding all operations
  /// and savepoints.
  void rollback() {
    _isActive = false;
    _operations.clear();
    _savepoints.clear();
  }

  /// Marks the transaction as committed. Called internally by
  /// [TransactionManager.commit].
  void _commit() {
    _isActive = false;
    _isCommitted = true;
  }

  /// Returns a summary of this transaction for debugging purposes.
  Map<String, dynamic> toDebugMap() {
    return {
      'id': id,
      'isActive': _isActive,
      'isCommitted': _isCommitted,
      'startedAt': startedAt.toIso8601String(),
      'operationCount': _operations.length,
      'savepointCount': _savepoints.length,
    };
  }
}

/// Manages ACID transactions across Rift boxes.
///
/// The [TransactionManager] coordinates transaction lifecycle: beginning,
/// committing, and rolling back transactions. It also provides a convenience
/// method [runInTransaction] that automatically commits on success and
/// rolls back on error.
class TransactionManager {
  /// Map of active transaction IDs to their [RiftTransaction] objects.
  final Map<String, RiftTransaction> _activeTransactions = {};

  /// Monotonically increasing counter for generating unique transaction IDs.
  int _counter = 0;

  /// History of committed transactions for audit and recovery purposes.
  final List<RiftTransaction> _committedHistory = [];

  /// Maximum number of committed transactions to retain in history.
  static const int _maxHistorySize = 100;

  /// Begins a new transaction and returns it.
  RiftTransaction begin() {
    final tx = RiftTransaction('tx_${_counter++}');
    _activeTransactions[tx.id] = tx;
    return tx;
  }

  /// Retrieves an active transaction by its ID.
  RiftTransaction? getTransaction(String id) => _activeTransactions[id];

  /// Executes a function within a transaction, automatically committing
  /// on success and rolling back on error.
  Future<T> runInTransaction<T>(
    Future<T> Function(RiftTransaction tx) fn,
  ) async {
    final tx = begin();
    try {
      final result = await fn(tx);
      _commitAndArchive(tx);
      return result;
    } catch (e) {
      tx.rollback();
      _activeTransactions.remove(tx.id);
      rethrow;
    }
  }

  /// Commits a transaction, marking it as successfully completed.
  void commit(RiftTransaction tx) {
    if (!tx.isActive) {
      throw RiftError('Transaction ${tx.id} is not active');
    }
    _commitAndArchive(tx);
  }

  /// Internal method to commit a transaction and archive it.
  void _commitAndArchive(RiftTransaction tx) {
    tx._commit();
    _activeTransactions.remove(tx.id);
    _committedHistory.add(tx);
    if (_committedHistory.length > _maxHistorySize) {
      _committedHistory.removeRange(
        0,
        _committedHistory.length - _maxHistorySize,
      );
    }
  }

  /// Rolls back a transaction, discarding all its operations.
  void rollback(RiftTransaction tx) {
    tx.rollback();
    _activeTransactions.remove(tx.id);
  }

  /// The number of currently active transactions.
  int get activeCount => _activeTransactions.length;

  /// IDs of all currently active transactions.
  List<String> get activeTransactionIds => _activeTransactions.keys.toList();

  /// A list of recently committed transactions (for audit purposes).
  List<RiftTransaction> get committedHistory =>
      List.unmodifiable(_committedHistory);

  /// Applies the operations recorded in a committed transaction to a box.
  ///
  /// Returns the number of operations applied.
  /// Throws [RiftError] if the transaction has not been committed.
  Future<int> applyToBox(RiftTransaction tx, dynamic box) async {
    if (!tx.isCommitted) {
      throw RiftError(
        'Transaction ${tx.id} has not been committed. '
        'Commit the transaction before applying.',
      );
    }

    var applied = 0;
    for (final op in tx.operations) {
      switch (op.type) {
        case _TransactionOpType.put:
          await box.put(op.key, op.value);
          applied++;
        case _TransactionOpType.delete:
          await box.delete(op.key);
          applied++;
        case _TransactionOpType.putAll:
          if (op.entries != null && op.entries!.isNotEmpty) {
            await box.putAll(op.entries);
            applied++;
          }
        case _TransactionOpType.deleteAll:
          if (op.keys != null && op.keys!.isNotEmpty) {
            await box.deleteAll(op.keys);
            applied++;
          }
        case _TransactionOpType.clear:
          await box.clear();
          applied++;
      }
    }
    return applied;
  }

  /// Clears all active transactions and history.
  void reset() {
    for (final tx in _activeTransactions.values) {
      tx.rollback();
    }
    _activeTransactions.clear();
    _committedHistory.clear();
  }
}
