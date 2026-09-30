import 'package:flutter/foundation.dart';

/// Direction for report column sorting.
enum ReportSortDirection {
  ascending,
  descending;

  bool get isAscending => this == ReportSortDirection.ascending;
  bool get isDescending => this == ReportSortDirection.descending;
}

/// Immutable value object defining sort criteria for report queries.
@immutable
class ReportSort {
  final String field;
  final ReportSortDirection direction;

  const ReportSort({
    required this.field,
    this.direction = ReportSortDirection.ascending,
  });

  /// Creates a copy of this sort with toggled direction.
  ReportSort toggleDirection() {
    return ReportSort(
      field: field,
      direction: direction == ReportSortDirection.ascending
          ? ReportSortDirection.descending
          : ReportSortDirection.ascending,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportSort &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          direction == other.direction;

  @override
  int get hashCode => Object.hash(field, direction);

  @override
  String toString() => 'ReportSort($field, ${direction.name})';
}
