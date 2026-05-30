import 'package:rift/rift.dart';

/// MongoDB-style aggregation pipeline for Rift.
/// Allows complex data analysis without extracting data from the database.

class AggregationPipeline {
  final List<_PipelineStage> _stages = [];

  /// Filter documents (like MongoDB $match).
  AggregationPipeline match(bool Function(Map<String, dynamic>) predicate) {
    _stages.add(_MatchStage(predicate));
    return this;
  }

  /// Group documents by [fieldKey] and compute [operations].
  AggregationPipeline group(String fieldKey, List<AggregationOp> operations) {
    _stages.add(_GroupStage(fieldKey, operations));
    return this;
  }

  /// Sort results by [field].
  AggregationPipeline sort(String field, {bool descending = false}) {
    _stages.add(_SortStage(field, descending));
    return this;
  }

  /// Limit results to [count] items.
  AggregationPipeline limit(int count) {
    _stages.add(_LimitStage(count));
    return this;
  }

  /// Skip the first [count] results.
  AggregationPipeline skip(int count) {
    _stages.add(_SkipStage(count));
    return this;
  }

  /// Project/transform results (like MongoDB $project).
  AggregationPipeline project(
    Map<String, dynamic> Function(Map<String, dynamic>) transformer,
  ) {
    _stages.add(_ProjectStage(transformer));
    return this;
  }

  /// Unwind an array field (like MongoDB $unwind).
  /// Creates one document per element in the array at [fieldPath].
  AggregationPipeline unwind(String fieldPath) {
    _stages.add(_UnwindStage(fieldPath));
    return this;
  }

  /// Count the number of documents.
  AggregationPipeline count(String outputField) {
    _stages.add(_CountStage(outputField));
    return this;
  }

  /// Add computed fields to each document.
  AggregationPipeline addFields(
    Map<String, dynamic> Function(Map<String, dynamic>) computer,
  ) {
    _stages.add(_AddFieldsStage(computer));
    return this;
  }

  /// Execute the pipeline on a [Box].
  Future<List<Map<String, dynamic>>> execute(Box box) async {
    var data = <Map<String, dynamic>>[];
    // Convert box data to maps
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        data.add({'_key': key, ...Map<String, dynamic>.from(value)});
      } else {
        data.add({'_key': key, '_value': value});
      }
    }
    // Apply each stage
    for (final stage in _stages) {
      data = stage.apply(data);
    }
    return data;
  }

  /// Execute the pipeline on a list of maps (without a Box).
  List<Map<String, dynamic>> executeOnList(List<Map<String, dynamic>> data) {
    var result = List<Map<String, dynamic>>.from(data);
    for (final stage in _stages) {
      result = stage.apply(result);
    }
    return result;
  }

  /// Number of stages in the pipeline.
  int get stageCount => _stages.length;

  /// Reset the pipeline (remove all stages).
  void reset() {
    _stages.clear();
  }
}

/// Abstract base class for pipeline stages.
abstract class _PipelineStage {
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> data);
}

/// $match stage - filters documents.
class _MatchStage extends _PipelineStage {
  final bool Function(Map<String, dynamic>) predicate;

  _MatchStage(this.predicate);

  @override
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> data) {
    return data.where(predicate).toList();
  }
}

/// $group stage - groups documents and computes aggregations.
class _GroupStage extends _PipelineStage {
  final String fieldKey;
  final List<AggregationOp> operations;

  _GroupStage(this.fieldKey, this.operations);

  @override
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> data) {
    final groups = <dynamic, List<Map<String, dynamic>>>{};

    for (final doc in data) {
      final keyValue = _getNestedValue(doc, fieldKey);
      groups.putIfAbsent(keyValue, () => []).add(doc);
    }

    final result = <Map<String, dynamic>>[];
    for (final entry in groups.entries) {
      final groupDoc = <String, dynamic>{'_id': entry.key};

      for (final op in operations) {
        final inputValues = entry.value
            .map((doc) => _getNestedValue(doc, op.inputField ?? op.outputField))
            .where((v) => v != null)
            .toList();

        switch (op.type) {
          case AggregationOpType.sum:
            groupDoc[op.outputField] = inputValues.fold<num>(
              0,
              (sum, v) => sum + (v is num ? v : 0),
            );
            break;
          case AggregationOpType.avg:
            final nums = inputValues.whereType<num>().toList();
            groupDoc[op.outputField] = nums.isEmpty
                ? 0
                : nums.fold<num>(0, (sum, v) => sum + v) / nums.length;
            break;
          case AggregationOpType.min:
            final nums = inputValues.whereType<num>().toList();
            groupDoc[op.outputField] = nums.isEmpty
                ? null
                : nums.reduce((a, b) => a < b ? a : b);
            break;
          case AggregationOpType.max:
            final nums = inputValues.whereType<num>().toList();
            groupDoc[op.outputField] = nums.isEmpty
                ? null
                : nums.reduce((a, b) => a > b ? a : b);
            break;
          case AggregationOpType.count:
            groupDoc[op.outputField] = entry.value.length;
            break;
          case AggregationOpType.first:
            groupDoc[op.outputField] = inputValues.isNotEmpty
                ? inputValues.first
                : null;
            break;
          case AggregationOpType.last:
            groupDoc[op.outputField] = inputValues.isNotEmpty
                ? inputValues.last
                : null;
            break;
        }
      }

      result.add(groupDoc);
    }

    return result;
  }
}

