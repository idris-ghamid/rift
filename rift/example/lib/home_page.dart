import 'package:flutter/material.dart';
import 'main.dart';
import 'about_page.dart';
import 'pages/feature_browser_page.dart';
import 'pages/settings_page.dart';
import 'demos/query_demo.dart';
import 'demos/live_query_demo.dart';
import 'demos/index_demo.dart';
import 'demos/wal_demo.dart';
import 'demos/transaction_demo.dart';
import 'demos/fts_demo.dart';
import 'demos/bulk_ops_demo.dart';
import 'demos/lru_cache_demo.dart';
import 'demos/cursor_demo.dart';
import 'demos/encryption_demo.dart';
import 'demos/compression_demo.dart';
import 'demos/backup_demo.dart';
import 'demos/relation_demo.dart';
import 'demos/migration_demo.dart';
import 'demos/ttl_demo.dart';
import 'demos/middleware_demo.dart';
import 'demos/crdt_demo.dart';
import 'demos/vector_search_demo.dart';
import 'demos/time_travel_demo.dart';
import 'demos/binary_storage_demo.dart';
import 'demos/sync_demo.dart';
import 'demos/aggregation_demo.dart';
import 'demos/cdc_demo.dart';
import 'demos/geo_demo.dart';
import 'demos/audit_demo.dart';
import 'demos/profiler_demo.dart';
import 'demos/plugin_demo.dart';
import 'demos/bloom_filter_demo.dart';
import 'demos/codec_demo.dart';
import 'demos/signal_demo.dart';
import 'demos/graph_demo.dart';
import 'demos/timeseries_demo.dart';
import 'demos/field_encryption_demo.dart';
import 'demos/cross_box_tx_demo.dart';
import 'demos/inspector_demo.dart';
import 'demos/in_memory_demo.dart';
import 'demos/codegen_demo.dart';
import 'demos/testing_demo.dart';
import 'demos/bg_compaction_demo.dart';
import 'demos/aurora_os_demo.dart';
import 'demos/incremental_export_demo.dart';
import 'demos/mmap_demo.dart';
import 'demos/extension_types_demo.dart';
import 'demos/shared_buffer_demo.dart';
import 'demos/rift_migration_demo.dart';
import 'demos/isolate_demo.dart';
import 'demos/typed_box_demo.dart';
import 'demos/cli_demo.dart';
import 'demos/file_versioning_demo.dart';
import 'demos/opfs_demo.dart';
import 'demos/pluggable_storage_demo.dart';
import 'demos/state_mgmt_demo.dart';
import 'demos/dart3_records_demo.dart';
import 'demos/read_cache_demo.dart';
import 'demos/web_perf_demo.dart';
import 'demos/observable_demo.dart';
import 'demos/masking_demo.dart';
import 'demos/validation_demo.dart';
import 'demos/snapshot_demo.dart';
import 'demos/ratelimit_demo.dart';
import 'demos/versioning_demo.dart';
import 'demos/partition_demo.dart';
import 'demos/metrics_demo.dart';
import 'demos/transform_demo.dart';
import 'demos/replication_demo.dart';
import 'demos/pool_demo.dart';
import 'demos/sanitization_demo.dart';
import 'demos/eventsourcing_demo.dart';
import 'demos/forms_demo.dart';
import 'demos/adaptive_cache_demo.dart';
import 'demos/dict_compress_demo.dart';
import 'demos/access_control_demo.dart';
import 'demos/diffpatch_demo.dart';
import 'demos/lazy_strategy_demo.dart';
import 'demos/query_opt_demo.dart';

// ─── Category Model ────────────────────────────────────────────────

enum FeatureCategory {
  queries('Query & Search', Icons.search_rounded, Color(0xFF007AFF)),
  data('Data & Schema', Icons.dataset_rounded, Color(0xFF5856D6)),
  security('Security & Privacy', Icons.shield_rounded, Color(0xFFFF3B30)),
  performance('Performance & Storage', Icons.bolt_rounded, Color(0xFFFF9500)),
  sync('Sync & Distribution', Icons.cloud_sync_rounded, Color(0xFF34C759)),
  tools('Developer Tools', Icons.build_rounded, Color(0xFFAF52DE)),
  platform('Platform & Integration', Icons.language_rounded, Color(0xFF5AC8FA));

