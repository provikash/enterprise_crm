import 'package:flutter/foundation.dart';

import 'report_date_range.dart';
import 'report_sort.dart';

/// Immutable domain query criteria for evaluating KPI Performance Reports.
///
/// Follows HR-8.5 specifications:
/// - Supports filtering by [employeeId], [metricName], and [dateRange].
/// - Supports [searchTerm] over employee name, code, or metric name.
/// - Supports presentation [sort] ordering.
@immutable
class KpiReportQuery {
  final String? employeeId;
  final String? metricName;
  final ReportDateRange? dateRange;
  final String? searchTerm;
  final ReportSort? sort;
  final int? limit;
  final int? offset;

  const KpiReportQuery({
    this.employeeId,
    this.metricName,
    this.dateRange,
    this.searchTerm,
    this.sort,
    this.limit,
    this.offset,
  });

  /// Default query configuration.
  static const defaultQuery = KpiReportQuery(
    sort: ReportSort(field: 'period', direction: ReportSortDirection.descending),
  );

  /// Whether any filtering criteria is actively applied beyond defaults.
  bool get hasActiveFilters =>
      (employeeId != null && employeeId!.isNotEmpty) ||
      (metricName != null && metricName!.isNotEmpty && metricName != 'All') ||
      dateRange != null ||
      (searchTerm != null && searchTerm!.trim().isNotEmpty);

  KpiReportQuery copyWith({
    String? employeeId,
    bool clearEmployeeId = false,
    String? metricName,
    bool clearMetricName = false,
    ReportDateRange? dateRange,
    bool clearDateRange = false,
    String? searchTerm,
    bool clearSearchTerm = false,
    ReportSort? sort,
    int? limit,
    int? offset,
  }) {
    return KpiReportQuery(
      employeeId: clearEmployeeId ? null : (employeeId ?? this.employeeId),
      metricName: clearMetricName ? null : (metricName ?? this.metricName),
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
      other is KpiReportQuery &&
          runtimeType == other.runtimeType &&
          employeeId == other.employeeId &&
          metricName == other.metricName &&
          dateRange == other.dateRange &&
          searchTerm == other.searchTerm &&
          sort == other.sort &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(
        employeeId,
        metricName,
        dateRange,
        searchTerm,
        sort,
        limit,
        offset,
      );

  @override
  String toString() =>
      'KpiReportQuery(employeeId: $employeeId, metricName: $metricName, dateRange: $dateRange, search: $searchTerm, sort: $sort)';
}
