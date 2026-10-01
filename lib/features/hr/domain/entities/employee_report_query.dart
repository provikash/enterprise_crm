import 'package:flutter/foundation.dart';

import 'employment_status.dart';
import 'report_date_range.dart';
import 'report_sort.dart';

/// Immutable query parameters for retrieving the Employee Directory Report.
///
/// Follows HR-8.1 filter and sort specifications:
/// - [department]: Optional filter matching employee department.
/// - [employmentStatus]: Optional filter matching [EmploymentStatus].
/// - [joiningDateRange]: Optional inclusive date boundary matching [Employee.joiningDate].
/// - [searchTerm]: Optional case-insensitive search matching name or employee code.
/// - [sort]: Optional sort criteria (default: `fullName` ascending).
@immutable
class EmployeeReportQuery {
  final String? department;
  final EmploymentStatus? employmentStatus;
  final ReportDateRange? joiningDateRange;
  final String? searchTerm;
  final ReportSort? sort;

  const EmployeeReportQuery({
    this.department,
    this.employmentStatus,
    this.joiningDateRange,
    this.searchTerm,
    this.sort,
  });

  /// Whether any filtering criteria are currently active.
  bool get hasFilters =>
      (department != null && department!.trim().isNotEmpty) ||
      employmentStatus != null ||
      joiningDateRange != null ||
      (searchTerm != null && searchTerm!.trim().isNotEmpty);

  /// Unified alias for cross-report filter state inspection.
  bool get hasActiveFilters => hasFilters;

  /// Creates a copy of this query with updated parameters.
  EmployeeReportQuery copyWith({
    String? department,
    bool clearDepartment = false,
    EmploymentStatus? employmentStatus,
    bool clearEmploymentStatus = false,
    ReportDateRange? joiningDateRange,
    bool clearJoiningDateRange = false,
    String? searchTerm,
    bool clearSearchTerm = false,
    ReportSort? sort,
    bool clearSort = false,
  }) {
    return EmployeeReportQuery(
      department: clearDepartment ? null : (department ?? this.department),
      employmentStatus: clearEmploymentStatus
          ? null
          : (employmentStatus ?? this.employmentStatus),
      joiningDateRange: clearJoiningDateRange
          ? null
          : (joiningDateRange ?? this.joiningDateRange),
      searchTerm: clearSearchTerm ? null : (searchTerm ?? this.searchTerm),
      sort: clearSort ? null : (sort ?? this.sort),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeReportQuery &&
          runtimeType == other.runtimeType &&
          department == other.department &&
          employmentStatus == other.employmentStatus &&
          joiningDateRange == other.joiningDateRange &&
          searchTerm == other.searchTerm &&
          sort == other.sort;

  @override
  int get hashCode => Object.hash(
        department,
        employmentStatus,
        joiningDateRange,
        searchTerm,
        sort,
      );

  @override
  String toString() =>
      'EmployeeReportQuery(dept: $department, status: ${employmentStatus?.value}, range: $joiningDateRange, search: $searchTerm, sort: $sort)';
}
