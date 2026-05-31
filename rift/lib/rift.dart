import 'package:rift/src/rift.dart';
import 'package:rift/src/rift_impl.dart';

import 'package:rift/src/isolate/isolated_rift.dart';
import 'package:rift/src/isolate/isolated_rift_impl/isolated_rift_impl.dart';
import 'package:rift/src/util/logger.dart';

// Core exports
export 'src/box_collection/box_collection_stub.dart'
    if (dart.library.js_interop) 'package:rift/src/box_collection/box_collection_indexed_db.dart'
    if (dart.library.io) 'package:rift/src/box_collection/box_collection.dart';
export 'src/object/rift_object.dart' show RiftObject, RiftObjectMixin;

export 'src/annotations/generate_adapters.dart';
export 'src/annotations/rift_field.dart';
export 'src/annotations/rift_type.dart';
export 'src/binary/binary_reader.dart';
export 'src/binary/binary_reader_impl.dart';
export 'src/binary/binary_writer.dart';
export 'src/binary/binary_writer_impl.dart';
export 'src/binary/file_header.dart';
export 'src/box/box.dart';
export 'src/box/box_base.dart';
export 'src/box/lazy_box.dart';
export 'src/crypto/rift_aes_cipher.dart';
export 'src/crypto/rift_cipher.dart';
export 'src/rift.dart';
export 'src/rift_error.dart';
export 'src/object/rift_collection.dart';
export 'src/object/rift_list.dart';
export 'src/object/rift_storage_backend_preference.dart';
export 'src/registry/type_adapter.dart';
export 'src/registry/type_registry.dart';

export 'src/isolate/isolate_name_server.dart';
export 'src/isolate/isolated_rift.dart';
export 'src/isolate/isolated_box.dart';

// Query builder and live queries
export 'src/query/rift_query.dart' show RiftQuery;
export 'src/query/filter_condition.dart' show FilterCondition, FilterOperator;
export 'src/query/sort_condition.dart' show SortCondition, SortOrder;
export 'src/query/live_query.dart' show LiveQuery;

// Secondary indexes
export 'src/index/rift_index.dart' show globalIndexManager;
export 'src/index/index_manager.dart'
    show IndexManager, FieldValueExtractor, defaultFieldValueExtractor;
export 'src/index/secondary_index.dart'
    show SecondaryIndex, IndexType, IndexOperator;
export 'src/index/composite_index.dart' show CompositeIndex;

// Compression
export 'src/compression/compressor.dart'
    show RiftCompression, CompressionAlgorithm;

// Enhanced encryption
export 'src/encryption/rift_enhanced_cipher.dart' show RiftEnhancedCipher;

// Backup and restore
export 'src/backup/backup_manager.dart' show BackupManager;

// Relations with lazy loading
export 'src/relations/relation.dart'
    show RelationManager, RelationConfig, RelationType;
export 'src/relations/lazy_relation.dart'
    show LazyRelation, LazyRelationAdapter;
export 'src/relations/relation_index.dart' show RelationIndex;

// Schema migration framework
export 'src/migration/schema_migration.dart' show Migrator, MigrationStep;
export 'src/migration/schema_version.dart'
    show SchemaVersionTracker, schemaVersionKey;

// TTL / Auto-Expiry
export 'src/ttl/ttl_manager.dart' show TTLManager;
export 'src/ttl/ttl_storage.dart' show TTLStorage, ttlBoxName;

// Middleware / Hooks System
export 'src/middleware/middleware.dart' show RiftMiddleware, MiddlewareChain;
export 'src/middleware/logging_middleware.dart'
    show LoggingMiddleware, LogLevel;
export 'src/middleware/validation_middleware.dart'
    show ValidationMiddleware, ValidationSchema, ValidationRule;

// ACID Transactions
export 'src/transaction/transaction.dart'
    show RiftTransaction, TransactionManager;

// Full-Text Search
export 'src/fts/fts_engine.dart' show FTSEngine, FTSQuery, FTSSearchOperator;
export 'src/fts/fts_result.dart' show FTSResult;

// Bulk Operations
export 'src/bulk/bulk_operations.dart' show BulkOperations;

// LRU Cache
export 'src/cache/lru_cache.dart' show LRUCache;
export 'src/cache/cached_lazy_box.dart' show CachedLazyBox;

// Cursor/Iterator
export 'src/cursor/rift_cursor.dart' show RiftCursor;

// CLI
export 'src/cli/rift_cli.dart' show RiftCLI;

// CRDT
export 'src/crdt/crdt_types.dart'
    show GCounter, PNCounter, GSet, ORSet, LWWRegister, LWWMap;
export 'src/crdt/crdt_document.dart' show CRDTDocument;

// Vector Search
export 'src/vector/vector_search.dart'
    show VectorSearch, VectorSearchResult, DistanceMetric;

