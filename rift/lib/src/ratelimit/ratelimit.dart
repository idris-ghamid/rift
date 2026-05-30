/// Rate limiting for Rift box operations.
///
/// Provides token bucket-based rate limiting to prevent abuse
/// or overload of database operations. Supports per-box and
/// global rate limiting.
///
/// Usage:
/// ```dart
/// final limiter = RateLimiter(RateLimitPolicy(
///   maxOperations: 100,
///   timeWindow: Duration(seconds: 1),
/// ));
///
/// // Check before operation
/// if (limiter.tryAcquire()) {
///   await box.put('key', value);
/// } else {
///   print('Rate limit exceeded');
/// }
///
/// // Or use acquire which waits until a token is available
/// await limiter.acquire();
/// await box.put('key', value);
/// ```
library;

import 'dart:async';

/// Configuration for rate limiting behavior.
class RateLimitPolicy {
  /// Maximum number of operations allowed per time window.
  final int maxOperations;

  /// The time window in which [maxOperations] are allowed.
  final Duration timeWindow;

  /// Maximum number of tokens that can be accumulated (burst capacity).
  /// If null, defaults to [maxOperations].
  final int? maxBurst;

  /// Creates a [RateLimitPolicy].
  const RateLimitPolicy({
    required this.maxOperations,
    required this.timeWindow,
    this.maxBurst,
  });

  /// The burst capacity (max accumulated tokens).
  int get burstCapacity => maxBurst ?? maxOperations;

  /// The time between token replenishments.
  Duration get refillInterval =>
      Duration(microseconds: timeWindow.inMicroseconds ~/ maxOperations);

  /// A permissive policy (no practical limits).
  static const RateLimitPolicy unlimited = RateLimitPolicy(
    maxOperations: 0x7FFFFFFF,
    timeWindow: Duration(seconds: 1),
  );

  /// A strict policy for write-heavy operations.
  static const RateLimitPolicy strictWrites = RateLimitPolicy(
    maxOperations: 10,
    timeWindow: Duration(seconds: 1),
  );

  /// A moderate policy for read operations.
  static const RateLimitPolicy moderateReads = RateLimitPolicy(
    maxOperations: 1000,
    timeWindow: Duration(seconds: 1),
  );
}

/// Exception thrown when rate limit is exceeded.
class RateLimitExceeded implements Exception {
  /// The policy that was exceeded.
  final RateLimitPolicy policy;

  /// The box name, if applicable.
  final String? boxName;

  /// The time until the next token is available.
  final Duration retryAfter;

  /// Creates a [RateLimitExceeded].
  const RateLimitExceeded({
    required this.policy,
    this.boxName,
    required this.retryAfter,
  });

  @override
  String toString() {
    final box = boxName != null ? ' on box "$boxName"' : '';
    return 'RateLimitExceeded: ${policy.maxOperations} ops/${policy.timeWindow.inSeconds}s$box '
        '(retry after ${retryAfter.inMilliseconds}ms)';
  }
}

/// Token bucket rate limiter for Rift operations.
///
/// Implements the token bucket algorithm: tokens are added at a
/// steady rate up to the burst capacity. Each operation consumes
/// one token. If no tokens are available, the operation is denied
/// or must wait.
class RateLimiter {
  /// The rate limit policy.
  final RateLimitPolicy policy;

  /// The box name this limiter is associated with (optional).
  final String? boxName;

  double _tokens;
  DateTime _lastRefill;
  final List<Completer<void>> _waitQueue = [];

  /// Creates a [RateLimiter] with the given [policy].
  RateLimiter(this.policy, {this.boxName})
    : _tokens = policy.burstCapacity.toDouble(),
      _lastRefill = DateTime.now();

  /// The current number of available tokens.
  double get availableTokens {
    _refill();
    return _tokens;
  }

  /// Whether a token is currently available.
  bool get canAcquire => availableTokens >= 1;

  /// Tries to acquire a token without waiting.
  ///
  /// Returns true if a token was acquired, false if rate limited.
  bool tryAcquire() {
    _refill();
    if (_tokens >= 1) {
      _tokens -= 1;
      return true;
    }
    return false;
  }

  /// Acquires a token, waiting until one is available.
  ///
  /// If a token is available immediately, returns right away.
  /// Otherwise, returns a Future that completes when a token
  /// becomes available.
  Future<void> acquire() async {
    if (tryAcquire()) return;

    final completer = Completer<void>();
    _waitQueue.add(completer);

    // Schedule token replenishment check
    final refillDelay = policy.refillInterval;
    Future.delayed(refillDelay, _processWaitQueue);

    return completer.future;
  }

