import 'package:flutter/foundation.dart';

import '../../domain/entities/attendance_report_query.dart';
import '../../domain/entities/attendance_report_row.dart';
import '../../domain/entities/attendance_report_summary.dart';
import '../../domain/entities/report_result.dart';

/// Operational lifecycle statuses for the Attendance Report screen.
enum AttendanceReportStatus {
  initial,
  loading,
  loaded,
  empty,
  failure,
}

/// Immutable BLoC state for Attendance Report presentation.
@immutable
class AttendanceReportState {
  final AttendanceReportStatus status;
  final AttendanceReportQuery query;
  final ReportResult<AttendanceReportRow>? result;
  final AttendanceReportSummary? summary;
  final String? errorMessage;

  const AttendanceReportState({
    this.status = AttendanceReportStatus.loading,
    this.query = AttendanceReportQuery.defaultQuery,
    this.result,
    this.summary,
    this.errorMessage,
  });

  /// Factory for the initial idle state with default query.
  factory AttendanceReportState.initial({AttendanceReportQuery? initialQuery}) {
    return AttendanceReportState(
      status: AttendanceReportStatus.loading,
      query: initialQuery ?? AttendanceReportQuery.defaultQuery,
    );
  }

  bool get isLoading => status == AttendanceReportStatus.loading;
  bool get isLoaded => status == AttendanceReportStatus.loaded;
  bool get isEmpty => status == AttendanceReportStatus.empty;
  bool get isFailure => status == AttendanceReportStatus.failure;

  int get totalCount => result?.totalCount ?? 0;
  List<AttendanceReportRow> get rows => result?.rows ?? const [];

  AttendanceReportState copyWith({
    AttendanceReportStatus? status,
    AttendanceReportQuery? query,
    ReportResult<AttendanceReportRow>? result,
    bool clearResult = false,
    AttendanceReportSummary? summary,
    bool clearSummary = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AttendanceReportState(
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
      other is AttendanceReportState &&
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
      'AttendanceReportState($status, query: $query, rows: ${result?.rows.length}, error: $errorMessage)';
}
