/// Data diff and patch operations (RFC 6902 JSON Patch compatible).
///
/// Compute diffs between data states and apply patches to transform
/// one state into another. Supports JSON Patch operations.
///
/// Usage:
/// ```dart
/// final differ = DataDiffer();
/// final patch = differ.diff(
///   {'name': 'Idris', 'age': 25},
///   {'name': 'Ahmed', 'age': 25, 'city': 'Cairo'},
/// );
///
/// print(patch.operations);
/// // [ReplaceOp(/name, Ahmed), AddOp(/city, Cairo)]
///
/// // Apply patch
/// final result = patch.apply({'name': 'Idris', 'age': 25});
/// print(result); // {name: Ahmed, age: 25, city: Cairo}
///
/// // Reverse patch
/// final reversed = patch.reverse().apply(result);
/// print(reversed); // {name: Idris, age: 25}
/// ```
library;

/// Types of patch operations.
enum PatchOperationType {
  /// Add a value at a path.
  add,

  /// Remove a value at a path.
  remove,

  /// Replace a value at a path.
  replace,

  /// Move a value from one path to another.
  move,

  /// Copy a value from one path to another.
  copy,

  /// Test that a value at a path equals an expected value.
  test,
}

/// A single patch operation (RFC 6902 JSON Patch).
class PatchOperation {
  /// The type of operation.
  final PatchOperationType type;

  /// The JSON Pointer path (e.g., '/name', '/items/0').
  final String path;

  /// The value for add, replace, copy, and test operations.
  final dynamic value;

  /// The source path for move and copy operations.
  final String? from;

  /// Creates a [PatchOperation].
  const PatchOperation({
    required this.type,
    required this.path,
    this.value,
    this.from,
  });

  /// Creates an add operation.
  factory PatchOperation.add(String path, dynamic value) =>
      PatchOperation(type: PatchOperationType.add, path: path, value: value);

  /// Creates a remove operation.
  factory PatchOperation.remove(String path) =>
      PatchOperation(type: PatchOperationType.remove, path: path);

  /// Creates a replace operation.
  factory PatchOperation.replace(String path, dynamic value) => PatchOperation(
    type: PatchOperationType.replace,
    path: path,
    value: value,
  );

  /// Creates a move operation.
  factory PatchOperation.move(String from, String path) =>
      PatchOperation(type: PatchOperationType.move, path: path, from: from);

  /// Creates a copy operation.
  factory PatchOperation.copy(String from, String path) =>
      PatchOperation(type: PatchOperationType.copy, path: path, from: from);

  /// Creates a test operation.
  factory PatchOperation.test(String path, dynamic value) =>
      PatchOperation(type: PatchOperationType.test, path: path, value: value);

  /// Converts the operation to RFC 6902 JSON format.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'op': type.name, 'path': path};
    if (value != null) json['value'] = value;
    if (from != null) json['from'] = from;
    return json;
  }

  /// Creates a [PatchOperation] from RFC 6902 JSON format.
  factory PatchOperation.fromJson(Map<String, dynamic> json) {
    final opName = json['op'] as String;
    final type = PatchOperationType.values.firstWhere(
      (t) => t.name == opName,
      orElse: () => PatchOperationType.add,
    );
    return PatchOperation(
      type: type,
      path: json['path'] as String,
      value: json['value'],
      from: json['from'] as String?,
    );
  }

  @override
  String toString() =>
      'PatchOperation(${type.name}, $path${value != null ? ', $value' : ''}${from != null ? ', from: $from' : ''})';
}

/// A patch that can transform one data state into another.
class DataPatch {
  /// The list of operations in this patch.
  final List<PatchOperation> operations;

  /// Creates a [DataPatch].
  const DataPatch(this.operations);

  /// Whether the patch has no operations.
  bool get isEmpty => operations.isEmpty;

  /// The number of operations.
  int get length => operations.length;

  /// Applies this patch to [data] and returns the result.
  ///
  /// Throws [PatchException] if the patch cannot be applied.
  Map<String, dynamic> apply(Map<String, dynamic> data) {
    var result = Map<String, dynamic>.from(data);

    for (final op in operations) {
      result = _applyOperation(result, op);
    }

    return result;
  }

  /// Creates a reverse patch that undoes this patch.
  ///
  /// The reverse patch, when applied to the result of this patch,
  /// returns the original data.
  DataPatch reverse() {
    final reversedOps = <PatchOperation>[];

    // Reverse operations in reverse order
    for (final op in operations.reversed) {
      switch (op.type) {
        case PatchOperationType.add:
          reversedOps.add(PatchOperation.remove(op.path));
          break;
        case PatchOperationType.remove:
          // We don't have the old value for remove, so this is a best effort
          reversedOps.add(PatchOperation.add(op.path, op.value));
          break;
        case PatchOperationType.replace:
          reversedOps.add(PatchOperation.replace(op.path, op.value));
          break;
        case PatchOperationType.move:
          reversedOps.add(PatchOperation.move(op.path, op.from!));
          break;
        case PatchOperationType.copy:
          reversedOps.add(PatchOperation.remove(op.path));
          break;
        case PatchOperationType.test:
          // Test operations don't need reversing
          break;
      }
    }

    return DataPatch(reversedOps);
  }