  /// Acquires a token with a timeout.
  ///
  /// Throws [RateLimitExceeded] if a token is not available
  /// within [timeout].
  Future<void> acquireWithTimeout(Duration timeout) async {
    if (tryAcquire()) return;

    final completer = Completer<void>();
    _waitQueue.add(completer);

    // Set up timeout
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        _waitQueue.remove(completer);
        completer.completeError(
          RateLimitExceeded(
            policy: policy,
            boxName: boxName,
            retryAfter: policy.refillInterval,
          ),
        );
      }
    });

    // Schedule token replenishment
    Future.delayed(policy.refillInterval, _processWaitQueue);

    return completer.future;
  }

  void _processWaitQueue() {
    _refill();
    while (_waitQueue.isNotEmpty && _tokens >= 1) {
      _tokens -= 1;
      final completer = _waitQueue.removeAt(0);
      completer.complete();
    }
    if (_waitQueue.isNotEmpty) {
      Future.delayed(policy.refillInterval, _processWaitQueue);
    }
  }

  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill);
    final tokensToAdd =
        elapsed.inMicroseconds /
        policy.timeWindow.inMicroseconds *
        policy.maxOperations;
    _tokens = (_tokens + tokensToAdd).clamp(0, policy.burstCapacity.toDouble());
    _lastRefill = now;
  }

  /// Resets the rate limiter, restoring all tokens.
  void reset() {
    _tokens = policy.burstCapacity.toDouble();
    _lastRefill = DateTime.now();
  }

  /// The number of operations waiting for tokens.
  int get pendingCount => _waitQueue.length;

  /// Disposes the rate limiter, cancelling any pending waits.
  void dispose() {
    for (final completer in _waitQueue) {
      if (!completer.isCompleted) {
        completer.completeError(
          RateLimitExceeded(
            policy: policy,
            boxName: boxName,
            retryAfter: Duration.zero,
          ),
        );
      }
    }
    _waitQueue.clear();
  }
}

/// Manages rate limiters per box and globally.
class RateLimitManager {
  /// Per-box rate limiters.
  final Map<String, RateLimiter> _boxLimiters = {};

  /// The global rate limiter (applies across all boxes).
  RateLimiter? _globalLimiter;

  /// Default policy for new box limiters.
  RateLimitPolicy defaultPolicy;

  /// Creates a [RateLimitManager].
  RateLimitManager({
    this.defaultPolicy = const RateLimitPolicy(
      maxOperations: 1000,
      timeWindow: Duration(seconds: 1),
    ),
  });

  /// Sets the global rate limiter with the given [policy].
  void setGlobalPolicy(RateLimitPolicy policy) {
    _globalLimiter = RateLimiter(policy);
  }

  /// Sets a rate limit policy for a specific [boxName].
  void setBoxPolicy(String boxName, RateLimitPolicy policy) {
    _boxLimiters[boxName] = RateLimiter(policy, boxName: boxName);
  }

  /// Tries to acquire permission for an operation on [boxName].
  ///
  /// Checks both the global and per-box rate limits.
  /// Returns true if the operation is allowed.
  bool tryAcquire(String boxName) {
    // Check global limit first
    if (_globalLimiter != null && !_globalLimiter!.tryAcquire()) {
      return false;
    }
    // Check box-specific limit
    final limiter = _boxLimiters[boxName] ??= RateLimiter(
      defaultPolicy,
      boxName: boxName,
    );
    return limiter.tryAcquire();
  }

  /// Acquires permission for an operation, waiting if needed.
  ///
  /// Checks both global and per-box limits.
  Future<void> acquire(String boxName) async {
    // Acquire global first
    if (_globalLimiter != null) {
      await _globalLimiter!.acquire();
    }
    // Acquire box-specific
    final limiter = _boxLimiters[boxName] ??= RateLimiter(
      defaultPolicy,
      boxName: boxName,
    );
    await limiter.acquire();
  }

  /// Gets the rate limiter for a specific [boxName].
  RateLimiter? getBoxLimiter(String boxName) => _boxLimiters[boxName];

  /// Gets the global rate limiter.
  RateLimiter? get globalLimiter => _globalLimiter;

  /// Resets all rate limiters.
  void resetAll() {
    _globalLimiter?.reset();
    for (final limiter in _boxLimiters.values) {
      limiter.reset();
    }
  }

  /// Disposes all rate limiters.
  void disposeAll() {
    _globalLimiter?.dispose();
    for (final limiter in _boxLimiters.values) {
      limiter.dispose();
    }
    _boxLimiters.clear();
  }

  /// Box names with configured rate limits.
  Iterable<String> get configuredBoxes => _boxLimiters.keys;
}
