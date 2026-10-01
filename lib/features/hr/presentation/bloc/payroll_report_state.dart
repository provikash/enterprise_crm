import 'package:flutter/foundation.dart';

import '../../domain/entities/payroll_period.dart';
import '../../domain/entities/payroll_report_query.dart';
import '../../domain/entities/payroll_report_row.dart';
import '../../domain/entities/payroll_report_summary.dart';
import '../../domain/entities/report_result.dart';

/// Operational lifecycle statuses for the Payroll Summary Report screen.
enum PayrollReportStatus {
  initial,
  loading,
  loaded,
  empty,
  failure,
}

/// Immutable BLoC state for Payroll Summary Report presentation.
@immutable
class PayrollReportState {
  final PayrollReportStatus status;
  final PayrollReportQuery query;
  final ReportResult<PayrollReportRow>? result;
  final PayrollReportSummary? summary;
  final List<PayrollPeriod> periods;
  final String? errorMessage;

  const PayrollReportState({
    this.status = PayrollReportStatus.loading,
    this.query = PayrollReportQuery.defaultQuery,
    this.result,
    this.summary,
    this.periods = const [],
    this.errorMessage,
  });

  /// Factory for the initial state.
  factory PayrollReportState.initial({
    PayrollReportQuery? initialQuery,
    List<PayrollPeriod> periods = const [],
  }) {
    return PayrollReportState(
      status: PayrollReportStatus.loading,
      query: initialQuery ?? PayrollReportQuery.defaultQuery,
      periods: periods,
    );
  }

  bool get isLoading => status == PayrollReportStatus.loading;
  bool get isLoaded => status == PayrollReportStatus.loaded;
  bool get isEmpty => status == PayrollReportStatus.empty;
  bool get isFailure => status == PayrollReportStatus.failure;

  int get totalCount => result?.totalCount ?? 0;
  List<PayrollReportRow> get rows => result?.rows ?? const [];

  PayrollReportState copyWith({
    PayrollReportStatus? status,
    PayrollReportQuery? query,
    ReportResult<PayrollReportRow>? result,
    bool clearResult = false,
    PayrollReportSummary? summary,
    bool clearSummary = false,
    List<PayrollPeriod>? periods,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PayrollReportState(
      status: status ?? this.status,
      query: query ?? this.query,
      result: clearResult ? null : (result ?? this.result),
      summary: clearSummary ? null : (summary ?? this.summary),
      periods: periods ?? this.periods,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollReportState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          query == other.query &&
          result == other.result &&
          summary == other.summary &&
          listEquals(periods, other.periods) &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        status,
        query,
        result,
        summary,
        Object.hashAll(periods),
        errorMessage,
      );
}
