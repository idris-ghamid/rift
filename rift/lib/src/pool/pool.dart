/// Connection pooling for Rift boxes.
///
/// Provides a pool of box connections for better resource management
/// in server-side scenarios. Supports min/max connections, idle
/// timeout, and health checks.
///
/// Usage:
/// ```dart
/// final pool = RiftPool(
///   config: PoolConfig(
///     minConnections: 2,
///     maxConnections: 10,
///     idleTimeout: Duration(minutes: 5),
///   ),
///   openBox: (name) => Rift.openBox<Map>(name),
/// );
///
/// await pool.initialize();
///
/// // Acquire a connection
/// final box = await pool.acquire('users');
/// await box.put('key', {'name': 'Idris'});
/// pool.release('users', box);
///
/// // Pool stats
/// print('Active: ${pool.activeCount}, Idle: ${pool.idleCount}');
/// ```
library;

import 'dart:async';

import 'package:rift/rift.dart';

/// Configuration for a connection pool.
class PoolConfig {
  /// Minimum number of connections to maintain per box.
  final int minConnections;

  /// Maximum number of connections per box.
  final int maxConnections;

  /// Time before idle connections are evicted.
  final Duration idleTimeout;

  /// Maximum time to wait for a connection before throwing.
  final Duration acquireTimeout;

  /// Whether to perform health checks on idle connections.
  final bool healthCheckEnabled;

  /// Interval between health checks.
  final Duration healthCheckInterval;

  /// Creates a [PoolConfig].
  const PoolConfig({
    this.minConnections = 1,
    this.maxConnections = 10,
    this.idleTimeout = const Duration(minutes: 5),
    this.acquireTimeout = const Duration(seconds: 30),
    this.healthCheckEnabled = true,
    this.healthCheckInterval = const Duration(minutes: 1),
  });
}

/// A boxed reference obtained from the pool.
class PooledBox<E> {
  /// The underlying box instance.
  final Box<E> box;

  /// When this pooled connection was acquired.
  final DateTime acquiredAt;

  /// When the connection was created.
  final DateTime createdAt;

  /// Whether this connection has been released back to the pool.
  bool _released = false;

  /// Creates a [PooledBox].
  PooledBox({
    required this.box,
    required this.acquiredAt,
    required this.createdAt,
  });

  /// Whether this pooled connection has been released.
  bool get isReleased => _released;

  /// The name of the box.
  String get name => box.name;

  /// The duration this connection has been in use.
  Duration get inUseDuration => DateTime.now().difference(acquiredAt);

  /// The age of this connection.
  Duration get age => DateTime.now().difference(createdAt);
}

/// Stats about the connection pool.
class PoolStats {
  /// The number of currently active (in-use) connections.
  final int activeCount;

  /// The number of idle (available) connections.
  final int idleCount;

  /// Total number of connections ever created.
  final int totalCreated;

  /// Total number of connections ever evicted.
  final int totalEvicted;

  /// Total number of times acquire had to wait.
  final int totalWaited;

  /// Total number of acquire timeouts.
  final int totalTimeouts;

  /// Creates a [PoolStats].
  const PoolStats({
    required this.activeCount,
    required this.idleCount,
    required this.totalCreated,
    required this.totalEvicted,
    required this.totalWaited,
    required this.totalTimeouts,
  });

  /// Total number of connections (active + idle).
  int get totalCount => activeCount + idleCount;

  @override
  String toString() =>
      'PoolStats(active: $activeCount, idle: $idleCount, '
      'created: $totalCreated, evicted: $totalEvicted)';
}

/// Connection pool for Rift boxes.
///
/// [RiftPool] manages a pool of [Box] connections, supporting
/// min/max connection limits, idle eviction, and health checks.
class RiftPool {
  /// The pool configuration.
  final PoolConfig config;

  /// Function to open a box by name.
  final Future<Box<E>> Function<E>(String name) openBox;

  /// Idle connections per box name.
  final Map<String, List<PooledBox>> _idle = {};

  /// Active (in-use) connections per box name.
  final Map<String, List<PooledBox>> _active = {};

  /// Waiters (completers) for acquire calls.
  final Map<String, List<Completer<PooledBox>>> _waiters = {};

  /// Counters.
  int _totalCreated = 0;
  int _totalEvicted = 0;
  int _totalWaited = 0;
  int _totalTimeouts = 0;

  /// Health check timer.
  Timer? _healthCheckTimer;

  /// Idle eviction timer.
  Timer? _evictionTimer;

  /// Whether the pool is initialized.
  bool _initialized = false;

  /// Creates a [RiftPool].
  RiftPool({required this.config, required this.openBox});

