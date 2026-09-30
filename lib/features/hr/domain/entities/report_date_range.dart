import 'package:flutter/foundation.dart';

/// Immutable date range value object for HR report filtering.
///
/// Follows HR-8.1/HR-8.2 contract:
/// - Enforces `start <= end`.
/// - Normalizes boundaries to UTC midnight and end-of-day.
/// - Evaluates inclusive date boundaries.
@immutable
class ReportDateRange {
  final DateTime start;
  final DateTime end;

  ReportDateRange({
    required DateTime start,
    required DateTime end,
  })  : start = DateTime.utc(start.year, start.month, start.day),
        end = DateTime.utc(end.year, end.month, end.day, 23, 59, 59, 999) {
    if (this.start.isAfter(this.end)) {
      throw ArgumentError(
        'ReportDateRange start date (${this.start.toIso8601String()}) must not be after end date (${this.end.toIso8601String()})',
      );
    }
  }

  /// Whether the specified [date] falls inclusively within this range.
  bool contains(DateTime date) {
    final utcDate = date.toUtc();
    return (utcDate.isAfter(start) || utcDate.isAtSameMomentAs(start)) &&
        (utcDate.isBefore(end) || utcDate.isAtSameMomentAs(end));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportDateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() =>
      'ReportDateRange(${start.toIso8601String().split('T').first}..${end.toIso8601String().split('T').first})';
}
