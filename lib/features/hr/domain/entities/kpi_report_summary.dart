import 'package:flutter/foundation.dart';

import 'kpi_report_row.dart';

/// Immutable domain summary metrics for evaluated KPI Performance Reports.
///
/// Follows HR-8.5 aggregation constraints:
/// - Provides exact count of matching KPI records.
/// - Categorizes scored vs unscored records.
/// - Strictly prohibits averaging or summing across disparate KPI metrics.
/// - Allows target/actual summation ONLY when every matching row shares an identical metric.
/// - Strictly prohibits employee ranking, leaderboards, or performance grading.
@immutable
class KpiReportSummary {
  final int totalRecords;
  final int scoredRecords;
  final int unscoredRecords;
  final String? singleMetricName;
  final double? totalTargetForMetric;
  final double? totalActualForMetric;

  const KpiReportSummary({
    required this.totalRecords,
    required this.scoredRecords,
    required this.unscoredRecords,
    this.singleMetricName,
    this.totalTargetForMetric,
    this.totalActualForMetric,
  });

  /// Factory computing authoritative summary metrics safely from evaluated [rows].
  factory KpiReportSummary.fromRows(List<KpiReportRow> rows) {
    if (rows.isEmpty) {
      return const KpiReportSummary(
        totalRecords: 0,
        scoredRecords: 0,
        unscoredRecords: 0,
      );
    }

    int scored = 0;
    int unscored = 0;
    final firstMetric = rows.first.metricName.trim().toLowerCase();
    bool allSameMetric = true;

    for (final row in rows) {
      if (row.score != null) {
        scored++;
      } else {
        unscored++;
      }

      if (allSameMetric && row.metricName.trim().toLowerCase() != firstMetric) {
        allSameMetric = false;
      }
    }

    double? sumTarget;
    double? sumActual;

    // Strict aggregation safety: sum target and actual ONLY if all records share identical metric
    if (allSameMetric) {
      sumTarget = 0.0;
      sumActual = 0.0;
      for (final row in rows) {
        sumTarget = (sumTarget ?? 0.0) + row.targetValue;
        sumActual = (sumActual ?? 0.0) + row.actualValue;
      }
    }

    return KpiReportSummary(
      totalRecords: rows.length,
      scoredRecords: scored,
      unscoredRecords: unscored,
      singleMetricName: allSameMetric ? rows.first.metricName : null,
      totalTargetForMetric: sumTarget,
      totalActualForMetric: sumActual,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KpiReportSummary &&
          runtimeType == other.runtimeType &&
          totalRecords == other.totalRecords &&
          scoredRecords == other.scoredRecords &&
          unscoredRecords == other.unscoredRecords &&
          singleMetricName == other.singleMetricName &&
          totalTargetForMetric == other.totalTargetForMetric &&
          totalActualForMetric == other.totalActualForMetric;

  @override
  int get hashCode => Object.hash(
        totalRecords,
        scoredRecords,
        unscoredRecords,
        singleMetricName,
        totalTargetForMetric,
        totalActualForMetric,
      );

  @override
  String toString() =>
      'KpiReportSummary(total: $totalRecords, scored: $scoredRecords, unscored: $unscoredRecords, singleMetric: $singleMetricName)';
}
