import 'package:flutter/foundation.dart';

import '../../domain/entities/employee_kpi.dart';

/// Statuses for KPI Summary loading operations.
enum EmployeeKpiSummaryStatus { initial, loading, loaded, failure }

/// View-state representation for the KPI Summary & Visualization dashboard.
///
/// Contains only approved direct counts and aggregations derived from authoritative
/// [EmployeeKpi] repository records. No speculative formulas, rankings, or performance
/// grades are computed.
@immutable
class EmployeeKpiSummaryState {
  final EmployeeKpiSummaryStatus status;
  final List<EmployeeKpi> records;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? errorMessage;

  const EmployeeKpiSummaryState({
    this.status = EmployeeKpiSummaryStatus.initial,
    this.records = const [],
    this.periodStart,
    this.periodEnd,
    this.errorMessage,
  });

  bool get isLoading => status == EmployeeKpiSummaryStatus.loading;
  bool get isLoaded => status == EmployeeKpiSummaryStatus.loaded;
  bool get isFailure => status == EmployeeKpiSummaryStatus.failure;
  bool get isEmpty => isLoaded && records.isEmpty;

  /// Total count of approved KPI records in the selected period.
  int get totalKpis => records.length;

  /// Total count of distinct employees represented in the selected period.
  int get distinctEmployeesCount =>
      records.map((r) => r.employeeId).toSet().length;

  /// Total count of KPI records with a recorded score.
  int get recordsWithScoreCount => records.where((r) => r.score != null).length;

  /// Total count of KPI records pending evaluation (null score).
  int get recordsWithoutScoreCount =>
      records.where((r) => r.score == null).length;

  /// Distribution of records grouped by metric name.
  Map<String, int> get metricCounts {
    final counts = <String, int>{};
    for (final record in records) {
      counts[record.metricName] = (counts[record.metricName] ?? 0) + 1;
    }
    return counts;
  }

  /// Records grouped by metric name for per-metric comparisons.
  Map<String, List<EmployeeKpi>> get metricRecords {
    final groups = <String, List<EmployeeKpi>>{};
    for (final record in records) {
      groups.putIfAbsent(record.metricName, () => []).add(record);
    }
    return groups;
  }

  /// Human-readable label for the current period selection.
  String get activePeriodLabel {
    if (periodStart == null && periodEnd == null) {
      return 'All Recorded Periods';
    }
    if (periodStart != null &&
        periodEnd != null &&
        periodStart!.year == 2026 &&
        periodStart!.month == 7 &&
        periodStart!.day == 1 &&
        periodEnd!.year == 2026 &&
        periodEnd!.month == 9 &&
        periodEnd!.day == 30) {
      return 'Q3 2026 (Jul–Sep)';
    }

    final startStr = periodStart != null
        ? '${periodStart!.year}-${periodStart!.month.toString().padLeft(2, '0')}-${periodStart!.day.toString().padLeft(2, '0')}'
        : 'Earliest';
    final endStr = periodEnd != null
        ? '${periodEnd!.year}-${periodEnd!.month.toString().padLeft(2, '0')}-${periodEnd!.day.toString().padLeft(2, '0')}'
        : 'Latest';
    return '$startStr to $endStr';
  }

  EmployeeKpiSummaryState copyWith({
    EmployeeKpiSummaryStatus? status,
    List<EmployeeKpi>? records,
    DateTime? periodStart,
    DateTime? periodEnd,
    bool clearPeriod = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmployeeKpiSummaryState(
      status: status ?? this.status,
      records: records ?? this.records,
      periodStart: clearPeriod ? null : (periodStart ?? this.periodStart),
      periodEnd: clearPeriod ? null : (periodEnd ?? this.periodEnd),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmployeeKpiSummaryState &&
        other.status == status &&
        listEquals(other.records, records) &&
        other.periodStart == periodStart &&
        other.periodEnd == periodEnd &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    status,
    Object.hashAll(records),
    periodStart,
    periodEnd,
    errorMessage,
  );

  @override
  String toString() =>
      'EmployeeKpiSummaryState(status: $status, count: ${records.length}, period: $activePeriodLabel, error: $errorMessage)';
}
