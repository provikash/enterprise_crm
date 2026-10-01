import 'package:flutter/foundation.dart';

import 'employee_kpi.dart';

/// Immutable domain entity representing a single evaluated line in a KPI Performance Report.
///
/// Follows HR-8.5 specifications:
/// - Stably associated with [kpiId] and [employeeId].
/// - Preserves exact stored [targetValue], [actualValue], and optional [score].
/// - Strictly prohibits recalculation or synthesizing missing scores.
/// - Preserves [periodStart] and [periodEnd] normalized to UTC calendar dates.
@immutable
class KpiReportRow {
  final String kpiId;
  final String employeeId;
  final String? employeeCode;
  final String employeeName;
  final String metricName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double targetValue;
  final double actualValue;
  final double? score;
  final String? remarks;

  KpiReportRow({
    required this.kpiId,
    required this.employeeId,
    this.employeeCode,
    required this.employeeName,
    required this.metricName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required this.targetValue,
    required this.actualValue,
    this.score,
    this.remarks,
  })  : periodStart = DateTime.utc(
          periodStart.year,
          periodStart.month,
          periodStart.day,
        ),
        periodEnd = DateTime.utc(
          periodEnd.year,
          periodEnd.month,
          periodEnd.day,
        );

  /// Factory constructor transforming an authoritative [EmployeeKpi] entity.
  factory KpiReportRow.fromEmployeeKpi(
    EmployeeKpi kpi, {
    String? employeeCode,
    required String employeeName,
  }) {
    return KpiReportRow(
      kpiId: kpi.id,
      employeeId: kpi.employeeId,
      employeeCode: employeeCode,
      employeeName: employeeName,
      metricName: kpi.metricName,
      periodStart: kpi.periodStart,
      periodEnd: kpi.periodEnd,
      targetValue: kpi.targetValue,
      actualValue: kpi.actualValue,
      score: kpi.score,
      remarks: kpi.remarks,
    );
  }

  /// Formatted period string 'YYYY-MM-DD – YYYY-MM-DD'.
  String get formattedPeriod {
    final sY = periodStart.year.toString().padLeft(4, '0');
    final sM = periodStart.month.toString().padLeft(2, '0');
    final sD = periodStart.day.toString().padLeft(2, '0');
    final eY = periodEnd.year.toString().padLeft(4, '0');
    final eM = periodEnd.month.toString().padLeft(2, '0');
    final eD = periodEnd.day.toString().padLeft(2, '0');
    return '$sY-$sM-$sD – $eY-$eM-$eD';
  }

  /// Formatted numeric representation without trailing decimal if integer.
  static String formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String get formattedTarget => formatNumber(targetValue);
  String get formattedActual => formatNumber(actualValue);
  String get formattedScore => score != null ? formatNumber(score!) : '—';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KpiReportRow &&
          runtimeType == other.runtimeType &&
          kpiId == other.kpiId &&
          employeeId == other.employeeId &&
          employeeCode == other.employeeCode &&
          employeeName == other.employeeName &&
          metricName == other.metricName &&
          periodStart == other.periodStart &&
          periodEnd == other.periodEnd &&
          targetValue == other.targetValue &&
          actualValue == other.actualValue &&
          score == other.score &&
          remarks == other.remarks;

  @override
  int get hashCode => Object.hash(
        kpiId,
        employeeId,
        employeeCode,
        employeeName,
        metricName,
        periodStart,
        periodEnd,
        targetValue,
        actualValue,
        score,
        remarks,
      );

  @override
  String toString() =>
      'KpiReportRow($kpiId, $employeeId, $metricName, $formattedPeriod, target: $targetValue, actual: $actualValue, score: $score)';
}
