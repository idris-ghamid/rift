import 'package:meta/meta.dart';

/// Sort order direction.
enum SortOrder {
  /// Ascending order (smallest first).
  asc,

  /// Descending order (largest first).
  desc,
}

/// A sort condition for a query.
///
/// Specifies a [field] to sort by and a [SortOrder] direction.
@immutable
class SortCondition {
  /// The name of the field to sort by.
  final String field;

  /// The sort direction.
  final SortOrder order;

  /// Create a sort condition.
  const SortCondition({required this.field, this.order = SortOrder.asc});

  /// Compare two values using this sort condition.
  ///
  /// Returns negative if [a] should come before [b],
  /// positive if [a] should come after [b], zero if equal.
  int compare(dynamic a, dynamic b) {
    final result = _compareValues(a, b);
    return order == SortOrder.asc ? result : -result;
  }

  /// Compare two raw values.
  static int _compareValues(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;

    if (a is Comparable && b is Comparable && a.runtimeType == b.runtimeType) {
      return a.compareTo(b);
    }

    if (a is num && b is num) {
      return a.compareTo(b);
    }

    if (a is String && b is String) {
      return a.compareTo(b);
    }

    return a.toString().compareTo(b.toString());
  }

  @override
  String toString() => 'SortCondition(field: $field, order: $order)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortCondition && field == other.field && order == other.order;

  @override
  int get hashCode => field.hashCode ^ order.hashCode;
}
