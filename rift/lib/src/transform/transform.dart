/// Data transformation pipeline for processing data on read/write.
///
/// Provides an ETL-style pipeline for transforming data as it
/// passes through Rift. Transforms can be applied on read, write,
/// or both.
///
/// Usage:
/// ```dart
/// final pipeline = TransformPipeline()
///   .add(RenameFieldTransform('oldName', 'newName'))
///   .add(FilterFieldsTransform(['name', 'age', 'email']))
///   .add(MapValuesTransform('age', (v) => (v as int) + 1));
///
/// // Apply on write
/// final transformed = pipeline.applyWrite({'oldName': 'Idris', 'age': 24});
/// // Result: {'newName': 'Idris', 'age': 25}
/// ```
library;

/// When to apply a transform.
enum TransformPhase {
  /// Apply during write (before storage).
  write,

  /// Apply during read (after retrieval).
  read,

  /// Apply during both read and write.
  both,
}

/// Base class for data transforms.
///
/// Subclass this to create custom transforms for the pipeline.
abstract class DataTransform {
  /// Optional name for debugging.
  String get name => runtimeType.toString();

  /// When this transform should be applied.
  TransformPhase get phase;

  /// Applies the transform to [data].
  ///
  /// Returns the transformed data. May return the same map
  /// (mutated) or a new map.
  Map<String, dynamic> apply(Map<String, dynamic> data);

  /// Applies the transform asynchronously.
  ///
  /// Override this for transforms that require async operations
  /// (e.g., network lookups, file reads).
  Future<Map<String, dynamic>> applyAsync(Map<String, dynamic> data) async {
    return apply(data);
  }

  /// Whether this transform should apply in the given [phase].
  bool appliesIn(TransformPhase phase) {
    if (this.phase == TransformPhase.both) return true;
    return this.phase == phase;
  }
}

/// A pipeline of transforms applied in sequence.
class TransformPipeline {
  /// The ordered list of transforms.
  final List<DataTransform> _transforms = [];

  /// Creates an empty [TransformPipeline].
  TransformPipeline();

  /// Adds a [transform] to the pipeline.
  ///
  /// Transforms are applied in the order they are added.
  TransformPipeline add(DataTransform transform) {
    _transforms.add(transform);
    return this;
  }

  /// Removes a [transform] from the pipeline.
  TransformPipeline remove(DataTransform transform) {
    _transforms.remove(transform);
    return this;
  }

  /// Inserts a [transform] at the given [index].
  void insert(int index, DataTransform transform) {
    _transforms.insert(index, transform);
  }

  /// The number of transforms in the pipeline.
  int get length => _transforms.length;

  /// Whether the pipeline has no transforms.
  bool get isEmpty => _transforms.isEmpty;

  /// Gets an unmodifiable list of transforms.
  List<DataTransform> get transforms => List.unmodifiable(_transforms);

  /// Applies all write-phase transforms to [data].
  Map<String, dynamic> applyWrite(Map<String, dynamic> data) {
    var result = Map<String, dynamic>.from(data);
    for (final transform in _transforms) {
      if (transform.appliesIn(TransformPhase.write)) {
        result = transform.apply(result);
      }
    }
    return result;
  }

  /// Applies all read-phase transforms to [data].
  Map<String, dynamic> applyRead(Map<String, dynamic> data) {
    var result = Map<String, dynamic>.from(data);
    for (final transform in _transforms) {
      if (transform.appliesIn(TransformPhase.read)) {
        result = transform.apply(result);
      }
    }
    return result;
  }

  /// Applies all write-phase transforms asynchronously.
  Future<Map<String, dynamic>> applyWriteAsync(
    Map<String, dynamic> data,
  ) async {
    var result = Map<String, dynamic>.from(data);
    for (final transform in _transforms) {
      if (transform.appliesIn(TransformPhase.write)) {
        result = await transform.applyAsync(result);
      }
    }
    return result;
  }

  /// Applies all read-phase transforms asynchronously.
  Future<Map<String, dynamic>> applyReadAsync(Map<String, dynamic> data) async {
    var result = Map<String, dynamic>.from(data);
    for (final transform in _transforms) {
      if (transform.appliesIn(TransformPhase.read)) {
        result = await transform.applyAsync(result);
      }
    }
    return result;
  }