  final String label;
  final IconData icon;
  final Color color;
  const FeatureCategory(this.label, this.icon, this.color);
}

// ─── Feature Model ─────────────────────────────────────────────────

class FeatureInfo {
  final String name;
  final String description;
  final IconData icon;
  final FeatureCategory category;
  final WidgetBuilder builder;

  const FeatureInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.builder,
  });
}

// ─── All Features ──────────────────────────────────────────────────

final List<FeatureInfo> allFeatures = [
  // ── Query & Search ──
  FeatureInfo(
    name: 'Query Builder',
    description:
        'Fluent query builder for filtering, sorting, and paginating data with a clean API',
    icon: Icons.search_rounded,
    category: FeatureCategory.queries,
    builder: (_) => const QueryDemoPage(),
  ),
  FeatureInfo(
    name: 'Live Query',
    description:
        'Reactive queries that auto-update when data changes, perfect for real-time UI',
    icon: Icons.sync_rounded,
    category: FeatureCategory.queries,
    builder: (_) => const LiveQueryDemoPage(),
  ),
  FeatureInfo(
    name: 'Full-Text Search',
    description:
        'Full-text search with TF-IDF scoring, stemming, and stop word filtering',
    icon: Icons.text_fields_rounded,
    category: FeatureCategory.queries,
    builder: (_) => const FtsDemoPage(),
  ),
  FeatureInfo(
    name: 'Secondary Index',
    description:
        'Secondary indexes for fast lookups, range queries, and compound indexes',
    icon: Icons.list_alt_rounded,
    category: FeatureCategory.queries,
    builder: (_) => const IndexDemoPage(),
  ),
  FeatureInfo(
    name: 'Cursor Iterator',
    description:
        'Cursor-based iteration for efficiently traversing large datasets',
    icon: Icons.arrow_forward_rounded,
    category: FeatureCategory.queries,
    builder: (_) => const CursorDemoPage(),
  ),
  FeatureInfo(
    name: 'Query Optimization',
    description:
        'Query optimizer with cost estimation, index hints, and automatic rewrites',
    icon: Icons.tune_rounded,
    category: FeatureCategory.queries,
    builder: (_) => const QueryOptDemoPage(),
  ),
  FeatureInfo(
    name: 'Vector Search',
    description:
        'Vector similarity search for AI and embedding applications with cosine distance',
    icon: Icons.insights_rounded,
    category: FeatureCategory.queries,
    builder: (_) => const VectorSearchDemoPage(),
  ),
  FeatureInfo(
    name: 'Geospatial',
    description:
        'Geospatial queries with Haversine distance, bounding boxes, and radius search',
    icon: Icons.map_rounded,
    category: FeatureCategory.queries,
    builder: (_) => const GeoDemoPage(),
  ),
  FeatureInfo(
    name: 'Graph Traversal',
    description:
        'Graph traversal for complex relationships with BFS and DFS algorithms',
    icon: Icons.account_tree_rounded,
    category: FeatureCategory.queries,
    builder: (_) => const GraphDemoPage(),
  ),

  // ── Data & Schema ──
  FeatureInfo(
    name: 'Transactions',
    description:
        'ACID transactions with savepoints, rollback, and automatic conflict detection',
    icon: Icons.swap_horiz_rounded,
    category: FeatureCategory.data,
    builder: (_) => const TransactionDemoPage(),
  ),
  FeatureInfo(
    name: 'Cross-Box TX',
    description:
        'Atomic transactions spanning multiple boxes with two-phase commit',
    icon: Icons.compare_arrows_rounded,
    category: FeatureCategory.data,
    builder: (_) => const CrossBoxTxDemoPage(),
  ),
  FeatureInfo(
    name: 'Schema Migration',
    description:
        'Schema migration framework for versioned data with upgrade and downgrade paths',
    icon: Icons.schema_rounded,
    category: FeatureCategory.data,
    builder: (_) => const MigrationDemoPage(),
  ),
  FeatureInfo(
    name: 'Relations',
    description:
        'Relations between boxes with lazy loading, cascade delete, and backlinks',
    icon: Icons.link_rounded,
    category: FeatureCategory.data,
    builder: (_) => const RelationDemoPage(),
  ),
  FeatureInfo(
    name: 'Bulk Operations',
    description:
        'High-performance bulk put, get, and delete operations for batch processing',
    icon: Icons.dataset_rounded,
    category: FeatureCategory.data,
    builder: (_) => const BulkOpsDemoPage(),
  ),
  FeatureInfo(
    name: 'Typed Boxes',
    description:
        'Typed boxes with schema enforcement at compile-time for type safety',
    icon: Icons.verified_user_rounded,
    category: FeatureCategory.data,
    builder: (_) => const TypedBoxDemoPage(),
  ),
  FeatureInfo(
    name: 'Schema Validation',
    description:
        'Schema validation with required, min, max, pattern, and custom rules',
    icon: Icons.checklist_rounded,
    category: FeatureCategory.data,
    builder: (_) => const ValidationDemoPage(),
  ),
  FeatureInfo(
    name: 'Middleware',
    description:
        'Logging and validation middleware hooks for intercepting operations',
    icon: Icons.extension_rounded,
    category: FeatureCategory.data,
    builder: (_) => const MiddlewareDemoPage(),
  ),
  FeatureInfo(
    name: 'Partitioning',
    description:
        'Hash and range partitioning for distributing data across multiple segments',
    icon: Icons.grid_view_rounded,
    category: FeatureCategory.data,
    builder: (_) => const PartitionDemoPage(),
  ),
  FeatureInfo(
    name: 'Aggregation',
    description:
        'MongoDB-style aggregation pipeline with group, match, sort, and project stages',
    icon: Icons.bar_chart_rounded,
    category: FeatureCategory.data,
    builder: (_) => const AggregationDemoPage(),
  ),
  FeatureInfo(
    name: 'Data Diff & Patch',
    description:
        'RFC 6902 JSON Patch for computing diffs, applying and reversing patches',
    icon: Icons.difference_rounded,
    category: FeatureCategory.data,
    builder: (_) => const DiffpatchDemoPage(),
  ),
  FeatureInfo(
    name: 'Data Versioning',
    description:
        'Entry version tracking with rollback capability and diff generation',
    icon: Icons.history_edu_rounded,
    category: FeatureCategory.data,
    builder: (_) => const VersioningDemoPage(),
  ),
  FeatureInfo(
    name: 'Transform Pipeline',
    description:
        'ETL-style data transform pipeline with rename, filter, and map operations',
    icon: Icons.transform_rounded,
    category: FeatureCategory.data,
    builder: (_) => const TransformDemoPage(),
  ),
  FeatureInfo(
    name: 'Rate Limiting',
    description:
        'Token bucket rate limiting for controlling operation frequency',
    icon: Icons.hourglass_empty_rounded,
    category: FeatureCategory.data,
    builder: (_) => const RatelimitDemoPage(),
  ),

  // ── Security & Privacy ──
  FeatureInfo(
    name: 'Encryption',
    description:
        'AES-256 encryption with PBKDF2 key derivation and HMAC integrity verification',
    icon: Icons.lock_rounded,
    category: FeatureCategory.security,
    builder: (_) => const EncryptionDemoPage(),
  ),
  FeatureInfo(
    name: 'Field Encryption',
    description:
        'Per-field encryption with different keys and algorithms for granular security',
    icon: Icons.enhanced_encryption_rounded,
    category: FeatureCategory.security,
    builder: (_) => const FieldEncryptionDemoPage(),
  ),
  FeatureInfo(
    name: 'Access Control',
    description:
        'Fine-grained access control with roles, permissions, and deny rules',
    icon: Icons.admin_panel_settings_rounded,
    category: FeatureCategory.security,
    builder: (_) => const AccessControlDemoPage(),
  ),
  FeatureInfo(
    name: 'Data Masking',
    description:
        'Mask sensitive data with full, partial, hash, and redact strategies',
    icon: Icons.shield_rounded,
    category: FeatureCategory.security,
    builder: (_) => const MaskingDemoPage(),
  ),
  FeatureInfo(
    name: 'Data Sanitization',
    description:
        'Data sanitization with XSS prevention and rule tracking for safe input handling',
    icon: Icons.sanitizer_rounded,
    category: FeatureCategory.security,
    builder: (_) => const SanitizationDemoPage(),
  ),
  FeatureInfo(
    name: 'Audit Log',
    description:
        'Audit trail for all database operations with filtering and export capabilities',
    icon: Icons.fact_check_rounded,
    category: FeatureCategory.security,
    builder: (_) => const AuditDemoPage(),
  ),

  // ── Performance & Storage ──
  FeatureInfo(
    name: 'Compression',
    description:
        'LZ4 compression for storage space savings with configurable compression levels',
    icon: Icons.compress_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const CompressionDemoPage(),
  ),
  FeatureInfo(
    name: 'LRU Cache',
    description:
        'LRU cache with hit rate statistics, eviction policies, and size limits',
    icon: Icons.cached_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const LruCacheDemoPage(),
  ),
  FeatureInfo(
    name: 'Read Cache',
    description:
        'Read cache with LRU and LFU eviction strategies for optimizing read performance',
    icon: Icons.read_more_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const ReadCacheDemoPage(),
  ),
  FeatureInfo(
    name: 'Adaptive Caching',
    description:
        'Adaptive cache that automatically switches between LRU, LFU, and ARC strategies',
    icon: Icons.auto_graph_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const AdaptiveCacheDemoPage(),
  ),
  FeatureInfo(
    name: 'In-Memory Mode',
    description:
        'In-memory database mode with zero disk writes for testing and caching',
    icon: Icons.memory_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const InMemoryDemoPage(),
  ),
  FeatureInfo(
    name: 'WAL Recovery',
    description:
        'Write-Ahead Log for crash recovery with automatic replay on startup',
    icon: Icons.restore_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const WalDemoPage(),
  ),
  FeatureInfo(
    name: 'Background Compaction',
    description:
        'Background compaction without blocking reads for maintaining storage efficiency',
    icon: Icons.cleaning_services_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const BgCompactionDemoPage(),
  ),
  FeatureInfo(
    name: 'Binary Storage',
    description:
        'Binary storage for large objects with metadata and streaming support',
    icon: Icons.attach_file_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const BinaryStorageDemoPage(),
  ),
  FeatureInfo(
    name: 'Dictionary Compression',
    description:
        'Dictionary-based compression for structured data patterns with high repetition',
    icon: Icons.book_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const DictCompressDemoPage(),
  ),
  FeatureInfo(
    name: 'Pluggable Storage',
    description:
        'Pluggable storage engine with swappable backends for custom storage solutions',
    icon: Icons.settings_input_component_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const PluggableStorageDemoPage(),
  ),
  FeatureInfo(
    name: 'TTL / Auto-Expiry',
    description:
        'Time-to-live for automatic data expiration with background purge timers',
    icon: Icons.timer_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const TtlDemoPage(),
  ),
  FeatureInfo(
    name: 'Time Travel',
    description:
        'Time travel and undo capability via event sourcing for reverting changes',
    icon: Icons.history_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const TimeTravelDemoPage(),
  ),
  FeatureInfo(
    name: 'Time-Series',
    description:
        'Time-series data storage with downsampling, aggregation, and range queries',
    icon: Icons.timeline_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const TimeseriesDemoPage(),
  ),
  FeatureInfo(
    name: 'Snapshot Isolation',
    description:
        'MVCC snapshot isolation for consistent point-in-time reads without locking',
    icon: Icons.camera_alt_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const SnapshotDemoPage(),
  ),
  FeatureInfo(
    name: 'Bloom Filter',
    description:
        'Bloom filter for fast probabilistic key existence checking with low memory',
    icon: Icons.filter_alt_rounded,
    category: FeatureCategory.performance,
    builder: (_) => const BloomFilterDemoPage(),
  ),

  // ── Sync & Distribution ──
  FeatureInfo(
    name: 'Sync Layer',
    description:
        'Sync layer with in-memory backend for testing and real-time data synchronization',
    icon: Icons.cloud_sync_rounded,
    category: FeatureCategory.sync,
    builder: (_) => const SyncDemoPage(),
  ),
  FeatureInfo(
    name: 'CDC',
    description:
        'Change Data Capture stream for integration pipelines and event-driven sync',
    icon: Icons.stream_rounded,
    category: FeatureCategory.sync,
    builder: (_) => const CdcDemoPage(),
  ),
  FeatureInfo(
    name: 'Replication',
    description:
        'Master-slave and peer-to-peer replication with conflict resolution strategies',
    icon: Icons.copy_all_rounded,
    category: FeatureCategory.sync,
    builder: (_) => const ReplicationDemoPage(),
  ),
  FeatureInfo(
    name: 'CRDT',
    description:
        'Conflict-free replicated data types for distributed systems without coordination',
    icon: Icons.merge_type_rounded,
    category: FeatureCategory.sync,
    builder: (_) => const CrdtDemoPage(),
  ),
  FeatureInfo(
    name: 'Event Sourcing',
    description:
        'Append-only event store with projections, replay, and state reconstruction',
    icon: Icons.event_note_rounded,
    category: FeatureCategory.sync,
    builder: (_) => const EventsourcingDemoPage(),
  ),
  FeatureInfo(
    name: 'Connection Pooling',
    description:
        'Connection pool with min/max connections, idle eviction, and health checks',
    icon: Icons.pool_rounded,
    category: FeatureCategory.sync,
    builder: (_) => const PoolDemoPage(),
  ),
  FeatureInfo(
    name: 'Observable Store',
    description:
        'Reactive data with RiftObservable, ObservableList, and ObservableMap',
    icon: Icons.visibility_rounded,
    category: FeatureCategory.sync,
    builder: (_) => const ObservableDemoPage(),
  ),

  // ── Developer Tools ──
  FeatureInfo(
    name: 'Testing Utilities',
    description:
        'Testing utilities with RiftTestUtil and MockBox for unit testing without I/O',
    icon: Icons.science_rounded,
    category: FeatureCategory.tools,
    builder: (_) => const TestingDemoPage(),
  ),
  FeatureInfo(
    name: 'Code Generator',
    description:
        'Smart code generator for auto-generating TypeAdapters with Dart 3 support',
    icon: Icons.auto_fix_high_rounded,
    category: FeatureCategory.tools,
    builder: (_) => const CodegenDemoPage(),
  ),
  FeatureInfo(
    name: 'Codec Mode',
    description:
        'No-codegen codec mode for manual serialization with custom adapters',
    icon: Icons.code_rounded,
    category: FeatureCategory.tools,
    builder: (_) => const CodecDemoPage(),
  ),
  FeatureInfo(
    name: 'Inspector',
    description:
        'Box inspection and debugging utilities for exploring stored data at runtime',
    icon: Icons.bug_report_rounded,
    category: FeatureCategory.tools,
    builder: (_) => const InspectorDemoPage(),
  ),
  FeatureInfo(
    name: 'Profiler',
    description:
        'Performance profiling for database operations with timing and throughput metrics',
    icon: Icons.speed_rounded,
    category: FeatureCategory.tools,
    builder: (_) => const ProfilerDemoPage(),
  ),
  FeatureInfo(
    name: 'Metrics / Observability',
    description:
        'Collect timing, counts, and success rates with Prometheus and Markdown export',
    icon: Icons.monitor_heart_rounded,
    category: FeatureCategory.tools,
    builder: (_) => const MetricsDemoPage(),
  ),
  FeatureInfo(
    name: 'Dart 3 Records',
    description:
        'Native Dart 3 Records and sealed classes support for modern data modeling',
    icon: Icons.data_array_rounded,
    category: FeatureCategory.tools,
    builder: (_) => const Dart3RecordsDemoPage(),
  ),
  FeatureInfo(
    name: 'Extension Types',
    description:
        'Dart 3 extension types for zero-cost type wrappers with compile-time safety',
    icon: Icons.data_object_rounded,
    category: FeatureCategory.tools,
    builder: (_) => const ExtensionTypesDemoPage(),
  ),
  FeatureInfo(
    name: 'Plugin System',
    description:
        'Plugin architecture for extending Rift with custom storage, adapters, and hooks',
    icon: Icons.plumbing_rounded,
    category: FeatureCategory.tools,
    builder: (_) => const PluginDemoPage(),
  ),
  FeatureInfo(
    name: 'CLI Tools',
    description:
        'CLI tools for database inspection, migration, and management from terminal',
    icon: Icons.terminal_rounded,
    category: FeatureCategory.tools,
    builder: (_) => const CliDemoPage(),
  ),

  // ── Platform & Integration ──
  FeatureInfo(
    name: 'Web Performance',
    description:
        'Web performance pack with IndexedDB batching, Web Workers, and lazy loading',
    icon: Icons.web_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const WebPerfDemoPage(),
  ),
  FeatureInfo(
    name: 'OPFS Support',
    description:
        'OPFS support for near-native web performance with synchronous file access',
    icon: Icons.language_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const OpfsDemoPage(),
  ),
  FeatureInfo(
    name: 'Memory-Mapped I/O',
    description:
        'Memory-mapped file I/O for fast random access to large data files on desktop',
    icon: Icons.storage_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const MmapDemoPage(),
  ),
  FeatureInfo(
    name: 'Isolate Support',
    description:
        'Native multi-isolate support with IsolatedRift for concurrent database access',
    icon: Icons.memory_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const IsolateDemoPage(),
  ),
  FeatureInfo(
    name: 'Aurora OS',
    description:
        'Aurora OS support via federated plugin architecture for Linux-based mobile',
    icon: Icons.phone_android_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const AuroraOsDemoPage(),
  ),
  FeatureInfo(
    name: 'SharedArrayBuffer',
    description:
        'SharedArrayBuffer for concurrent web worker access with Atomics-based sync',
    icon: Icons.share_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const SharedBufferDemoPage(),
  ),
  FeatureInfo(
    name: 'Backup & Restore',
    description:
        'Full and incremental backup with JSON export/import for data portability',
    icon: Icons.backup_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const BackupDemoPage(),
  ),
  FeatureInfo(
    name: 'Incremental Export',
    description:
        'Incremental export that only exports changes since the last export timestamp',
    icon: Icons.upload_file_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const IncrementalExportDemoPage(),
  ),
  FeatureInfo(
    name: 'File Versioning',
    description:
        'File format versioning with RIFT header and flags for forward compatibility',
    icon: Icons.insert_drive_file_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const FileVersioningDemoPage(),
  ),
  FeatureInfo(
    name: 'rift Migration',
    description:
        'Migration helper from rift and rift_ce to Rift with automatic data conversion',
    icon: Icons.swap_horiz_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const RiftMigrationDemoPage(),
  ),
  FeatureInfo(
    name: 'State Management',
    description:
        'Integration with Riverpod and Bloc state management for reactive apps',
    icon: Icons.hub_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const StateMgmtDemoPage(),
  ),
  FeatureInfo(
    name: 'Signals',
    description:
        'Reactive signals for automatic UI updates with fine-grained reactivity',
    icon: Icons.notifications_active_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const SignalDemoPage(),
  ),
  FeatureInfo(
    name: 'Reactive Forms',
    description:
        'Reactive forms with auto-save, dirty tracking, and real-time validation',
    icon: Icons.edit_note_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const FormsDemoPage(),
  ),
  FeatureInfo(
    name: 'Lazy Loading',
    description:
        'Eager, lazy, and on-demand loading strategies with prefetch and batch support',
    icon: Icons.hourglass_top_rounded,
    category: FeatureCategory.platform,
    builder: (_) => const LazyStrategyDemoPage(),
  ),
];