  Map<String, dynamic> _applyOperation(
    Map<String, dynamic> data,
    PatchOperation op,
  ) {
    final result = Map<String, dynamic>.from(data);
    final segments = _parsePath(op.path);

    switch (op.type) {
      case PatchOperationType.add:
        _setPath(result, segments, op.value);
        break;

      case PatchOperationType.remove:
        _removePath(result, segments);
        break;

      case PatchOperationType.replace:
        _setPath(result, segments, op.value);
        break;

      case PatchOperationType.move:
        final fromSegments = _parsePath(op.from!);
        final value = _getPath(result, fromSegments);
        _removePath(result, fromSegments);
        _setPath(result, segments, value);
        break;

      case PatchOperationType.copy:
        final fromSegments = _parsePath(op.from!);
        final value = _getPath(result, fromSegments);
        _setPath(result, segments, value);
        break;

      case PatchOperationType.test:
        final current = _getPath(result, segments);
        if (current != op.value) {
          throw PatchException(
            'Test failed at ${op.path}: expected ${op.value}, got $current',
          );
        }
        break;
    }

    return result;
  }

  List<String> _parsePath(String path) {
    if (path == '/' || path.isEmpty) return [];
    if (path.startsWith('/')) path = path.substring(1);
    return path
        .split('/')
        .map((s) => s.replaceAll('~1', '/').replaceAll('~0', '~'))
        .toList();
  }

  dynamic _getPath(Map<String, dynamic> data, List<String> segments) {
    dynamic current = data;
    for (final segment in segments) {
      if (current is Map) {
        current = current[segment];
      } else if (current is List) {
        final index = int.tryParse(segment);
        if (index != null && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }

  void _setPath(
    Map<String, dynamic> data,
    List<String> segments,
    dynamic value,
  ) {
    if (segments.isEmpty) return;

    dynamic current = data;
    for (int i = 0; i < segments.length - 1; i++) {
      final segment = segments[i];
      if (current is Map) {
        current.putIfAbsent(segment, () => <String, dynamic>{});
        current = current[segment];
      }
    }

    final lastSegment = segments.last;
    if (current is Map) {
      current[lastSegment] = value;
    } else if (current is List) {
      final index = int.tryParse(lastSegment);
      if (index != null) {
        if (lastSegment == '-') {
          (current).add(value);
        } else if (index < current.length) {
          current[index] = value;
        } else {
          (current).add(value);
        }
      }
    }
  }

  void _removePath(Map<String, dynamic> data, List<String> segments) {
    if (segments.isEmpty) return;

    dynamic current = data;
    for (int i = 0; i < segments.length - 1; i++) {
      final segment = segments[i];
      if (current is Map) {
        current = current[segment];
      }
    }

    final lastSegment = segments.last;
    if (current is Map) {
      current.remove(lastSegment);
    } else if (current is List) {
      final index = int.tryParse(lastSegment);
      if (index != null && index < current.length) {
        (current).removeAt(index);
      }
    }
  }

  /// Converts the patch to RFC 6902 JSON format.
  List<Map<String, dynamic>> toJson() =>
      operations.map((op) => op.toJson()).toList();

  /// Creates a [DataPatch] from RFC 6902 JSON format.
  static DataPatch fromJson(List<Map<String, dynamic>> json) =>
      DataPatch(json.map(PatchOperation.fromJson).toList());
}

/// Computes deep diffs between two maps.
class DataDiffer {
  /// Computes the diff between [from] and [to].
  ///
  /// Returns a [DataPatch] with operations that transform [from]
  /// into [to].
  DataPatch diff(
    Map<String, dynamic> from,
    Map<String, dynamic> to, [
    String basePath = '/',
  ]) {
    final operations = <PatchOperation>[];
    final allKeys = <String>{...from.keys, ...to.keys};

    for (final key in allKeys) {
      final path = '$basePath$key';
      final inFrom = from.containsKey(key);
      final inTo = to.containsKey(key);

      if (!inFrom && inTo) {
        // Added
        operations.add(PatchOperation.add(path, to[key]));
      } else if (inFrom && !inTo) {
        // Removed
        operations.add(PatchOperation.remove(path));
      } else if (inFrom && inTo) {
        final fromValue = from[key];
        final toValue = to[key];

        if (fromValue != toValue) {
          if (fromValue is Map && toValue is Map) {
            // Recurse into nested maps
            final nestedPatch = diff(
              Map<String, dynamic>.from(fromValue),
              Map<String, dynamic>.from(toValue),
              '$path/',
            );
            operations.addAll(nestedPatch.operations);
          } else {
            operations.add(PatchOperation.replace(path, toValue));
          }
        }
      }
    }

    return DataPatch(operations);
  }

  /// Computes a diff and returns only the changed paths.
  List<String> changedPaths(
    Map<String, dynamic> from,
    Map<String, dynamic> to,
  ) {
    final patch = diff(from, to);
    return patch.operations.map((op) => op.path).toList();
  }
}

/// Exception thrown when a patch cannot be applied.
class PatchException implements Exception {
  /// Description of the error.
  final String message;

  /// Creates a [PatchException].
  const PatchException(this.message);

  @override
  String toString() => 'PatchException: $message';
}
