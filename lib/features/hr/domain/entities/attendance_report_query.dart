import 'package:flutter/foundation.dart';

import 'report_date_range.dart';
import 'report_sort.dart';

/// Immutable domain query criteria for evaluating Attendance Summary Reports.
///
/// Follows HR-8.4 query contract:
/// - Supports filtering by [employeeId], [status], and [dateRange].
/// - Supports [searchTerm] over employee name or code.
/// - Supports typed presentation [sort] ordering.
@immutable
class AttendanceReportQuery {
  final String? employeeId;
  final String? status;
  final ReportDateRange? dateRange;
  final String? searchTerm;
  final ReportSort? sort;
  final int? limit;
  final int? offset;

  const AttendanceReportQuery({
    this.employeeId,
    this.status,
    this.dateRange,
    this.searchTerm,
    this.sort,
    this.limit,
    this.offset,
  });

  /// Default query configuration.
  static const defaultQuery = AttendanceReportQuery(
    sort: ReportSort(field: 'date', direction: ReportSortDirection.descending),
  );

  /// Whether any filtering criteria is actively applied beyond defaults.
  bool get hasActiveFilters =>
      (employeeId != null && employeeId!.isNotEmpty) ||
      (status != null && status!.isNotEmpty && status != 'All') ||
      dateRange != null ||
      (searchTerm != null && searchTerm!.trim().isNotEmpty);

  /// Unified alias for cross-report filter state inspection.
  bool get hasFilters => hasActiveFilters;

  AttendanceReportQuery copyWith({
    String? employeeId,
    bool clearEmployeeId = false,
    String? status,
    bool clearStatus = false,
    ReportDateRange? dateRange,
    bool clearDateRange = false,
    String? searchTerm,
    bool clearSearchTerm = false,
    ReportSort? sort,
    int? limit,
    int? offset,
  }) {
    return AttendanceReportQuery(
      employeeId: clearEmployeeId ? null : (employeeId ?? this.employeeId),
      status: clearStatus ? null : (status ?? this.status),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      searchTerm: clearSearchTerm ? null : (searchTerm ?? this.searchTerm),
      sort: sort ?? this.sort,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceReportQuery &&
          runtimeType == other.runtimeType &&
          employeeId == other.employeeId &&
          status == other.status &&
          dateRange == other.dateRange &&
          searchTerm == other.searchTerm &&
          sort == other.sort &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(
        employeeId,
        status,
        dateRange,
        searchTerm,
        sort,
        limit,
        offset,
      );

  @override
  String toString() =>
      'AttendanceReportQuery(employeeId: $employeeId, status: $status, dateRange: $dateRange, search: $searchTerm, sort: $sort)';
}
