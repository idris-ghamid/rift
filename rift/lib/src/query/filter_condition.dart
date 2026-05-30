import 'package:meta/meta.dart';

/// Operators supported by filter conditions.
enum FilterOperator {
  /// Field equals value.
  equalTo,

  /// Field is greater than value.
  greaterThan,

  /// Field is less than value.
  lessThan,

  /// Field is greater than or equal to value.
  greaterThanOrEqual,

  /// Field is less than or equal to value.
  lessThanOrEqual,

  /// Field value is in the given list.
  inList,

  /// Field value contains the given string.
  contains,

  /// Field value starts with the given string.
  startsWith,

  /// Field value is between two values (inclusive).
  between,
}

/// A single filter condition for a query.
///
/// Each condition targets a specific [field] with a [FilterOperator]
/// and one or more comparison [values].
@immutable
class FilterCondition {
  /// The name of the field to filter on.
  final String field;

  /// The comparison operator.
  final FilterOperator operator;

  /// The value(s) to compare against.
  ///
  /// For most operators this is a single-element list.
  /// For [FilterOperator.inList] this contains all acceptable values.
  /// For [FilterOperator.between] this contains [low, high].
  final List<dynamic> values;

  /// Create an equality filter.
  const FilterCondition.equalTo(this.field, dynamic value)
    : operator = FilterOperator.equalTo,
      values = const [];

  /// Create a greater-than filter.
  const FilterCondition.greaterThan(this.field, dynamic value)
    : operator = FilterOperator.greaterThan,
      values = const [];

  /// Create a less-than filter.
  const FilterCondition.lessThan(this.field, dynamic value)
    : operator = FilterOperator.lessThan,
      values = const [];

  /// Create a greater-than-or-equal filter.
  const FilterCondition.greaterThanOrEqual(this.field, dynamic value)
    : operator = FilterOperator.greaterThanOrEqual,
      values = const [];

  /// Create a less-than-or-equal filter.
  const FilterCondition.lessThanOrEqual(this.field, dynamic value)
    : operator = FilterOperator.lessThanOrEqual,
      values = const [];

  /// Create an in-list filter.
  const FilterCondition.inList(this.field, List<dynamic> list)
    : operator = FilterOperator.inList,
      values = const [];

  /// Create a contains filter (string contains substring).
  const FilterCondition.contains(this.field, String substring)
    : operator = FilterOperator.contains,
      values = const [];

  /// Create a starts-with filter (string starts with prefix).
  const FilterCondition.startsWith(this.field, String prefix)
    : operator = FilterOperator.startsWith,
      values = const [];

  /// Create a between filter (inclusive range).
  const FilterCondition.between(this.field, dynamic low, dynamic high)
    : operator = FilterOperator.between,
      values = const [];

  /// Internal constructor with explicit values list.
  const FilterCondition._({
    required this.field,
    required this.operator,
    required this.values,
  });

  /// Create a filter condition from the named parameters of [RiftQuery.where].
  factory FilterCondition.fromWhere(
    String field, {
    dynamic equalTo,
    dynamic greaterThan,
    dynamic lessThan,
    dynamic greaterThanOrEqual,
    dynamic lessThanOrEqual,
    List<dynamic>? inList,
    String? contains,
    String? startsWith,
  }) {
    if (equalTo != null) {
      return FilterCondition._(
        field: field,
        operator: FilterOperator.equalTo,
        values: [equalTo],
      );
    } else if (greaterThan != null) {
      return FilterCondition._(
        field: field,
        operator: FilterOperator.greaterThan,
        values: [greaterThan],
      );
    } else if (lessThan != null) {
      return FilterCondition._(
        field: field,
        operator: FilterOperator.lessThan,
        values: [lessThan],
      );
    } else if (greaterThanOrEqual != null) {
      return FilterCondition._(
        field: field,
        operator: FilterOperator.greaterThanOrEqual,
        values: [greaterThanOrEqual],
      );
    } else if (lessThanOrEqual != null) {
      return FilterCondition._(
        field: field,
        operator: FilterOperator.lessThanOrEqual,
        values: [lessThanOrEqual],
      );
    } else if (inList != null) {
      return FilterCondition._(
        field: field,
        operator: FilterOperator.inList,
        values: inList,
      );
    } else if (contains != null) {
      return FilterCondition._(
        field: field,
        operator: FilterOperator.contains,
        values: [contains],
      );
    } else if (startsWith != null) {
      return FilterCondition._(
        field: field,
        operator: FilterOperator.startsWith,
        values: [startsWith],
      );
    } else {
      throw ArgumentError(
        'At least one comparison parameter must be provided for field "$field".',
      );
    }
  }

  /// Evaluate this condition against a field value extracted from an object.
  ///
  /// Returns `true` if the condition is satisfied, `false` otherwise.
  bool evaluate(dynamic fieldValue) {
    switch (operator) {
      case FilterOperator.equalTo:
        return fieldValue == values[0];

      case FilterOperator.greaterThan:
        return _compare(fieldValue, values[0]) > 0;

      case FilterOperator.lessThan:
        return _compare(fieldValue, values[0]) < 0;

      case FilterOperator.greaterThanOrEqual:
        return _compare(fieldValue, values[0]) >= 0;

      case FilterOperator.lessThanOrEqual:
        return _compare(fieldValue, values[0]) <= 0;

      case FilterOperator.inList:
        return values.contains(fieldValue);

      case FilterOperator.contains:
        if (fieldValue is String && values[0] is String) {
          return fieldValue.contains(values[0] as String);
        }
        return false;

      case FilterOperator.startsWith:
        if (fieldValue is String && values[0] is String) {
          return fieldValue.startsWith(values[0] as String);
        }
        return false;

      case FilterOperator.between:
        return _compare(fieldValue, values[0]) >= 0 &&
            _compare(fieldValue, values[1]) <= 0;
    }
  }

  /// Compare two comparable values.
  ///
  /// Returns negative if [a] < [b], zero if equal, positive if [a] > [b].
  /// Handles nulls (null is considered less than any non-null value).
  static int _compare(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;

    if (a is Comparable && b is Comparable && a.runtimeType == b.runtimeType) {
      return a.compareTo(b);
    }

    // Fallback: try numeric comparison
    if (a is num && b is num) {
      return a.compareTo(b);
    }

    // Fallback: string comparison
    if (a is String && b is String) {
      return a.compareTo(b);
    }

    // Last resort: compare as strings
    return a.toString().compareTo(b.toString());
  }

  @override
  String toString() =>
      'FilterCondition(field: $field, operator: $operator, values: $values)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterCondition &&
          field == other.field &&
          operator == other.operator &&
          _listEquals(values, other.values);

  @override
  int get hashCode => field.hashCode ^ operator.hashCode ^ values.hashCode;

  static bool _listEquals(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
