import 'package:flutter/foundation.dart';

import 'payroll_report_row.dart';

/// Monetary breakdown summary for a specific ISO currency code.
@immutable
class PayrollCurrencySummary {
  final String currency;
  final int recordCount;
  final double totalGross;
  final double totalAllowances;
  final double totalDeductions;
  final double totalNet;

  const PayrollCurrencySummary({
    required this.currency,
    required this.recordCount,
    required this.totalGross,
    required this.totalAllowances,
    required this.totalDeductions,
    required this.totalNet,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollCurrencySummary &&
          runtimeType == other.runtimeType &&
          currency == other.currency &&
          recordCount == other.recordCount &&
          totalGross == other.totalGross &&
          totalAllowances == other.totalAllowances &&
          totalDeductions == other.totalDeductions &&
          totalNet == other.totalNet;

  @override
  int get hashCode => Object.hash(
        currency,
        recordCount,
        totalGross,
        totalAllowances,
        totalDeductions,
        totalNet,
      );
}

/// Immutable domain summary metrics for evaluated Payroll Summary Reports.
///
/// Follows HR-8.1 / HR-8.6 aggregation rules:
/// - Provides exact count of matching payroll records.
/// - Strictly aggregates monetary amounts GROUPED BY CURRENCY.
/// - Strictly prohibits cross-currency summation (e.g., USD + INR cannot be combined).
/// - Preserves missing values: only valid numerical values are aggregated.
@immutable
class PayrollReportSummary {
  final int totalRecords;
  final Map<String, PayrollCurrencySummary> currencySummaries;

  const PayrollReportSummary({
    required this.totalRecords,
    required this.currencySummaries,
  });

  /// True if records span more than one ISO currency code.
  bool get isMultiCurrency => currencySummaries.keys.length > 1;

  /// The single ISO currency if only one currency exists, or `null`.
  String? get singleCurrency =>
      currencySummaries.keys.length == 1 ? currencySummaries.keys.first : null;

  /// The single currency summary if only one currency exists, or `null`.
  PayrollCurrencySummary? get singleSummary =>
      currencySummaries.keys.length == 1 ? currencySummaries.values.first : null;

  /// Factory computing authoritative summary metrics safely from evaluated [rows].
  factory PayrollReportSummary.fromRows(List<PayrollReportRow> rows) {
    if (rows.isEmpty) {
      return const PayrollReportSummary(
        totalRecords: 0,
        currencySummaries: {},
      );
    }

    final Map<String, int> counts = {};
    final Map<String, double> grossMap = {};
    final Map<String, double> allowancesMap = {};
    final Map<String, double> deductionsMap = {};
    final Map<String, double> netMap = {};

    for (final row in rows) {
      final curr = row.currency.trim().toUpperCase();
      counts[curr] = (counts[curr] ?? 0) + 1;

      if (row.grossSalary != null) {
        grossMap[curr] = (grossMap[curr] ?? 0.0) + row.grossSalary!;
      }
      if (row.totalAllowances != null) {
        allowancesMap[curr] =
            (allowancesMap[curr] ?? 0.0) + row.totalAllowances!;
      }
      if (row.totalDeductions != null) {
        deductionsMap[curr] =
            (deductionsMap[curr] ?? 0.0) + row.totalDeductions!;
      }
      if (row.netSalary != null) {
        netMap[curr] = (netMap[curr] ?? 0.0) + row.netSalary!;
      }
    }

    final summaries = <String, PayrollCurrencySummary>{};
    for (final curr in counts.keys) {
      summaries[curr] = PayrollCurrencySummary(
        currency: curr,
        recordCount: counts[curr]!,
        totalGross: grossMap[curr] ?? 0.0,
        totalAllowances: allowancesMap[curr] ?? 0.0,
        totalDeductions: deductionsMap[curr] ?? 0.0,
        totalNet: netMap[curr] ?? 0.0,
      );
    }

    return PayrollReportSummary(
      totalRecords: rows.length,
      currencySummaries: summaries,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayrollReportSummary &&
          runtimeType == other.runtimeType &&
          totalRecords == other.totalRecords &&
          mapEquals(currencySummaries, other.currencySummaries);

  @override
  int get hashCode => Object.hash(
        totalRecords,
        Object.hashAll(currencySummaries.entries),
      );
}
