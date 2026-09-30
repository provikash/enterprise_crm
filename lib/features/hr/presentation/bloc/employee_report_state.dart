import 'package:flutter/foundation.dart';

import '../../domain/entities/employee_report_query.dart';
import '../../domain/entities/employee_report_row.dart';
import '../../domain/entities/report_result.dart';

/// Lifecycle status for Employee Directory Report evaluation.
enum EmployeeReportStatus {
  initial,
  loading,
  loaded,
  empty,
  error;

  bool get isInitial => this == EmployeeReportStatus.initial;
  bool get isLoading => this == EmployeeReportStatus.loading;
  bool get isLoaded => this == EmployeeReportStatus.loaded;
  bool get isEmpty => this == EmployeeReportStatus.empty;
  bool get isError => this == EmployeeReportStatus.error;
}

/// Immutable state for Employee Directory Report workflow.
@immutable
class EmployeeReportState {
  final EmployeeReportStatus status;
  final EmployeeReportQuery query;
  final ReportResult<EmployeeReportRow>? result;
  final String? errorMessage;

  const EmployeeReportState({
    this.status = EmployeeReportStatus.initial,
    this.query = const EmployeeReportQuery(),
    this.result,
    this.errorMessage,
  });

  bool get isLoading => status == EmployeeReportStatus.loading;
  bool get isLoaded => status == EmployeeReportStatus.loaded;
  bool get isEmpty => status == EmployeeReportStatus.empty;
  bool get isError => status == EmployeeReportStatus.error;

  /// Current rows from the evaluated result.
  List<EmployeeReportRow> get rows => result?.rows ?? const [];

  /// Total count of matching employees.
  int get totalCount => result?.totalCount ?? 0;

  EmployeeReportState copyWith({
    EmployeeReportStatus? status,
    EmployeeReportQuery? query,
    ReportResult<EmployeeReportRow>? result,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return EmployeeReportState(
      status: status ?? this.status,
      query: query ?? this.query,
      result: result ?? this.result,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeReportState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          query == other.query &&
          result == other.result &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(status, query, result, errorMessage);
}
