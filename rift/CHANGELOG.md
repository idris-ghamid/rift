## 1.0.0 - May 30, 2026

Initial release of Rift — the next-generation NoSQL database for Flutter & Dart.

### Core
- Fork from Hive v2 / hive_ce with complete rebranding to Rift
- Pure Dart implementation with zero native dependencies
- Full API compatibility with Hive for easy migration
- Support for Dart SDK ^3.8.0 and Flutter ^3.27.0

### New Features (95+)
- **Query Engine**: Query Builder, Live Queries, Secondary & Composite Indexes, Cursor Iterator, Query Optimization
- **Data & Schema**: ACID Transactions, Cross-Box Transactions, Schema Migration, Relations, Bulk Operations, Typed Boxes, Schema Validation, Enhanced Validation (Async Rules, Cross-Field Validation, Pre-built Rules), Validation Annotations for Code Generation, Middleware, Partitioning, Aggregation Pipeline, Data Diff & Patch, Data Versioning, Transform Pipeline, Rate Limiting
- **Security**: AES-256 Encryption with PBKDF2+HMAC, Field-Level Encryption, Access Control, Data Masking, Data Sanitization, Audit Log
- **Performance**: LZ4 Compression, LRU Cache, Read Cache, Adaptive Caching, In-Memory Mode, WAL Recovery, Background Compaction, Binary Storage, Dictionary Compression, Pluggable Storage, TTL/Auto-Expiry, Time Travel/Undo, Time-Series Data, Snapshot Isolation, Bloom Filters
- **Sync & Distribution**: Sync Layer, Change Data Capture, Replication, CRDT, Event Sourcing, Connection Pooling, Observable Store
- **Developer Tools**: Testing Utilities, Code Generator, No-Codegen Mode, DevTools Inspector, Performance Profiler, Metrics/Observability, Dart 3 Records, Extension Types, Plugin Architecture, CLI Tools
- **Platform**: Web Performance Pack, OPFS Support, Memory-Mapped I/O, Isolate Support, Aurora OS, SharedArrayBuffer, Backup & Restore, Incremental Export, File Versioning, Hive Migration Helper, State Management, Reactive Signals, Reactive Forms, Lazy Loading Strategies

### Improvements over Hive
- Varint encoding for smaller storage footprint
- O(1) type adapter lookup
- WAL batch writes for crash safety
- Skip list indexes for O(log n) queries
- Bloom filters for reduced disk I/O
- Buffered I/O for large datasets

### Documentation
- Comprehensive README with 75+ feature examples
- Migration guide from Hive/hive_ce
- Architecture diagrams
- Performance optimization guide

### Credits
- Built on the foundation of [Hive](https://github.com/isar/hive) by Simon Choi
- Built on [hive_ce](https://github.com/IO-Design-Team/hive_ce) by the community
- Rift by [Idris Ghamid](https://github.com/idris-ghamid) / [IDRISIUM Corp](https://github.com/IDRISIUMCorp)