/// $sort stage - sorts documents.
class _SortStage extends _PipelineStage {
  final String field;
  final bool descending;

  _SortStage(this.field, this.descending);

  @override
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> data) {
    final sorted = List<Map<String, dynamic>>.from(data);
    sorted.sort((a, b) {
      final aVal = _getNestedValue(a, field);
      final bVal = _getNestedValue(b, field);
      int cmp;
      if (aVal == null && bVal == null) {
        cmp = 0;
      } else if (aVal == null) {
        cmp = -1;
      } else if (bVal == null) {
        cmp = 1;
      } else if (aVal is Comparable && bVal is Comparable) {
        cmp = (aVal).compareTo(bVal);
      } else {
        cmp = aVal.toString().compareTo(bVal.toString());
      }
      return descending ? -cmp : cmp;
    });
    return sorted;
  }
}

/// $limit stage - limits result count.
class _LimitStage extends _PipelineStage {
  final int count;

  _LimitStage(this.count);

  @override
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> data) {
    return data.take(count).toList();
  }
}

/// $skip stage - skips first N results.
class _SkipStage extends _PipelineStage {
  final int count;

  _SkipStage(this.count);

  @override
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> data) {
    return data.skip(count).toList();
  }
}

/// $project stage - transforms documents.
class _ProjectStage extends _PipelineStage {
  final Map<String, dynamic> Function(Map<String, dynamic>) transformer;

  _ProjectStage(this.transformer);

  @override
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> data) {
    return data.map(transformer).toList();
  }
}

/// $unwind stage - explodes array fields.
class _UnwindStage extends _PipelineStage {
  final String fieldPath;

  _UnwindStage(this.fieldPath);

  @override
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> data) {
    final result = <Map<String, dynamic>>[];
    for (final doc in data) {
      final value = _getNestedValue(doc, fieldPath);
      if (value is List) {
        for (final item in value) {
          final newDoc = Map<String, dynamic>.from(doc);
          _setNestedValue(newDoc, fieldPath, item);
          result.add(newDoc);
        }
      } else {
        result.add(doc);
      }
    }
    return result;
  }
}

/// $count stage - counts documents.
class _CountStage extends _PipelineStage {
  final String outputField;

  _CountStage(this.outputField);

  @override
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> data) {
    return [
      {outputField: data.length},
    ];
  }
}

/// $addFields stage - adds computed fields.
class _AddFieldsStage extends _PipelineStage {
  final Map<String, dynamic> Function(Map<String, dynamic>) computer;

  _AddFieldsStage(this.computer);

  @override
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> data) {
    return data.map((doc) {
      final newDoc = Map<String, dynamic>.from(doc);
      final additions = computer(doc);
      newDoc.addAll(additions);
      return newDoc;
    }).toList();
  }
}

/// Aggregation operation type.
enum AggregationOpType {
  /// Sum of values.
  sum,

  /// Average of values.
  avg,

  /// Minimum value.
  min,

  /// Maximum value.
  max,

  /// Count of documents.
  count,

  /// First value in the group.
  first,

  /// Last value in the group.
  last,
}

/// An aggregation operation to perform during grouping.
class AggregationOp {
  /// The name of the output field for the result.
  final String outputField;

  /// The type of aggregation operation.
  final AggregationOpType type;

  /// The input field to aggregate (defaults to outputField if null).
  final String? inputField;

  /// Create an aggregation operation.
  AggregationOp(this.outputField, this.type, {this.inputField});
}

/// Get a nested value from a map using dot notation.
dynamic _getNestedValue(Map<String, dynamic> doc, String fieldPath) {
  final parts = fieldPath.split('.');
  dynamic current = doc;
  for (final part in parts) {
    if (current is Map<String, dynamic>) {
      current = current[part];
    } else if (current is Map) {
      current = current[part];
    } else {
      return null;
    }
    if (current == null) return null;
  }
  return current;
}

/// Set a nested value in a map using dot notation.
void _setNestedValue(
  Map<String, dynamic> doc,
  String fieldPath,
  dynamic value,
) {
  final parts = fieldPath.split('.');
  dynamic current = doc;
  for (int i = 0; i < parts.length - 1; i++) {
    final part = parts[i];
    if (current is Map<String, dynamic>) {
      current.putIfAbsent(part, () => <String, dynamic>{});
      current = current[part];
    } else if (current is Map) {
      current.putIfAbsent(part, () => <String, dynamic>{});
      current = current[part];
    }
  }
  if (current is Map) {
    current[parts.last] = value;
  }
}