  /// Clears all transforms from the pipeline.
  void clear() {
    _transforms.clear();
  }
}

// --- Built-in Transforms ---

/// Renames a field from [oldName] to [newName].
class RenameFieldTransform extends DataTransform {
  /// The current field name.
  final String oldName;

  /// The new field name.
  final String newName;

  /// When to apply this transform.
  @override
  final TransformPhase phase;

  /// Creates a [RenameFieldTransform].
  RenameFieldTransform(
    this.oldName,
    this.newName, {
    this.phase = TransformPhase.both,
  });

  @override
  Map<String, dynamic> apply(Map<String, dynamic> data) {
    if (data.containsKey(oldName)) {
      data[newName] = data.remove(oldName);
    }
    return data;
  }
}

/// Filters data to only include the specified [fields].
class FilterFieldsTransform extends DataTransform {
  /// The field names to keep.
  final Set<String> fields;

  /// When to apply this transform.
  @override
  final TransformPhase phase;

  /// Whether to keep (true) or exclude (false) the listed fields.
  final bool inclusive;

  /// Creates a [FilterFieldsTransform].
  FilterFieldsTransform(
    Iterable<String> fields, {
    this.phase = TransformPhase.both,
    this.inclusive = true,
  }) : fields = Set.from(fields);

  @override
  Map<String, dynamic> apply(Map<String, dynamic> data) {
    if (inclusive) {
      return Map.fromEntries(data.entries.where((e) => fields.contains(e.key)));
    } else {
      return Map.fromEntries(
        data.entries.where((e) => !fields.contains(e.key)),
      );
    }
  }
}

/// Transforms the value of a specific field using a function.
class MapValuesTransform extends DataTransform {
  /// The field to transform.
  final String field;

  /// The transformation function.
  final dynamic Function(dynamic value) mapper;

  /// When to apply this transform.
  @override
  final TransformPhase phase;

  /// Creates a [MapValuesTransform].
  MapValuesTransform(
    this.field,
    this.mapper, {
    this.phase = TransformPhase.both,
  });

  @override
  Map<String, dynamic> apply(Map<String, dynamic> data) {
    if (data.containsKey(field)) {
      data[field] = mapper(data[field]);
    }
    return data;
  }
}

/// Converts the type of a specific field.
class TypeConvertTransform extends DataTransform {
  /// The field to convert.
  final String field;

  /// The target type name.
  final String targetType;

  /// When to apply this transform.
  @override
  final TransformPhase phase;

  /// Creates a [TypeConvertTransform].
  TypeConvertTransform(
    this.field,
    this.targetType, {
    this.phase = TransformPhase.both,
  });

  @override
  Map<String, dynamic> apply(Map<String, dynamic> data) {
    if (!data.containsKey(field)) return data;
    final value = data[field];

    switch (targetType) {
      case 'String':
        data[field] = value.toString();
        break;
      case 'int':
        if (value is double) {
          data[field] = value.toInt();
        } else if (value is String) {
          data[field] = int.tryParse(value) ?? value;
        }
        break;
      case 'double':
        if (value is int) {
          data[field] = value.toDouble();
        } else if (value is String) {
          data[field] = double.tryParse(value) ?? value;
        }
        break;
      case 'bool':
        if (value is String) {
          data[field] = value.toLowerCase() == 'true';
        } else if (value is int) {
          data[field] = value != 0;
        }
        break;
      default:
        // No conversion possible
        break;
    }
    return data;
  }
}

/// Adds a computed field based on existing fields.
class ComputedFieldTransform extends DataTransform {
  /// The name of the new field.
  final String fieldName;

  /// The function to compute the field value.
  final dynamic Function(Map<String, dynamic> data) compute;

  /// When to apply this transform.
  @override
  final TransformPhase phase;

  /// Creates a [ComputedFieldTransform].
  ComputedFieldTransform(
    this.fieldName,
    this.compute, {
    this.phase = TransformPhase.both,
  });

  @override
  Map<String, dynamic> apply(Map<String, dynamic> data) {
    data[fieldName] = compute(data);
    return data;
  }
}