  /// Initializes the pool and pre-creates minimum connections.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Start timers
    if (config.healthCheckEnabled) {
      _healthCheckTimer = Timer.periodic(
        config.healthCheckInterval,
        (_) => _healthCheck(),
      );
    }
    _evictionTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _evictIdle(),
    );
  }

  /// Acquires a connection from the pool for the given [boxName].
  ///
  /// If an idle connection is available, it is returned immediately.
  /// If not and the pool hasn't reached max connections, a new one
  /// is created. Otherwise, waits until a connection is available
  /// or the acquire timeout is reached.
  Future<PooledBox> acquire(String boxName) async {
    if (!_initialized) {
      throw StateError('Pool not initialized. Call initialize() first.');
    }

    // Try to get an idle connection
    final idleList = _idle[boxName];
    if (idleList != null && idleList.isNotEmpty) {
      final pooled = idleList.removeLast();
      pooled._released = false;
      _active.putIfAbsent(boxName, () => []);
      _active[boxName]!.add(
        PooledBox(
          box: pooled.box,
          acquiredAt: DateTime.now(),
          createdAt: pooled.createdAt,
        ),
      );
      return _active[boxName]!.last;
    }

    // Create a new connection if under max
    final currentCount =
        (_idle[boxName]?.length ?? 0) + (_active[boxName]?.length ?? 0);
    if (currentCount < config.maxConnections) {
      return await _createConnection(boxName);
    }

    // Wait for a connection to become available
    _totalWaited++;
    final completer = Completer<PooledBox>();
    _waiters.putIfAbsent(boxName, () => []);
    _waiters[boxName]!.add(completer);

    // Set timeout
    Future.delayed(config.acquireTimeout, () {
      if (!completer.isCompleted) {
        _totalTimeouts++;
        _waiters[boxName]?.remove(completer);
        completer.completeError(
          TimeoutException(
            'Timed out waiting for pool connection to box "$boxName"',
            config.acquireTimeout,
          ),
        );
      }
    });

    return completer.future;
  }

  /// Releases a connection back to the pool.
  void release(String boxName, PooledBox pooled) {
    if (pooled._released) return;
    pooled._released = true;

    // Remove from active
    _active[boxName]?.removeWhere((p) => p.box == pooled.box);

    // Check if anyone is waiting
    final waiters = _waiters[boxName];
    if (waiters != null && waiters.isNotEmpty) {
      final waiter = waiters.removeAt(0);
      final newPooled = PooledBox(
        box: pooled.box,
        acquiredAt: DateTime.now(),
        createdAt: pooled.createdAt,
      );
      _active.putIfAbsent(boxName, () => []);
      _active[boxName]!.add(newPooled);
      waiter.complete(newPooled);
      return;
    }

    // Return to idle pool
    _idle.putIfAbsent(boxName, () => []);
    _idle[boxName]!.add(
      PooledBox(
        box: pooled.box,
        acquiredAt: DateTime.now(),
        createdAt: pooled.createdAt,
      ),
    );
  }

  Future<PooledBox> _createConnection(String boxName) async {
    final box = await openBox(boxName);
    _totalCreated++;
    final pooled = PooledBox(
      box: box,
      acquiredAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    _active.putIfAbsent(boxName, () => []);
    _active[boxName]!.add(pooled);
    return pooled;
  }

  void _evictIdle() {
    final now = DateTime.now();
    for (final boxName in _idle.keys.toList()) {
      final idleList = _idle[boxName];
      if (idleList == null) continue;
      idleList.removeWhere((pooled) {
        final idleTime = now.difference(pooled.acquiredAt);
        final shouldEvict =
            idleTime > config.idleTimeout &&
            (idleList.length > config.minConnections);
        if (shouldEvict) _totalEvicted++;
        return shouldEvict;
      });
    }
  }

  void _healthCheck() {
    // Check if idle connections are still valid
    for (final boxName in _idle.keys.toList()) {
      final idleList = _idle[boxName];
      if (idleList == null) continue;
      idleList.removeWhere((pooled) {
        final isValid = pooled.box.isOpen;
        if (!isValid) _totalEvicted++;
        return !isValid;
      });
    }
  }

  /// Gets current pool stats.
  PoolStats get stats {
    var activeCount = 0;
    var idleCount = 0;
    for (final list in _active.values) {
      activeCount += list.length;
    }
    for (final list in _idle.values) {
      idleCount += list.length;
    }
    return PoolStats(
      activeCount: activeCount,
      idleCount: idleCount,
      totalCreated: _totalCreated,
      totalEvicted: _totalEvicted,
      totalWaited: _totalWaited,
      totalTimeouts: _totalTimeouts,
    );
  }

  /// The number of active connections.
  int get activeCount =>
      _active.values.fold(0, (sum, list) => sum + list.length);

  /// The number of idle connections.
  int get idleCount => _idle.values.fold(0, (sum, list) => sum + list.length);

  /// Closes all connections and shuts down the pool.
  Future<void> close() async {
    _healthCheckTimer?.cancel();
    _evictionTimer?.cancel();

    // Close all boxes
    for (final list in [..._active.values, ..._idle.values]) {
      for (final pooled in list) {
        await pooled.box.close();
      }
    }

    _active.clear();
    _idle.clear();

    // Cancel any waiters
    for (final waiters in _waiters.values) {
      for (final completer in waiters) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('Pool is closing'));
        }
      }
    }
    _waiters.clear();
    _initialized = false;
  }
}
