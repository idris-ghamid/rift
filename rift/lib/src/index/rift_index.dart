import 'package:rift/src/index/index_manager.dart';

/// Global singleton index manager shared across all Rift boxes.
///
/// This is the single source of truth for all secondary indexes.
/// It is used internally by [BoxBaseImpl] and [RiftQuery].
final globalIndexManager = IndexManager();
