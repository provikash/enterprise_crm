import 'package:flutter/foundation.dart';

import 'report_sort.dart';

/// Immutable domain query criteria for evaluating Payroll Summary Reports.
///
/// Follows HR-8.1 / HR-8.6 query contract:
/// - Supports filtering by [payrollPeriodId], [employeeId], [paymentStatus], and [currency].
/// - Supports [searchTerm] matching employee name, employee code, or payroll record ID.
/// - Supports typed presentation [sort] ordering.
/// - Read-only query: zero side-effects on underlying repositories.
@immutable
class PayrollReportQuery {
  final String? payrollPeriodId;
  final String? employeeId;
  final String? paymentStatus;
  final String? currency;
  final String? searchTerm;
  final ReportSort? sort;
  final int? limit;
  final int? offset;

  const PayrollReportQuery({
    this.payrollPeriodId,
    this.employeeId,
    this.paymentStatus,
    this.currency,
    this.searchTerm,
    this.sort,
    this.limit,
    this.offset,
  });

  /// Default query configuration: sorts by period descending.
  static const defaultQuery = PayrollReportQuery(
    sort: ReportSort(
      field: 'period',
      direction: ReportSortDirection.descending,
    ),
  );

  /// Whether any filtering criteria is actively applied beyond defaults.
  bool get hasActiveFilters =>
      (payrollPeriodId != null &&
          payrollPeriodId!.isNotEmpty &&
          payrollPeriodId != 'All') ||
      (employeeId != null && employeeId!.isNotEmpty) ||
      (paymentStatus != null &&
          paymentStatus!.isNotEmpty &&
          paymentStatus != 'All') ||
      (currency != null && currency!.isNotEmpty && currency != 'All') ||
      (searchTerm != null && searchTerm!.trim().isNotEmpty);

  PayrollReportQuery copyWith({
    String? payrollPeriodId,
    bool clearPayrollPeriodId = false,
    String? employeeId,
    bool clearEmployeeId = false,
    String? paymentStatus,
    bool clearPaymentStatus = false,
    String? currency,
    bool clearCurrency = false,
    String? searchTerm,
    bool clearSearchTerm = false,
    ReportSort? sort,
    int? limit,
    int? offset,
  }) {
    return PayrollReportQuery(
      payrollPeriodId: clearPayrollPeriodId
          ? null
          : (payrollPeriodId ?? this.payrollPeriodId),
      employeeId:
          clearEmployeeId ? null : (employeeId ?? this.employeeId),
      paymentStatus: clearPaymentStatus
          ? null
          : (paymentStatus ?? this.paymentStatus),
      currency: clearCurrency ? null : (currency ?? this.currency),
      searchTerm:
          clearSearchTerm ? null : (searchTerm ?? this.searchTerm),
      sort: sort ?? this.sort,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollReportQuery &&
          runtimeType == other.runtimeType &&
          payrollPeriodId == other.payrollPeriodId &&
          employeeId == other.employeeId &&
          paymentStatus == other.paymentStatus &&
          currency == other.currency &&
          searchTerm == other.searchTerm &&
          sort == other.sort &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(
        payrollPeriodId,
        employeeId,
        paymentStatus,
        currency,
        searchTerm,
        sort,
        limit,
        offset,
      );
}
