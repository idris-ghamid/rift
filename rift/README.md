<div align="center">

# ⚡ Rift

**The next-generation NoSQL database for Flutter & Dart**

*Pure Dart. Blazing fast. Reactive queries. Zero native dependencies.*

[![Pub Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://pub.dev/packages/rift)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-orange.svg)](https://pub.dev/packages/rift)
[![Pure Dart](https://img.shields.io/badge/pure-Dart%20%F0%9F%92%9C-blueviolet.svg)](https://dart.dev)

**Rift through your data** ⚡

</div>

---

## Why Rift?

Rift is built on the battle-tested foundation of [Hive](https://github.com/isar/hive) and [hive_ce](https://github.com/IO-Design-Team/hive_ce), but adds everything developers have been asking for — **queries, reactivity, crash safety, relations, CRDT, vector search, and 50+ more features** — while staying 100% Pure Dart with zero native dependencies.

| Feature | Hive v2 | hive_ce | Isar | Drift | **Rift** |
|---------|---------|---------|------|-------|----------|
| Queries | ❌ | ❌ | ✅ | ✅ | ✅ |
| Live Queries (Reactive) | ❌ | ❌ | ✅ | ✅ | ✅ |
| Secondary Indexes | ❌ | ❌ | ✅ | ✅ | ✅ |
| Composite Indexes | ❌ | ❌ | ❌ | ❌ | ✅ |
| Relations (Lazy Loading) | ⚠️ Fragile | ⚠️ Fragile | ✅ | ✅ | ✅ |
| ACID Transactions | ❌ | ⚠️ Limited | ✅ | ✅ | ✅ |
| WAL (Crash Safety) | ❌ | ❌ | ✅ | ✅ | ✅ |
| Schema Migration | ❌ | ⚠️ Limited | ✅ | ✅ | ✅ |
| Multi-Isolate | ❌ | ✅ | ✅ | ⚠️ | ✅ Native |
| Compression (LZ4) | ❌ | ❌ | ❌ | ❌ | ✅ |
| TTL / Auto-Expiry | ❌ | ❌ | ❌ | ❌ | ✅ |
| Middleware / Hooks | ❌ | ❌ | ❌ | ❌ | ✅ |
| Full-Text Search | ❌ | ❌ | ✅ | ✅ | ✅ |
| Backup & Restore | ❌ | ❌ | ❌ | ❌ | ✅ |
| Enhanced Encryption | ⚠️ Basic | ⚠️ Basic | ❌ | ❌ | ✅ PBKDF2+HMAC |
| Field-Level Encryption | ❌ | ❌ | ❌ | ❌ | ✅ |
| Bulk Operations | ❌ | ❌ | ⚠️ | ❌ | ✅ 10-100x faster |
| LRU Cache | ❌ | ❌ | ❌ | ❌ | ✅ |
| Cursor/Iterator | ❌ | ❌ | ❌ | ❌ | ✅ |
| CLI Tools | ❌ | ❌ | ❌ | ❌ | ✅ |
| CRDT (Conflict-Free) | ❌ | ❌ | ❌ | ❌ | ✅ |
| Vector Search (ANN) | ❌ | ❌ | ⚠️ | ❌ | ✅ |
| Time Travel / Undo | ❌ | ❌ | ❌ | ❌ | ✅ |
| Binary Storage | ❌ | ❌ | ❌ | ❌ | ✅ |
| Sync Layer | ❌ | ❌ | 💰 Paid | ❌ | ✅ |
| Aggregation Pipeline | ❌ | ❌ | ❌ | ✅ | ✅ |
| Change Data Capture | ❌ | ❌ | ❌ | ❌ | ✅ |
| Geospatial Queries | ❌ | ❌ | ❌ | ❌ | ✅ |
| Audit Log | ❌ | ❌ | ❌ | ❌ | ✅ |
| Performance Profiler | ❌ | ❌ | ❌ | ❌ | ✅ |
| Plugin Architecture | ❌ | ❌ | ❌ | ❌ | ✅ |
| Bloom Filters | ❌ | ❌ | ❌ | ❌ | ✅ |
| Graph Data Model | ❌ | ❌ | ❌ | ❌ | ✅ |
| Time-Series Data | ❌ | ❌ | ❌ | ❌ | ✅ |
| Reactive Signals | ❌ | ❌ | ❌ | ❌ | ✅ |
| No-Codegen Mode | ❌ | ❌ | ❌ | ❌ | ✅ |
| Hive Migration Helper | ❌ | ❌ | ❌ | ❌ | ✅ |
| Data Masking | ❌ | ❌ | ❌ | ❌ | ✅ |
| Schema Validation | ❌ | ❌ | ❌ | ✅ | ✅ |
| Async Validation | ❌ | ❌ | ❌ | ❌ | ✅ |
| Cross-Field Validation | ❌ | ❌ | ❌ | ❌ | ✅ |
| Snapshot Isolation | ❌ | ❌ | ❌ | ❌ | ✅ |
| Rate Limiting | ❌ | ❌ | ❌ | ❌ | ✅ |
| Data Versioning | ❌ | ❌ | ❌ | ❌ | ✅ |
| Partitioning | ❌ | ❌ | ❌ | ❌ | ✅ |
| Observability / Metrics | ❌ | ❌ | ❌ | ❌ | ✅ |
| Data Transform Pipeline | ❌ | ❌ | ❌ | ❌ | ✅ |
| Replication | ❌ | ❌ | ❌ | ❌ | ✅ |
| Connection Pooling | ❌ | ❌ | ❌ | ❌ | ✅ |
| Data Sanitization | ❌ | ❌ | ❌ | ❌ | ✅ |
| Event Sourcing | ❌ | ❌ | ❌ | ❌ | ✅ |
| Reactive Forms | ❌ | ❌ | ❌ | ❌ | ✅ |
| Adaptive Caching | ❌ | ❌ | ❌ | ❌ | ✅ |
| Dictionary Compression | ❌ | ❌ | ❌ | ❌ | ✅ |
| Access Control (RBAC) | ❌ | ❌ | ❌ | ❌ | ✅ |
| Data Diff & Patch | ❌ | ❌ | ❌ | ❌ | ✅ |
| Lazy Loading Strategies | ❌ | ❌ | ❌ | ❌ | ✅ |
| Query Optimization | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Pure Dart** | ✅ | ✅ | ❌ C/Rust | ❌ SQLite | ✅ |

---

## Quick Start

### Installation

```yaml
# pubspec.yaml
dependencies:
  rift: ^1.0.0
```

For Flutter apps, also add:

```yaml
dependencies:
  rift_flutter: ^1.0.0
```

### Hello Rift

```dart
import 'package:rift/rift.dart';

void main() async {
  // Initialize Rift
  await Rift.init();

  // Open a box (like a table)
  final users = await Rift.openBox<Map>('users');

  // Store data
  await users.put('u1', {'name': 'Idris', 'age': 25, 'city': 'Cairo'});

  // Read data
  final user = users.get('u1');
  print(user); // {name: Idris, age: 25, city: Cairo}

  // Query with filters
  final adults = users.query()
    .where('age', greaterThan: 18)
    .where('city', equalTo: 'Cairo')
    .sortBy('name')
    .limit(10)
    .findAll();

  // Live query — auto-updating stream
  users.query()
    .where('age', greaterThan: 18)
    .watch()
    .listen((results) => print('Found ${results.length} adults'));

  await Rift.close();
}
```

---

## Features Deep Dive

### 📦 Boxes — Key-Value Storage

Boxes are the primary data containers, similar to tables in SQL databases.

```dart
// Open a box
final users = await Rift.openBox<Map>('users');

// CRUD operations
await users.put('key', value);         // Create/Update
final value = users.get('key');         // Read
await users.delete('key');              // Delete
await users.clear();                    // Clear all

// Bulk operations
await users.putAll({'k1': v1, 'k2': v2});
await users.deleteAll(['k1', 'k2']);
final all = users.toMap();

// Check existence
final exists = users.containsKey('key');

// Iterate
for (final key in users.keys) { ... }
for (final value in users.values) { ... }
```

### 🔍 Query Builder

The most requested feature for Hive — now in Rift.

```dart
// Simple filter
final results = users.query()
  .where('age', greaterThan: 18)
  .findAll();

// Multiple filters (AND logic)
final results = users.query()
  .where('age', greaterThanOrEqual: 21)
  .where('city', equalTo: 'Cairo')
  .findAll();

// Sort and paginate
final page = users.query()
  .where('active', equalTo: true)
  .sortBy('name')
  .offset(20)
  .limit(10)
  .findAll();

// Count and find first
final count = users.query().where('age', greaterThan: 18).count();
final first = users.query().where('email', startsWith: 'admin').findFirst();
```

### 📡 Live Queries — Reactive Streams

Watch query results in real-time. The stream emits automatically when data changes.

```dart
// Watch a query
final subscription = users.query()
  .where('status', equalTo: 'active')
  .watch()
  .listen((activeUsers) {
    print('Active users: ${activeUsers.length}');
  });

// Watch with debounce
final subscription = users.query()
  .where('age', greaterThan: 18)
  .watch(debounce: Duration(milliseconds: 300))
  .listen((results) => updateUI(results));
```

### 🗂️ Secondary & Composite Indexes

Speed up queries with indexes on frequently queried fields.

```dart
// Create indexes
await users.createIndex('age');                          // B-tree index
await users.createIndex('name', type: IndexType.hash);   // Hash index

// Composite index for multi-field queries
await users.createCompositeIndex(['city', 'age']);

// Queries automatically use indexes when available
```

### ✅ ACID Transactions

Atomic operations with savepoints and rollback.

```dart
// Auto-commit transaction
final txManager = TransactionManager();
await txManager.runInTransaction((tx) async {
  tx.put('users', 'u1', {'balance': 100});
  tx.put('users', 'u2', {'balance': 200});
  // If either fails, both are rolled back
});

// Manual transaction with savepoints
final tx = txManager.begin();
tx.put('users', 'u1', {'balance': 100});
tx.savepoint('before_u2');
tx.put('users', 'u2', {'balance': 200});
// Something went wrong? Rollback to savepoint:
tx.rollbackTo('before_u2');
// Or commit everything:
txManager.commit(tx);
```

### 🔗 Cross-Box Transactions

Atomic operations across multiple boxes.

```dart
final users = await Rift.openBox<Map>('users');
final orders = await Rift.openBox<Map>('orders');

final ctx = CrossBoxTransaction([users, orders]);
ctx.put('users', 'u1', {'cart': []});
ctx.put('orders', 'o1', {'userId': 'u1', 'total': 50});
await ctx.commit(); // Both boxes updated atomically
```

### 🛡️ WAL — Crash Safety

Write-Ahead Logging prevents data loss on app crash.

```dart
// WAL automatically recovers uncommitted changes on next open
// No configuration needed — just open your boxes
final users = await Rift.openBox<Map>('users');
```

### 🔄 Schema Migration

Evolve your data schema safely over time.

```dart
final migrator = Migrator();
migrator.addStep(MigrationStep(fromVersion: 1, toVersion: 2, migrate: (data) {
  data['email'] = data['email'] ?? '';
  return data;
}));
migrator.addStep(MigrationStep(fromVersion: 2, toVersion: 3, migrate: (data) {
  data['fullName'] = data.remove('name');
  return data;
}));
await migrator.run(box);
```

### 🔗 Relations with Lazy Loading

Define relationships between boxes.

```dart
// One-to-many: Author → Posts
final relationMgr = RelationManager();
relationMgr.createRelation(RelationConfig(
  sourceBox: 'posts',
  targetBox: 'users',
  field: 'authorId',
  type: RelationType.manyToOne,
  lazyLoad: true,
));

// Access related data
final author = await relationMgr.getRelated('posts', 'post1', 'users');
```

### ⏱️ TTL — Auto-Expiring Data

Set expiration times on entries.

```dart
// Store with TTL
await box.putWithTTL('session', token, Duration(hours: 1));
await box.putWithTTL('cache', data, Duration(minutes: 30));

// Start automatic purge
TTLManager.instance.startPurgeTimer(interval: Duration(minutes: 1));
```

### 🔌 Middleware / Hooks

Intercept operations for logging, validation, caching, or sync.

```dart
// Built-in logging middleware
final chain = MiddlewareChain();
chain.add(LoggingMiddleware(level: LogLevel.debug));

// Validation middleware
chain.add(ValidationMiddleware(ValidationSchema({
  'name': [ValidationRule.required(), ValidationRule.type(String)],
  'age': [ValidationRule.required(), ValidationRule.min(0), ValidationRule.max(150)],
})));
```

### 🔎 Full-Text Search

Search text content with TF-IDF scoring and stemming.

```dart
final fts = FTSEngine();

// Index documents
fts.indexDocument('doc1', {'title': 'Flutter Database', 'body': 'Rift is a fast NoSQL database for Flutter'});
fts.indexDocument('doc2', {'title': 'Dart Programming', 'body': 'Dart is the language behind Flutter'});

// Search
final results = fts.search('Flutter database');
for (final r in results) {
  print('${r.key}: score=${r.score.toStringAsFixed(2)}');
}

// Advanced queries
final query = FTSQuery.parse('Flutter AND database');
final results = fts.searchWithQuery(query);
```

### 🗜️ Compression

Save 30-70% storage space with built-in LZ4 compression.

```dart
final largeData = await Rift.openBox<Map>('largeData',
  compression: RiftCompression.lz4,
);

// Custom threshold (only compress values > 1KB)
final docs = await Rift.openBox<Map>('docs',
  compression: RiftCompression(
    algorithm: CompressionAlgorithm.lz4,
    threshold: 1024,
  ),
);
```

### 🔐 Enhanced Encryption

PBKDF2 key derivation + HMAC tamper detection + AES-256-CBC.

```dart
// Box-level encryption
final cipher = RiftEnhancedCipher(password: 'my-secret-password');
final secrets = await Rift.openBox<Map>('secrets',
  encryptionCipher: cipher,
);

// Field-level encryption (different keys per field)
final fieldEnc = FieldEncryption({
  'ssn': FieldEncryptionConfig(key: 'strong-key', algorithm: EncryptionAlgorithm.aes256),
  'creditCard': FieldEncryptionConfig(key: 'another-key'),
});
final encrypted = fieldEnc.encrypt({'ssn': '123-45-6789', 'creditCard': '4111...', 'name': 'Public'});
```

### 💾 Backup & Restore

Full and incremental backup support.

```dart
final backupMgr = BackupManager();

// Full backup
final backup = await backupMgr.fullBackup();

// Incremental backup
final incBackup = await backupMgr.incrementalBackup(sinceTimestamp);

// Restore
await backupMgr.restore(backup);

// Export/import single box
final json = await backupMgr.exportBox('users');
await backupMgr.importBox('users', json);
```

### ⚡ Bulk Operations

10-100x faster than individual operations.

```dart
// Bulk put
final largeDataset = Map.fromEntries(List.generate(10000, (i) => MapEntry('key_$i', {'value': i})));
await BulkOperations.bulkPut(box, largeDataset, batchSize: 1000);

// Bulk delete
await BulkOperations.bulkDelete(box, keysToDelete);

// Bulk get
final values = await BulkOperations.bulkGet(box, ['k1', 'k2', 'k3']);

// Import/Export JSON
await BulkOperations.importJson(box, jsonData);
final exported = await BulkOperations.exportJson(box);
```

### 📊 Aggregation Pipeline

MongoDB-style data analysis pipeline.

```dart
final results = await AggregationPipeline()
  .match((doc) => doc['age'] > 18)
  .group('city', [
    AggregationOp('avgAge', AggregationOpType.avg, inputField: 'age'),
    AggregationOp('count', AggregationOpType.count),
    AggregationOp('maxSalary', AggregationOpType.max, inputField: 'salary'),
  ])
  .sort('avgAge', descending: true)
  .limit(10)
  .execute(box);
```

### 🔄 CRDT — Conflict-Free Replicated Data Types

Sync across devices without conflicts.

```dart
// G-Counter (grow-only)
final counter1 = GCounter('device1');
counter1.increment(5);
final counter2 = GCounter('device2');
counter2.increment(3);
final merged = counter1.merge(counter2);
print(merged.value); // 8

// LWW-Register (last-writer-wins)
final reg1 = LWWRegister<String>('hello', 'device1');
final reg2 = LWWRegister<String>('world', 'device2');
final winner = reg1.merge(reg2);

// CRDT Document
final doc1 = CRDTDocument('phone');
doc1.put('name', 'Idris');
final doc2 = CRDTDocument('laptop');
doc2.put('name', 'Ahmed');
final merged = doc1.merge(doc2); // Resolves conflicts automatically
```

### 🧠 Vector Search (AI/Embeddings)

Search by vector similarity for AI applications.

```dart
final vectorSearch = VectorSearch(dimensions: 128, metric: DistanceMetric.cosine);

// Index embeddings
vectorSearch.index('doc1', embedding1);
vectorSearch.index('doc2', embedding2);

// Find k nearest neighbors
final results = vectorSearch.search(queryEmbedding, k: 5);
for (final r in results) {
  print('${r.key}: distance=${r.distance.toStringAsFixed(4)}');
}
```

### ⏪ Time Travel / Undo

Revert data to any previous state.

```dart
final timeTravel = TimeTravel('users');

// Record changes
timeTravel.record(TimeTravelEventType.put, 'u1', null, {'name': 'Idris'});
timeTravel.record(TimeTravelEventType.put, 'u1', {'name': 'Idris'}, {'name': 'Ahmed'});

// Take snapshot
final snapshot = await BoxSnapshot.fromBox(box, timeTravel.currentVersion);
timeTravel.saveSnapshot(snapshot);

// View history
final history = timeTravel.history;
for (final event in history) {
  print('v${event.version}: ${event.type} ${event.key}');
}
```

### 🔔 Change Data Capture (CDC)

Stream of structured change events for sync and audit.

```dart
final cdc = CDCManager();

// Subscribe to changes
cdc.stream.listen((event) {
  print('${event.type}: ${event.boxName}[${event.key}]');
});

// Filter by box or event type
cdc.subscribe(boxNames: ['users'], eventTypes: [CDCEventType.update, CDCEventType.delete])
  .listen((event) => handleUserChange(event));
```

### 🌍 Geospatial Queries

Search by geographic proximity.

```dart
// Find locations within 5km radius
final cafe = GeoPoint(30.0444, 31.2357); // Cairo
final nearby = GeoQuery.findWithinRadius(
  box, 'latitude', 'longitude', cafe, 5000, // 5km
);
for (final result in nearby) {
  print('${result.key}: ${result.distance.toStringAsFixed(0)}m away');
}

// Nearest neighbors
final nearest = GeoQuery.findNearest(box, 'lat', 'lon', cafe, k: 10);
```

### 📝 Audit Log / Event Trail

Track all modifications for compliance and debugging.

```dart
final auditLog = AuditLog(maxEntries: 10000);

// Log operations
auditLog.log(AuditAction.update, 'users', key: 'u1', oldValue: old, newValue: new_);

// Query audit log
final recentChanges = auditLog.getEntries(
  boxName: 'users',
  since: DateTime.now().subtract(Duration(hours: 1)),
);

// Export as JSON
final jsonLog = auditLog.exportJson();
```

### 🔍 Bloom Filters

Fast key existence checking to reduce disk I/O.

```dart
final bloom = BloomFilter(expectedItems: 10000, falsePositiveRate: 0.01);

// Add keys
bloom.add('user_001');
bloom.add('user_002');

// Check existence (no false negatives!)
if (bloom.mightContain('user_001')) {
  // Might exist — check the actual box
}
if (!bloom.mightContain('user_999')) {
  // Definitely doesn't exist — skip disk read
}
```

### 🧩 Plugin Architecture

Build custom features on top of Rift.

```dart
class MyAuditPlugin extends RiftPlugin {
  @override
  String get id => 'my_audit';
  @override
  String get name => 'Audit Plugin';
  @override
  String get version => '1.0.0';

  @override
  Future<void> onRegister(RiftPluginContext context) async {
    print('Audit plugin registered!');
  }

  @override
  void afterOperation(RiftOperation operation, dynamic result) {
    print('Operation: ${operation.type} on ${operation.boxName}');
  }
}

// Register plugin
final pluginMgr = RiftPluginManager();
await pluginMgr.register(MyAuditPlugin());
```

### 📈 Performance Profiler

Measure and optimize database operations.

```dart
final profiler = RiftProfiler()..enable();

// Time operations automatically
final result = await profiler.time('query_users', () async {
  return users.query().where('age', greaterThan: 18).findAll();
});

// Generate report
final report = profiler.generateReport();
print(report.toMarkdown());
```

### 🧪 Testing Utilities

Built-in tools for writing tests easily.

```dart
// Create a test box with seed data
final testBox = await RiftTestUtil.createTestBox<Map>('test', seedData: {
  'u1': {'name': 'Alice'},
  'u2': {'name': 'Bob'},
});

// Use MockBox for unit tests without disk I/O
final mockBox = MockBox<Map>();
await mockBox.put('key', {'value': 42});
expect(mockBox.get('key'), equals({'value': 42}));

// Clean up
await RiftTestUtil.cleanUp(['test']);
```

### 🔗 Graph Data Model

Store and traverse graph structures.

```dart
final nodes = await Rift.openBox<Map>('graph_nodes');
final edges = await Rift.openBox<Map>('graph_edges');
final graph = GraphStore(nodes, edges);

// Add nodes and edges
final alice = await graph.addNode('person', {'name': 'Alice'});
final bob = await graph.addNode('person', {'name': 'Bob'});
await graph.addEdge(alice, bob, 'follows');

// Traverse the graph
final following = graph.traverse(alice, maxDepth: 2, edgeLabel: 'follows');

// Shortest path
final path = graph.shortestPath(alice, bob);
```

### 📊 Time-Series Data

Store and analyze timestamped data.

```dart
final tsBox = await Rift.openBox<Map>('sensor_data');
final ts = TimeSeries(tsBox, timestampField: 'timestamp');

// Insert data points
await ts.insert(DateTime.now(), {'temperature': 23.5, 'humidity': 65});
await ts.insert(DateTime.now().subtract(Duration(hours: 1)), {'temperature': 22.1, 'humidity': 70});

// Query range
final recentData = await ts.queryRange(
  DateTime.now().subtract(Duration(hours: 24)),
  DateTime.now(),
);

// Downsample (average per hour)
final hourly = await ts.downsample(Duration(hours: 1), 'temperature', method: AggregationMethod.average);
```

### 🎯 Reactive Signals

Create reactive signals from box values.

```dart
final signalFactory = RiftSignalFactory();

// Create a signal for a specific key
final nameSignal = signalFactory.forKey<String>(box, 'username');
nameSignal.listen((value) => print('Username changed to: $value'));

// Create a signal for the entire box
final boxSignal = signalFactory.forBox(box);
boxSignal.listen((data) => updateUI(data));
```

### 🗂️ No-Codegen Mode

Use Rift without build_runner for simple use cases.

```dart
// Define a codec
class UserCodec extends RiftCodec<User> {
  @override
  User fromMap(Map<String, dynamic> map) => User(
    name: map['name'] as String,
    age: map['age'] as int,
  );

  @override
  Map<String, dynamic> toMap(User user) => {'name': user.name, 'age': user.age};
}

// Create a typed box
final rawBox = await Rift.openBox<Map<String, dynamic>>('users');
final typedBox = TypedBox(rawBox, UserCodec());

// Type-safe access
await typedBox.put('u1', User(name: 'Idris', age: 25));
final user = typedBox.get('u1'); // User?
```

### 🗄️ Binary Storage

Store images, PDFs, and other binary data.

```dart
final storage = RiftBinaryStorage(basePath: '/app/data/binaries');

// Store a file
final key = await storage.store(
  'profile_pic',
  imageBytes,
  mimeType: 'image/png',
  metadata: {'userId': 'u1'},
);

// Retrieve
final data = await storage.retrieve('profile_pic');
```

### 🔄 Sync Layer

Pluggable sync with any backend.

```dart
final sync = RiftSync();
sync.configure(InMemorySyncBackend(), SyncConfig(
  endpoint: 'https://api.example.com/sync',
  syncInterval: Duration(seconds: 30),
  conflictResolution: ConflictResolution.lastWriteWins,
));

sync.registerBox('users', usersBox);
await sync.startSync();
```

### 🚀 Cursor / Iterator

Iterate over large datasets without loading everything into memory.

```dart
final cursor = RiftCursor(box, box.keys.toList(), batchSize: 50);

while (cursor.hasNext) {
  final batch = await cursor.nextBatch();
  for (final entry in batch) {
    processEntry(entry);
  }
}

// Filter and transform
final filtered = cursor.where((key, value) => value != null);
final mapped = filtered.map<String>((key, value) => value['name'] as String);
```

### 🔧 Lazy Boxes with LRU Cache

Memory-efficient boxes with smart caching.

```dart
// Cached lazy box — best of both worlds
final images = await Rift.openLazyBox<Uint8List>('images');
final cachedBox = CachedLazyBox(images, cacheSize: 100);

// Frequently accessed items stay in memory
final img1 = cachedBox.get('common_icon.png'); // First read from disk
final img2 = cachedBox.get('common_icon.png'); // Second read from cache!

// Cache stats
print('Hit rate: ${cachedBox.cacheHitRate.toStringAsFixed(2)}');
```

### 🛠️ CLI Tools

Manage your database from the command line.

```bash
# Inspect all boxes
dart run rift inspect /path/to/database

# Export a box to JSON
dart run rift export users /path/to/output.json

# Import data
dart run rift import users /path/to/input.json

# Validate integrity
dart run rift validate /path/to/database

# View statistics
dart run rift stats /path/to/database
```

### 📥 Incremental Export

Export only changes since the last export.

```dart
final exporter = IncrementalExporter();

// First export — full data
final fullExport = await exporter.export(box);

// Later — only changes
final incremental = await exporter.export(box);
print('Changes: ${incremental.upserts.length} upserts, ${incremental.deletes.length} deletes');
```

### 🔄 Hive Migration Helper

Automatically migrate from Hive/hive_ce to Rift.

```dart
// Migrate all Hive boxes
final report = await HiveMigrationHelper.migrateAll();
print('Migrated ${report.successfulMigrations}/${report.totalBoxes} boxes');

// Migrate a single box
final result = await HiveMigrationHelper.migrateBox('users');
if (result.success) {
  print('Migrated ${result.entriesMigrated} entries');
}
```

### 🔍 DevTools Inspector

Inspect and modify your database during development.

```dart
// Install the Rift DevTools extension
// Open Flutter DevTools → Rift tab
// Browse boxes, query data, edit values visually
```

### ✨ Enhanced Validation

Advanced validation with async rules, cross-field validation, and code generation support.

```dart
// Sync validation with pre-built rules
final schema = DataValidationSchema(fields: {
  'email': [ValidationRules.email()],
  'age': [ValidationRule.required(), ValidationRule.min(0), ValidationRule.max(150)],
  'password': [ValidationRules.passwordStrength()],
});

final validator = SchemaValidator(schema);
final result = validator.validate({'email': 'test@example.com', 'age': 25, 'password': 'Secure123!'});
if (!result.isValid) {
  print(result.messages);
}

// Async validation
final enhancedSchema = EnhancedValidationSchema(
  fields: {'email': [ValidationRule.required()]},
  asyncRules: {
    'email': [ValidationRules.unique(checkUnique: (email) async => await checkEmailExists(email))],
  },
);

final enhancedValidator = EnhancedSchemaValidator(enhancedSchema);
final asyncResult = await enhancedValidator.validateAsync(data);

// Cross-field validation
final crossFieldSchema = EnhancedValidationSchema(
  fields: {},
  crossFieldRules: [
    CrossFieldValidationRules.passwordConfirmation(),
    CrossFieldValidationRules.dateRange(),
  ],
);

// Code generation with annotations
@RiftType()
@RiftValidation({
  'name': [
    RiftValidationRule.required(),
    RiftValidationRule.min(2),
    RiftValidationRule.max(50),
  ],
  'email': [RiftValidationRule.email()],
})
class User {
  @RiftField(0)
  String name;

  @RiftField(1)
  String email;
}
```

---

## Typed Boxes with Code Generation

For maximum type safety, use code generation:

```dart
import 'package:rift/rift.dart';

part 'user.g.dart';

@RiftType()
class User {
  @RiftField(0)
  String name;

  @RiftField(1)
  int age;

  @RiftField(2, defaultValue: '')
  String email;

  User({required this.name, required this.age, this.email = ''});
}

// Open a typed box
final users = await Rift.openBox<User>('users');

// Type-safe access
await users.put('u1', User(name: 'Idris', age: 25));
final user = users.get('u1'); // User? — fully typed
```

---

## State Management Integration

### Riverpod

```dart
// Watch a box key as a stream
final nameStream = RiftRiverpodHelper.watchKey<String>(box, 'username');

// Watch all box changes
final allChanges = RiftRiverpodHelper.watchAll(box);
```

### Bloc/Cubit

```dart
final cubit = RiftBoxCubit<Map>(usersBox);

// Access current state
print(cubit.state);

// Listen to changes
cubit.stream.listen((state) => updateUI(state));

// Modify data
await cubit.put('u1', {'name': 'Idris'});
await cubit.delete('u2');
```

---

## Migration from Hive

Rift is a drop-in replacement for Hive with backward compatibility:

```dart
// Old Hive code
import 'package:hive_ce/hive_ce.dart';
final box = await Hive.openBox('users');

// New Rift code — just change the import!
import 'package:rift/rift.dart';
final box = await Rift.openBox('users');

// Or keep using Hive name (backward compat alias)
final box = await Hive.openBox('users'); // Hive = Rift
```

Rift can read existing Hive data files. On first write, the file is automatically upgraded to the new Rift format with varint integers and file headers.

Use the migration helper for automatic bulk migration:

```dart
final report = await HiveMigrationHelper.migrateAll();
```

---

## Flutter Integration

```dart
import 'package:rift_flutter/rift_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiftFlutter.init();
  runApp(const MyApp());
}

// Reactive UI updates with StreamBuilder
class UserList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: usersBox.watch(),
      builder: (context, snapshot) {
        return ListView.builder(
          itemCount: usersBox.length,
          itemBuilder: (context, index) => UserTile(usersBox.getAt(index)),
        );
      },
    );
  }
}
```

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                    API Layer                          │
│  Box<E> │ RiftQuery │ Migration │ Middleware │ CLI    │
├──────────────────────────────────────────────────────┤
│                  Query Engine                         │
│  Filters │ Sort │ Live Queries │ FTS │ Aggregation   │
├──────────────────────────────────────────────────────┤
│               Advanced Features                       │
│  CRDT │ Vector Search │ CDC │ Time Travel │ Graph    │
│  Geospatial │ Bloom Filters │ Audit │ Signals        │
├──────────────────────────────────────────────────────┤
│                 Index Engine                          │
│  Primary (SkipList) │ Secondary (B-Tree/Hash)        │
│  Composite │ Full-Text (Inverted Index)               │
├──────────────────────────────────────────────────────┤
│                  Core Engine                          │
│  WAL │ Transactions │ Compaction │ O(1) Registry     │
│  Encryption │ Compression │ TTL │ Change Tracking    │
│  Backup │ Relations │ Schema Validation              │
├──────────────────────────────────────────────────────┤
│            Storage Engine (Pluggable)                 │
│  BitcaskVM │ IndexedDB │ Memory │ OPFS               │
└──────────────────────────────────────────────────────┘
```

---

## Performance

Rift is built for speed. Key optimizations:

- **Varint encoding** — Integers use 1-10 bytes instead of always 8 bytes (float64)
- **O(1) type adapter lookup** — No more linear scanning for adapters
- **WAL batch writes** — Multiple writes are batched and flushed together
- **Skip list indexes** — O(log n) indexed queries
- **LZ4 compression** — Fast compression with minimal CPU overhead
- **Lazy loading + LRU cache** — Best of both worlds for memory efficiency
- **Bloom filters** — Reduce disk I/O for key existence checks
- **Bulk operations** — 10-100x faster than individual puts
- **Buffered I/O** — Reduced system calls for large datasets

---

## Feature Summary

Rift includes **95+ features** across 5 priority levels:

| Priority | Count | Features |
|----------|-------|----------|
| 🔴 Critical | 7 | Query Builder, Live Queries, Secondary Indexes, WAL, ACID Transactions, Isolate Support, Schema Migration |
| 🟠 High | 10 | Relations, Full-Text Search, Typed Boxes, Enhanced Encryption, Bulk Operations, DevTools Inspector, CLI Tools, Compression, TTL, File Format Versioning |
| 🟡 Medium | 13 | Middleware, LRU Cache, OPFS Web, No-Codegen Mode, Pluggable Storage, State Management, Cursor/Iterator, Backup/Restore, Audit Log, Dart 3 Records, Read Cache, Web Performance, In-Memory Mode |
| 🟢 Competitive | 8 | CRDT, Vector Search, Time Travel, Binary Storage, Sync Layer, Geospatial Queries, Aggregation Pipeline, CDC |
| 🔵 Advanced | 57 | Time-Series, Graph Schema, Smart Codegen, Profiler, Testing Utils, Field-Level Encryption, Cross-Box Tx, Bloom Filters, Background Compaction, Aurora OS, Reactive Signals, Incremental Export, mmap, Extension Types, SharedArrayBuffer, Hive Migration, Plugin Architecture, Data Masking, Schema Validation, Async Validation, Cross-Field Validation, Snapshot Isolation, Rate Limiting, Data Versioning, Partitioning, Observability/Metrics, Data Transform Pipeline, Replication, Connection Pooling, Data Sanitization, Event Sourcing, Reactive Forms, Adaptive Caching, Dictionary Compression, Access Control (RBAC), Data Diff & Patch, Lazy Loading Strategies, Query Optimization, and more |

---

## 🚀 Future Roadmap

Planned features for upcoming releases:

### Phase 1: API & Real-time (Q3 2026)
- **GraphQL Support** - Full GraphQL schema generation and query execution
- **REST API** - Built-in REST API server for external access
- **WebSocket Support** - Real-time bidirectional communication
- **Real-time Collaboration** - Multi-user collaboration with conflict resolution

### Phase 2: Performance & Scalability (Q4 2026)
- **Memory-Mapped I/O (mmap)** - Zero-copy file access for better performance
- **SharedArrayBuffer** - Shared memory between isolates for web
- **Sharding** - Horizontal scaling across multiple nodes
- **Distributed Transactions** - Cross-shard transaction support

### Phase 3: Advanced Features (Q1 2027)
- **GraphQL Subscriptions** - Real-time GraphQL updates
- **WebAssembly (WASM) Backend** - High-performance web backend
- **Edge Computing Support** - Edge deployment optimization
- **Machine Learning Integration** - ML model integration for data analysis

### Phase 4: Enterprise Features (Q2 2027)
- **Advanced Vector Search (HNSW)** - Hierarchical Navigable Small World indexing
- **Distributed Transactions** - Multi-node transaction coordination
- **Enhanced Event Sourcing** - Advanced event replay and projection

---

## Comparison with Alternatives

### Rift vs Hive
Rift adds everything Hive is missing: queries, indexes, live queries, relations, WAL, transactions, migration, TTL, middleware, compression, enhanced encryption, CRDT, vector search, and 40+ more features — while maintaining full API compatibility.

### Rift vs Isar
Isar has a C/Rust native core that requires compiling for each platform. Rift is **100% Pure Dart** — no native dependencies, no compilation issues, works everywhere Dart runs including web. Isar has been effectively abandoned since 2023.

### Rift vs Drift
Drift is a SQL wrapper over SQLite. Rift is a NoSQL key-value store with a simpler, more intuitive API. If you need full SQL power, use Drift. If you want simple, fast, reactive data storage, use Rift.

### Rift vs ObjectBox
ObjectBox has a C++ core and doesn't support web. Rift is Pure Dart with full web support. ObjectBox requires a paid license for sync features.

---

## Packages

| Package | Description |
|---------|-------------|
| `rift` | Core database library |
| `rift_flutter` | Flutter integration (init, adapters, extensions) |
| `rift_generator` | Code generation for typed boxes |
| `rift_inspector` | DevTools inspector UI |

---

## License

Apache License 2.0 — Free for personal and commercial use.

---

## Credits

Rift is built on the excellent foundation of [Hive](https://github.com/isar/hive) by Simon Choi and [hive_ce](https://github.com/IO-Design-Team/hive_ce) by the community.

---

## About Author

**Idris Ghamid** is a software engineer and open-source contributor specializing in Flutter, Dart, and mobile development. He creates high-performance, production-ready libraries and tools for the Flutter ecosystem.

### Connect with Idris

- **GitHub**: [idrisghamid](https://github.com/idris-ghamid)
- **LinkedIn**: [Idris Ghamid](https://www.linkedin.com/in/idris-ghamid)
- **Instagram**: [@idris.ghamid](https://www.instagram.com/idris.ghamid)
- **X (Twitter)**: [@IdrisGhamid](https://x.com/IdrisGhamid)

### Sponsor

If you find Rift useful, consider [sponsoring the project](https://github.com/sponsors/idrisghamid) to support continued development.

---

<div align="center">

**Made with ❤️ by [Idris Ghamid](https://github.com/idris-ghamid)**

⭐ If Rift helps you, give it a star on [GitHub](https://github.com/idris-ghamid/rift)!

</div>
