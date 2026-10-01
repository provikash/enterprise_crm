import 'package:flutter/foundation.dart';

import '../../domain/entities/kpi_report_query.dart';
import '../../domain/entities/kpi_report_row.dart';
import '../../domain/entities/kpi_report_summary.dart';
import '../../domain/entities/report_result.dart';

/// Operational lifecycle statuses for the KPI Performance Report screen.
enum KpiReportStatus {
  initial,
  loading,
  loaded,
  empty,
  failure,
}

/// Immutable BLoC state for KPI Performance Report presentation.
@immutable
class KpiReportState {
  final KpiReportStatus status;
  final KpiReportQuery query;
  final ReportResult<KpiReportRow>? result;
  final KpiReportSummary? summary;
  final String? errorMessage;

  const KpiReportState({
    this.status = KpiReportStatus.loading,
    this.query = KpiReportQuery.defaultQuery,
    this.result,
    this.summary,
    this.errorMessage,
  });

  /// Factory for the initial state.
  factory KpiReportState.initial({KpiReportQuery? initialQuery}) {
    return KpiReportState(
      status: KpiReportStatus.loading,
      query: initialQuery ?? KpiReportQuery.defaultQuery,
    );
  }

  bool get isLoading => status == KpiReportStatus.loading;
  bool get isLoaded => status == KpiReportStatus.loaded;
  bool get isEmpty => status == KpiReportStatus.empty;
  bool get isFailure => status == KpiReportStatus.failure;

  int get totalCount => result?.totalCount ?? 0;
  List<KpiReportRow> get rows => result?.rows ?? const [];

  KpiReportState copyWith({
    KpiReportStatus? status,
    KpiReportQuery? query,
    ReportResult<KpiReportRow>? result,
    bool clearResult = false,
    KpiReportSummary? summary,
    bool clearSummary = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return KpiReportState(
      status: status ?? this.status,
      query: query ?? this.query,
      result: clearResult ? null : (result ?? this.result),
      summary: clearSummary ? null : (summary ?? this.summary),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KpiReportState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          query == other.query &&
          result == other.result &&
          summary == other.summary &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(status, query, result, summary, errorMessage);

  @override
  String toString() =>
      'KpiReportState($status, query: $query, rows: ${result?.rows.length}, error: $errorMessage)';
}