// Time Travel
export 'src/timetravel/time_travel.dart'
    show TimeTravel, TimeTravelEvent, TimeTravelEventType, BoxSnapshot;

// Binary Storage
export 'src/binary_storage/binary_storage.dart'
    show RiftBinaryStorage, BinaryMetadata;

// Sync Layer
export 'src/sync/sync_layer.dart'
    show
        RiftSync,
        SyncBackend,
        SyncConfig,
        SyncChange,
        SyncResult,
        SyncConflict,
        SyncEvent,
        SyncStatus,
        ChangeType,
        ConflictResolution,
        ChangeTracker,
        InMemorySyncBackend;
export 'src/sync/sync_types.dart' show SyncCursor, SyncEventType;

// Aggregation Pipeline
export 'src/aggregation/aggregation_pipeline.dart'
    show AggregationPipeline, AggregationOp, AggregationOpType;

// CDC
export 'src/cdc/cdc_manager.dart'
    show CDCManager, CDCEvent, CDCEventType, CDCFilter;

// Field-Level Encryption
export 'src/encryption/field_encryption.dart'
    show FieldEncryption, FieldEncryptionConfig, EncryptionAlgorithm;

// Cross-Box Transactions
export 'src/transaction/cross_box_transaction.dart' show CrossBoxTransaction;

// Profiler
export 'src/profiler/rift_profiler.dart' show RiftProfiler, ProfilerReport;

// Testing Utilities
export 'src/testing/rift_testing.dart' show RiftTestUtil, MockBox;

// Plugin Architecture
export 'src/plugin/rift_plugin.dart'
    show RiftPlugin, RiftPluginManager, RiftPluginContext, RiftOperation;

// Audit Log
export 'src/audit/audit_log.dart' show AuditLog, AuditEntry, AuditAction;

// Geospatial Queries
export 'src/geo/geo_query.dart'
    show GeoQuery, GeoPoint, GeoBoundingBox, GeoResult;

// Bloom Filters
export 'src/bloom/bloom_filter.dart' show BloomFilter;

// Incremental Export
export 'src/incremental/incremental_export.dart'
    show IncrementalExporter, IncrementalExport;

// Dart 3 Records
export 'src/adapters/records_adapter.dart' show RecordAdapter;

// No-Codegen Mode
export 'src/codec/rift_codec.dart'
    show
        RiftCodec,
        MapCodec,
        ReflectiveCodec,
        FieldAccessor,
        CodecRegistry,
        TypedBox;

// State Management Integration
export 'src/state/rift_riverpod.dart'
    show RiftBoxProviderConfig, RiftRiverpodHelper;
export 'src/state/rift_bloc.dart' show RiftBoxCubit;

// Read Cache
export 'src/cache/read_cache.dart' show ReadCache, CacheStrategy, CacheStats;

// Time-Series
export 'src/timeseries/timeseries.dart'
    show TimeSeries, TimeSeriesPoint, AggregationMethod;

// Graph Schema
export 'src/graph/graph_store.dart' show GraphStore, Direction;

// Background Compaction
export 'src/compaction/background_compaction.dart'
    show BackgroundCompactor, CompactionEvent;

// Reactive Signals
export 'src/signals/rift_signals.dart' show RiftSignal, RiftSignalFactory;

// Hive Migration Helper
export 'src/migration/rift_migration_helper.dart'
    show HiveMigrationHelper, MigrationReport, BoxMigrationResult;

// Extension Types
export 'src/adapters/extension_type_adapter.dart' show ExtensionTypeAdapter;

// ============================================================
// NEW FEATURES (20 additions, total 75+)
// ============================================================

// 1. Observable Store
export 'src/observable/observable.dart'
    show
        RiftObservable,
        ObservableList,
        ObservableMap,
        ObservableComputation,
        ListChange,
        ListChangeType,
        MapChange,
        MapChangeType;

// 2. Data Masking
export 'src/masking/masking.dart'
    show DataMasker, MaskingStrategy, MaskingRule, CustomMaskingFunction;

// 3. Schema Validation
export 'src/validation/validation.dart'
    show
        SchemaValidator,
        DataValidationSchema,
        FieldRule,
        FieldRuleType,
        ValidationResult,
        ValidationError,
        ValidationException;

// 3.1. Enhanced Validation
export 'src/validation/enhanced_validation.dart'
    show
        AsyncFieldRule,
        CrossFieldRule,
        EnhancedValidationSchema,
        EnhancedSchemaValidator,
        AsyncValidationError,
        EnhancedValidationResult,
        ValidationRules,
        CrossFieldValidationRules;

// 3.2. Validation Annotations
export 'src/annotations/rift_validation.dart'
    show
        RiftValidation,
        RiftValidationRule,
        ValidationRuleType,
        RiftValidationSchema,
        RiftCrossField;