// ─── Home Page ─────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FeatureCategory? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<FeatureInfo> get _filteredFeatures {
    var features = allFeatures;
    if (_selectedCategory != null) {
      features =
          features.where((f) => f.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      features = features.where((f) {
        return f.name.toLowerCase().contains(q) ||
            f.description.toLowerCase().contains(q);
      }).toList();
    }
    return features;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredFeatures;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          // ── Large Title Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF).withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFF007AFF),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Rift',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // About button
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const AboutPage()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withAlpha(12)
                                    : Colors.black.withAlpha(6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 20,
                                color: isDark ? Colors.white54 : Colors.black38,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Settings button
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const SettingsPage()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withAlpha(12)
                                    : Colors.black.withAlpha(6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.settings_rounded,
                                size: 20,
                                color: isDark ? Colors.white54 : Colors.black38,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Theme toggle
                          GestureDetector(
                            onTap: () {
                              final appState = context
                                  .findAncestorStateOfType<RiftDemoAppState>();
                              appState?.toggleTheme();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withAlpha(12)
                                    : Colors.black.withAlpha(6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                size: 20,
                                color: isDark ? Colors.white54 : Colors.black38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Large title
                  Text(
                    'Explore',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      letterSpacing: -1.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${allFeatures.length} features to discover',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Statistics Cards ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF).withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.apps_rounded,
                              size: 20,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${allFeatures.length}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Features',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5856D6).withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.category_rounded,
                              size: 20,
                              color: Color(0xFF5856D6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${FeatureCategory.values.length}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1C1C1E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Search Bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search features...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.white24 : Colors.black26,
                      size: 22,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: false,
                  ),
                ),
              ),
            ),
          ),

          // ── Category Shortcuts (only when no search/filter) ──
          if (_searchQuery.isEmpty && _selectedCategory == null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Browse by Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF1C1C1E),
                            letterSpacing: -0.3,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FeatureBrowserPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.5,
                      children: FeatureCategory.values.map((cat) {
                        final count =
                            allFeatures.where((f) => f.category == cat).length;
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FeatureBrowserPage(
                                  initialCategory: cat,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1C1C1E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cat.color.withAlpha(26),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    cat.icon,
                                    size: 18,
                                    color: cat.color,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        cat.label.split(' ')[0],
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1C1C1E),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '$count features',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

          // ── Category Pills ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: FeatureCategory.values.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategory == null;
                      return _Pill(
                        label: 'All',
                        icon: Icons.apps_rounded,
                        color: const Color(0xFF007AFF),
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedCategory = null),
                      );
                    }
                    final cat = FeatureCategory.values[index - 1];
                    final isSelected = _selectedCategory == cat;
                    return _Pill(
                      label: cat.label,
                      icon: cat.icon,
                      color: cat.color,
                      isSelected: isSelected,
                      onTap: () => setState(() {
                        _selectedCategory = isSelected ? null : cat;
                      }),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Result count ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} features',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white30 : Colors.black26,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_selectedCategory != null || _searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = null;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF007AFF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Feature List (Grouped by Category if no filter) ──
          if (_selectedCategory == null && _searchQuery.isEmpty)
            ..._buildGroupedSlivers(isDark)
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _FeatureRow(
                    feature: filtered[index],
                    isDark: isDark,
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedSlivers(bool isDark) {
    final slivers = <Widget>[];
    for (final cat in FeatureCategory.values) {
      final features = allFeatures.where((f) => f.category == cat).toList();
      if (features.isEmpty) continue;

      // Category header
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
          child: Row(
            children: [
              Icon(cat.icon, size: 16, color: cat.color),
              const SizedBox(width: 8),
              Text(
                cat.label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${features.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ));

      // Feature rows
      slivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: _FeatureRow(feature: features[index], isDark: isDark),
            ),
            childCount: features.length,
          ),
        ),
      ));
    }
    return slivers;
  }
}

// ─── Category Pill ─────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature Row (iOS Settings-style) ──────────────────────────────

class _FeatureRow extends StatelessWidget {
  final FeatureInfo feature;
  final bool isDark;

  const _FeatureRow({required this.feature, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final catColor = feature.category.color;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: feature.builder),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: catColor.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(feature.icon, size: 18, color: catColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feature.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ],
        ),
      ),
    );
  }
}