// 4. Snapshot Isolation
export 'src/snapshot/snapshot.dart'
    show
        BoxSnapshotData,
        SnapshotDiff,
        SnapshotChange,
        SnapshotChangeType,
        SnapshotIsolation;

// 5. Rate Limiting
export 'src/ratelimit/ratelimit.dart'
    show RateLimiter, RateLimitPolicy, RateLimitExceeded, RateLimitManager;

// 6. Data Versioning
export 'src/versioning/versioning.dart'
    show EntryVersion, VersionManager, VersionDiff;

// 7. Partitioning
export 'src/partition/partition.dart'
    show
        PartitionStrategy,
        PartitionStrategyType,
        HashPartitionStrategy,
        RangePartitionStrategy,
        CustomPartitionStrategy,
        PartitionedBox;

// 8. Observability / Metrics
export 'src/metrics/metrics.dart'
    show RiftMetrics, OperationMetric, OperationType, MetricsReport;

// 9. Data Transform Pipeline
export 'src/transform/transform.dart'
    show
        TransformPipeline,
        DataTransform,
        TransformPhase,
        RenameFieldTransform,
        FilterFieldsTransform,
        MapValuesTransform,
        TypeConvertTransform,
        ComputedFieldTransform;

// 10. Replication
export 'src/replication/replication.dart'
    show
        ReplicationManager,
        ReplicaNode,
        ReplicaRole,
        ReplicaStatus,
        ReplicationMode,
        ReplicationConflict,
        ReplicationEvent,
        ReplicationEventType,
        ConflictResolutionStrategy;

// 11. Connection Pooling
export 'src/pool/pool.dart' show RiftPool, PoolConfig, PooledBox, PoolStats;

// 12. Data Sanitization
export 'src/sanitization/sanitization.dart'
    show
        DataSanitizer,
        SanitizationRule,
        SanitizationRuleType,
        SanitizationResult;

// 13. Event Sourcing
export 'src/eventsourcing/eventsourcing.dart'
    show EventStore, Event, Projection, EventReplay, MapProjection;

// 14. Reactive Forms
export 'src/forms/forms.dart'
    show
        RiftForm,
        RiftFormField,
        FieldValidator,
        FieldValidationResult,
        FormState;

// 15. Adaptive Caching
export 'src/adaptive_cache/adaptive_cache.dart'
    show AdaptiveCache, AdaptiveCacheStrategy, AdaptiveCacheStats;

// 16. Data Compression Dictionary
export 'src/dict_compress/dict_compress.dart'
    show DictionaryCompressor, CompressionDictionary;

// 17. Access Control
export 'src/access_control/access_control.dart'
    show
        AccessControl,
        Permission,
        Role,
        AccessContext,
        AccessRule,
        AccessDeniedException;

// 18. Data Diff & Patch
export 'src/diffpatch/diffpatch.dart'
    show
        DataDiffer,
        DataPatch,
        PatchOperation,
        PatchOperationType,
        PatchException;

// 19. Lazy Loading Strategies
export 'src/lazy_strategy/lazy_strategy.dart'
    show LazyStrategy, LazyLoader, LazyRef, PrefetchStrategy, BatchLoader;

// 20. Query Optimization
export 'src/query_opt/query_opt.dart'
    show
        QueryOptimizer,
        QueryPlan,
        QueryAnalysis,
        QueryRewrite,
        QueryRewriteType,
        IndexHint,
        CostEstimate,
        FilterDesc,
        SlowQueryEntry;

/// Global constant to access [Rift]
// ignore: non_constant_identifier_names
final RiftInterface Rift = RiftImpl();

/// Backward compatibility alias for [Rift]
// ignore: non_constant_identifier_names
final RiftInterface Hive = Rift;

/// Global constant to access [IsolatedRift]
///
/// [IsolatedRift] delegates method calls to an isolate. This allows safe
/// usage of Rift across multiple isolates.
///
/// Limitations:
/// - On web, [IsolatedRift] directly calls [Rift] since web does not support
///   isolates
/// - [IsolatedRift] does not support [RiftObject] or [RiftList]
/// - Most methods are async due to isolate communication
// ignore: non_constant_identifier_names
final IsolatedRiftInterface IsolatedRift = IsolatedRiftImpl();

/// Backward compatibility alias for [IsolatedRift]
// ignore: non_constant_identifier_names
final IsolatedRiftInterface IsolatedHive = IsolatedRift;

/// Rift's logger
typedef RiftLogger = Logger;

/// Rift's logger level
typedef RiftLoggerLevel = LoggerLevel;

/// Backward compatibility alias for [RiftLogger]
typedef HiveLogger = Logger;

/// Backward compatibility alias for [RiftLoggerLevel]
typedef HiveLoggerLevel = LoggerLevel;
